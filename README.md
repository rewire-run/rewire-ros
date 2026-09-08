# rewire_ros

ROS 2 launch integration for [rewire](https://rewire.run), a drop-in bridge that streams live ROS 2 topics into the [Rerun](https://rerun.io) viewer.

rewire speaks DDS and Zenoh natively and is not an rcl node, so this package does not build it, wrap it in a node, or expose ROS parameters. It exists so that `ros2 launch` can start the bridge alongside the rest of your stack, with the configuration living where rewire already expects it.

## Install

```bash
curl -fsSL https://apt.rewire.run/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/rewire.gpg
echo "deb [signed-by=/usr/share/keyrings/rewire.gpg] https://apt.rewire.run stable main" | sudo tee /etc/apt/sources.list.d/rewire.list
sudo apt update && sudo apt install ros-humble-rewire-ros
```

Substitute your distribution for `humble`. That one command is enough: the package declares a dependency on `rewire`, so apt fetches the bridge and the viewer from the same repository and puts them on your `PATH`. Nothing else to download.

The ROS package itself carries no binaries, which is why one copy of rewire serves every ROS distribution you have installed. Build it from source instead, as below, and it bundles its own copy.

## What the build does

There is nothing to compile. The CMake step downloads the rewire release pinned in [`sources.json`](sources.json), verifies its SHA-256, and installs both binaries from it into the package's `lib` directory. You need nothing else on the machine: `ros2 launch` starts the bridge, and it finds the viewer sitting beside it.

| Installed | Size |
| --- | --- |
| `rewire`, the bridge | 70 MB |
| `rewire-viewer` | 235 MB |

A robot that streams to a workstation has no use for a viewer, and can leave it out. A machine that already has rewire, from apt or the install script, needs no bundled copy at all:

```bash
colcon build --packages-select rewire_ros --cmake-args -DREWIRE_VIEWER=OFF
colcon build --packages-select rewire_ros --cmake-args -DREWIRE_BUNDLE=OFF
```

With `-DREWIRE_BUNDLE=OFF` the package installs only the launch file and resolves `rewire` on `PATH`, which is exactly how the deb is built.

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

Without a ROS installation, or on macOS, [pixi](https://pixi.sh) provides one per distribution from [RoboStack](https://robostack.github.io):

```bash
pixi run build                    # colcon build in the default env, jazzy
pixi run -e humble check          # build, then run the same checks as CI
```

Environments exist for `humble`, `jazzy`, `kilted`, and `lyrical`.

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

With `connect` empty, rewire probes for a viewer already listening and spawns one if it finds none. The bundled viewer sits next to the bridge in the package's `lib` directory, which is the first place rewire looks, so a plain launch on a desktop opens a window and needs no argument.

Two cases want something else. A robot streaming to a workstation should pass `connect` naming that machine, which skips the probe entirely. A robot recording for later should pass `save` together with `args:="--no-live"`, which writes an `.rrd` and never looks for a viewer at all. Both are worth pairing with `-DREWIRE_VIEWER=OFF` at build time, since neither spawns one.

A build with `-DREWIRE_VIEWER=OFF` and an empty `connect` falls through to spawning a stock Rerun viewer, which fails unless `rerun` is on `PATH`. That combination is the one to avoid.

## Versioning

The package version tracks the rewire release it pins, so `rewire_ros` 0.10.1 installs rewire 0.10.1. Upgrading the bridge means bumping [`sources.json`](sources.json) and the version in `package.xml` together.

## License

This package is licensed under the Apache License 2.0, in [`LICENSE`](LICENSE). That covers the manifest, the CMake file, and the launch file.

It does not cover rewire itself. The bridge binary is proprietary and is not redistributed here. This repository contains a URL and a checksum, and your build downloads the binary directly from the [rewire releases](https://github.com/rewire-run/rewire/releases) under rewire's own terms.
