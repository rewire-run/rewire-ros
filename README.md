# rewire_ros

ROS 2 launch integration for [rewire](https://rewire.run), a drop-in bridge that streams live ROS 2 topics into the [Rerun](https://rerun.io) viewer.

rewire speaks DDS and Zenoh natively and is not an rcl node, so this package does not build it, wrap it in a node, or expose ROS parameters. It exists so that `ros2 launch` can start the bridge alongside the rest of your stack, with the configuration living where rewire already expects it.

## What the build does

There is nothing to compile. The CMake step downloads the rewire release pinned in [`sources.json`](sources.json), verifies its SHA-256, and installs the bridge binary into the package's `lib` directory. The release archive also carries `rewire-viewer`, which is over three times the size of the bridge and of no use on a robot, so it is skipped.

Supported platforms are Linux on x86_64 and aarch64, plus macOS on Apple silicon.

## Build

```bash
cd ~/ros2_ws/src
git clone https://github.com/rewire-run/rewire-ros.git
cd ~/ros2_ws
colcon build --packages-select rewire_ros
source install/setup.bash
```

The build needs network access to reach the GitHub release. To use a rewire you already have, from apt, nix, or the install script, point the build at it and nothing is downloaded:

```bash
colcon build --packages-select rewire_ros --cmake-args -DREWIRE_BINARY=/usr/bin/rewire
```

## Launch

```bash
ros2 launch rewire_ros rewire.launch.py
ros2 launch rewire_ros rewire.launch.py connect:=192.168.1.10:9876
ros2 launch rewire_ros rewire.launch.py save:=/data/flight args:="--no-live"
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `config` | empty | JSON5 file holding topic filters and per-topic overrides. Empty uses rewire's own default location |
| `connect` | empty | Rerun viewer or relay to stream to, as `host` or `host:port` |
| `save` | empty | Write an `.rrd` archive with this path stem |
| `args` | empty | Extra flags passed through to `rewire record` verbatim |

Anything not covered by a named argument goes through `args`, so the whole command line stays reachable without this package growing a knob per flag. The full CLI is also available directly:

```bash
ros2 run rewire_ros rewire doctor
ros2 run rewire_ros rewire types
```

## Configuration

Topic selection, throttling, and per-topic overrides belong in the JSON5 config rather than on the command line, because the file supports glob patterns and per-topic rules that the flags cannot express.

This package ships no config of its own, so rewire resolves it exactly as it does outside ROS. With the `config` argument left empty, it reads `~/.config/rewire/config.json5` when that file exists, and otherwise runs on defaults. A config you already wrote for rewire therefore keeps working when you launch it this way.

To start from a documented template, or to keep a config per robot:

```bash
ros2 run rewire_ros rewire config generate > my_robot.json5
ros2 launch rewire_ros rewire.launch.py config:=my_robot.json5
```

Every key in the template ships commented out, so the defaults apply as-is. The usual first edit is uncommenting the `exclude` list to drop `/rosout` and `/parameter_events`.

Domain ID needs no argument. With `domain_id` left commented out, rewire falls back to `ROS_DOMAIN_ID`, so a launch that inherits your environment joins the same graph as everything else. Custom message types resolve through `AMENT_PREFIX_PATH`, so sourcing the workspace that holds your interface packages is all that is required.

## Choosing an output

With `connect` empty, rewire probes for a local viewer and spawns one if it finds none. That works on a workstation with a normal rewire install, where `rewire-viewer` is on `PATH`. It does not work on a headless robot whose only rewire is this package, because the viewer is deliberately not installed here and the fallback to a stock Rerun viewer needs `rerun` on `PATH`. On a robot, pass `connect` pointing at the workstation running the viewer, or pass `save` with `args:="--no-live"` to archive without a live half.

## Versioning

The package version tracks the rewire release it pins, so `rewire_ros` 0.10.1 installs rewire 0.10.1. Upgrading the bridge means bumping [`sources.json`](sources.json) and the version in `package.xml` together.

## License

This package is licensed under the Apache License 2.0, in [`LICENSE`](LICENSE). That covers the manifest, the CMake file, and the launch file.

It does not cover rewire itself. The bridge binary is proprietary and is not redistributed here. This repository contains a URL and a checksum, and your build downloads the binary directly from the [rewire releases](https://github.com/rewire-run/rewire/releases) under rewire's own terms.
