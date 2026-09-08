#!/usr/bin/env bash
#
# Build the ros-<distro>-rewire deb from this checkout.
#
# The package carries no binaries and no compiled code, so one deb serves every
# architecture. rewire itself is a separate package that apt pulls in, and the
# build fails if a copy of it slips into the tree.
#
# Usage: scripts/build-deb.sh <distro>
#
# The version comes from package.xml. Expects a ROS install under
# /opt/ros/<distro>, as in the ros:<distro>-ros-base images. Leaves the deb in
# the repository root.

set -eo pipefail

distro="$1"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(sed -n 's:.*<version>\(.*\)</version>.*:\1:p' "$root/package.xml" | head -1)"
package="ros-${distro}-rewire"
deb="$root/${package}_${version}_all.deb"

source "/opt/ros/${distro}/setup.bash"

cmake -S "$root" -B "$root/build" \
  -DCMAKE_INSTALL_PREFIX="/opt/ros/${distro}" \
  -DREWIRE_BUNDLE=OFF
rm -rf "$root/pkg"
DESTDIR="$root/pkg" cmake --install "$root/build"

mkdir -p "$root/pkg/DEBIAN"
cat > "$root/pkg/DEBIAN/control" << EOF
Package: ${package}
Version: ${version}
Section: misc
Priority: optional
Architecture: all
Depends: rewire, ros-${distro}-launch, ros-${distro}-ament-index-python, ros-${distro}-ros-workspace
Maintainer: Alvaro Gaona <alvgaona@gmail.com>
Homepage: https://rewire.run
Description: ROS 2 launch integration for the rewire bridge
 Starts rewire from ros2 launch, streaming live ROS 2 topics into the
 Rerun viewer. The bridge itself comes from the rewire package.
EOF
dpkg-deb --build "$root/pkg" "$deb"

dpkg-deb --info "$deb"
dpkg-deb --contents "$deb"
if dpkg-deb --contents "$deb" | grep -E 'lib/rewire/rewire'; then
  echo "error: the deb carries a rewire binary; it must depend on the rewire package instead" >&2
  exit 1
fi
