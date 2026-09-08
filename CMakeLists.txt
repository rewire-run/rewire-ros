cmake_minimum_required(VERSION 3.19)
project(rewire)

find_package(ament_cmake REQUIRED)

option(REWIRE_BUNDLE
  "Install the rewire binaries into this package. Off expects rewire on PATH, which is
   how the deb is built: it depends on the rewire package instead of carrying a copy" ON)
set(REWIRE_BINARY "" CACHE FILEPATH
  "Install this rewire binary instead of downloading the pinned release")
option(REWIRE_VIEWER
  "Install rewire-viewer alongside the bridge, so a plain launch spawns a viewer" ON)

if(NOT REWIRE_BUNDLE)
  message(STATUS "rewire: bundling disabled, the launch file will resolve rewire on PATH")
elseif(REWIRE_BINARY)
  if(NOT EXISTS "${REWIRE_BINARY}")
    message(FATAL_ERROR "REWIRE_BINARY is ${REWIRE_BINARY}, which does not exist")
  endif()
  set(rewire_exe "${REWIRE_BINARY}")
  message(STATUS "rewire: installing ${rewire_exe}")
else()
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64)$")
    set(rewire_system "x86_64-linux")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(rewire_system "aarch64-linux")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(rewire_system "aarch64-darwin")
  else()
    message(FATAL_ERROR
      "rewire publishes no binary for ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}. "
      "Build one yourself and pass -DREWIRE_BINARY=<path>.")
  endif()

  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/sources.json" rewire_sources)
  string(JSON rewire_version GET "${rewire_sources}" version)
  string(JSON rewire_platform GET "${rewire_sources}" platforms "${rewire_system}" platform)
  string(JSON rewire_sha256 GET "${rewire_sources}" platforms "${rewire_system}" sha256)

  set(rewire_archive "${CMAKE_CURRENT_BINARY_DIR}/rewire-${rewire_version}-${rewire_platform}.tar.gz")
  set(rewire_url
    "https://github.com/rewire-run/rewire/releases/download/v${rewire_version}/rewire-${rewire_version}-${rewire_platform}.tar.gz")

  message(STATUS "rewire: downloading ${rewire_url}")
  file(DOWNLOAD "${rewire_url}" "${rewire_archive}"
    EXPECTED_HASH SHA256=${rewire_sha256}
    STATUS rewire_download_status)
  list(GET rewire_download_status 0 rewire_download_code)
  if(NOT rewire_download_code EQUAL 0)
    list(GET rewire_download_status 1 rewire_download_error)
    message(FATAL_ERROR "could not download ${rewire_url}: ${rewire_download_error}")
  endif()

  if(REWIRE_VIEWER)
    file(ARCHIVE_EXTRACT INPUT "${rewire_archive}"
      DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/rewire")
  else()
    file(ARCHIVE_EXTRACT INPUT "${rewire_archive}"
      DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/rewire"
      PATTERNS "rewire")
  endif()
  set(rewire_exe "${CMAKE_CURRENT_BINARY_DIR}/rewire/rewire")

  # A release may ship without the viewer: it is built in another repository and the
  # release job tolerates its absence, as install.sh does.
  set(rewire_viewer_exe "${CMAKE_CURRENT_BINARY_DIR}/rewire/rewire-viewer")
  if(REWIRE_VIEWER AND NOT EXISTS "${rewire_viewer_exe}")
    message(WARNING "rewire ${rewire_version} shipped no viewer for ${rewire_platform}")
    unset(rewire_viewer_exe)
  endif()
endif()

if(REWIRE_BUNDLE)
  install(PROGRAMS "${rewire_exe}" DESTINATION lib/${PROJECT_NAME})
  if(REWIRE_VIEWER AND rewire_viewer_exe)
    install(PROGRAMS "${rewire_viewer_exe}" DESTINATION lib/${PROJECT_NAME})
  endif()
endif()
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})

ament_package()
