#!/usr/bin/env bash
#
# Install a built deb the way a user would, with apt resolving its dependency
# on rewire, then run the same checks as CI against the installed package.
#
# apt.rewire.run is not used because Cloudflare answers 403 to GitHub's
# runners. The rewire deb comes from the GitHub release pinned in sources.json
# instead, and both debs are served from a local repository so apt still has
# to resolve the dependency by name.
#
# Usage: scripts/test-deb.sh <distro> <deb>
#
# Writes to /etc/apt and installs packages, so run it in a throwaway
# ros:<distro>-ros-base container, never on a workstation.

set -eo pipefail

distro="$1"
deb="$(realpath "$2")"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

apt-get update
apt-get install -y --no-install-recommends dpkg-dev curl ca-certificates

rewire_version="$(python3 -c "import json; print(json.load(open('$root/sources.json'))['version'])")"
arch="$(dpkg --print-architecture)"
repo="$(mktemp -d)"
chmod 755 "$repo"
curl -fsSL -o "$repo/rewire_${rewire_version}_${arch}.deb" \
  "https://github.com/rewire-run/rewire/releases/download/v${rewire_version}/rewire_${rewire_version}_${arch}.deb"
cp "$deb" "$repo/"
(cd "$repo" && dpkg-scanpackages . > Packages)
echo "deb [trusted=yes] file://${repo} ./" > /etc/apt/sources.list.d/local.list
apt-get update
apt-get install -y "ros-${distro}-rewire"

dpkg -s rewire > /dev/null
command -v rewire
rewire --version
source "/opt/ros/${distro}/setup.bash"
ros2 launch rewire rewire.launch.py --show-args
