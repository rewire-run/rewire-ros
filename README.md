<h1 align="center">
  <a href="https://rewire.run/">
    <img alt="rewire" src="https://rewire.run/brand/rewire-banner.png">
  </a>
</h1>

<p align="center">
  <a href="https://github.com/rewire-run/rewire-ros/actions/workflows/ci.yaml">
    <img alt="CI" src="https://github.com/rewire-run/rewire-ros/actions/workflows/ci.yaml/badge.svg">
  </a>
  <a href="https://github.com/rewire-run/rewire-ros/actions/workflows/deb.yaml">
    <img alt="deb" src="https://github.com/rewire-run/rewire-ros/actions/workflows/deb.yaml/badge.svg">
  </a>
  <a href="https://github.com/rewire-run/rewire-ros/releases/latest">
    <img alt="Version" src="https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fraw.githubusercontent.com%2Frewire-run%2Frewire-ros%2Fmain%2Fpackage.xml&query=%2Fpackage%2Fversion&prefix=v&label=version&color=green">
  </a>
  <img alt="ROS 2" src="https://img.shields.io/badge/ROS_2-humble_%7C_jazzy_%7C_kilted_%7C_lyrical-blue">
  <a href="https://github.com/rewire-run/rewire-ros/blob/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue">
  </a>
  <a href="https://pixi.sh">
    <img alt="Powered by" src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json">
  </a>
</p>

# ROS 2 launch integration for rewire

Start [rewire](https://rewire.run), the drop-in bridge that streams live ROS 2 topics into the [Rerun](https://rerun.io) viewer, from `ros2 launch` alongside the rest of your stack.

rewire speaks DDS and Zenoh natively and is not an rcl node, so this package does not build it, wrap it in a node, or expose ROS parameters. It ships a launch file and, on source builds, the bridge and viewer binaries.

## Install

```bash
curl -fsSL https://apt.rewire.run/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/rewire.gpg
echo "deb [signed-by=/usr/share/keyrings/rewire.gpg] https://apt.rewire.run stable main" | sudo tee /etc/apt/sources.list.d/rewire.list
sudo apt update && sudo apt install ros-humble-rewire
```

Substitute your distribution for `humble`. The package depends on `rewire`, so apt installs the bridge and the viewer from the same repository. One copy of rewire serves every ROS distribution on the machine.

### From source

```bash
cd ~/ros2_ws/src
git clone https://github.com/rewire-run/rewire-ros.git
cd ~/ros2_ws
colcon build --packages-select rewire
source install/setup.bash
```

There is nothing to compile. The build downloads the rewire release pinned in [`sources.json`](sources.json), verifies its SHA-256, and installs the bridge (70 MB) and the viewer (235 MB) into the package. It needs network access to reach the GitHub release. Supported platforms are Linux on x86_64 and aarch64, and macOS on Apple silicon.

| CMake flag | Effect |
| --- | --- |
| `-DREWIRE_VIEWER=OFF` | Skip the viewer. Right for a robot that streams to a workstation or records to disk |
| `-DREWIRE_BINARY=/usr/bin/rewire` | Install a rewire you already have instead of downloading one |
| `-DREWIRE_BUNDLE=OFF` | Install only the launch file and resolve `rewire` on `PATH`. This is how the deb is built |

Pass them through `colcon build --cmake-args`.

## Quick Start

```bash
ros2 launch rewire rewire.launch.py                                   # Open a viewer and stream everything
ros2 launch rewire rewire.launch.py connect:=192.168.1.10:9876        # Stream to a viewer on another machine
ros2 launch rewire rewire.launch.py save:=/data/flight args:="--no-live"   # Record to an .rrd, no viewer

ros2 run rewire rewire doctor                                         # The full CLI is available too
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `config` | empty | JSON5 file holding topic filters and per-topic overrides. Empty uses rewire's own default location |
| `connect` | empty | Rerun viewer or relay to stream to, as `host` or `host:port` |
| `save` | empty | Write an `.rrd` archive with this path stem |
| `args` | empty | Extra flags passed through to `rewire record` verbatim |

Anything not covered by a named argument goes through `args`, so the whole command line stays reachable.

With `connect` empty, rewire looks for a viewer already listening and spawns the bundled one if it finds none. A build with `-DREWIRE_VIEWER=OFF` and an empty `connect` falls through to a stock Rerun viewer on `PATH`, so pair that flag with `connect` or `save`.

## Configuration

Topic selection, throttling, and per-topic overrides live in rewire's JSON5 config, which supports glob patterns the flags cannot express. This package ships no config of its own. With `config` left empty, rewire reads `~/.config/rewire/config.json5` when it exists and otherwise runs on defaults, so a config you already use keeps working.

```bash
ros2 run rewire rewire config generate > my_robot.json5
ros2 launch rewire rewire.launch.py config:=my_robot.json5
```

Domain ID follows `ROS_DOMAIN_ID`, and custom message types resolve through `AMENT_PREFIX_PATH`, so sourcing your workspace is all that is required. The full reference is at [docs.rewire.run](https://docs.rewire.run).

## Development

No ROS installation is needed. [pixi](https://pixi.sh) builds the package with [pixi-build-ros](https://pixi.prefix.dev/latest/build/ros/) against a [RoboStack](https://robostack.github.io) distribution and installs it into the environment:

```bash
pixi run check                    # Build on jazzy, then run the same checks as CI
pixi run -e humble check          # Same on humble, kilted, or lyrical
pixi build                        # Produce a ros-jazzy-rewire .conda package
```

The bridge version a source build installs is pinned in [`sources.json`](sources.json), and moving it is a plain commit. The package has its own version in [`package.xml`](package.xml) and is released only when the package itself changes. Each release publishes the debs to apt.rewire.run, where they depend on whatever rewire is current. Commit messages follow [conventional commits](https://www.conventionalcommits.org).

## License

This package is licensed under the Apache License 2.0, in [`LICENSE`](LICENSE). That covers the manifest, the CMake file, and the launch file.

It does not cover rewire itself. The bridge binary is proprietary and is not redistributed here. This repository contains a URL and a checksum, and your build downloads the binary directly from the [rewire releases](https://github.com/rewire-run/rewire/releases) under rewire's own terms.
