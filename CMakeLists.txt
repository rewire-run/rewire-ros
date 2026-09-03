cmake_minimum_required(VERSION 3.19)
project(rewire_ros)

find_package(ament_cmake REQUIRED)

set(REWIRE_BINARY "" CACHE FILEPATH
  "Install this rewire binary instead of downloading the pinned release")

if(REWIRE_BINARY)
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

  # The archive also carries rewire-viewer, which is over three times the size of the
  # bridge and of no use on a robot.
  file(ARCHIVE_EXTRACT INPUT "${rewire_archive}"
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/rewire"
    PATTERNS "rewire")
  set(rewire_exe "${CMAKE_CURRENT_BINARY_DIR}/rewire/rewire")
endif()

install(PROGRAMS "${rewire_exe}" DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})

ament_package()
