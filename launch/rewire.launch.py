# SPDX-License-Identifier: Apache-2.0

import os
import shlex

from ament_index_python.packages import get_package_prefix
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess, OpaqueFunction
from launch.substitutions import LaunchConfiguration

PACKAGE = 'rewire'


def rewire_executable():
    """A source build bundles the binaries here; the deb depends on the rewire
    package instead and leaves them on PATH."""
    bundled = os.path.join(get_package_prefix(PACKAGE), 'lib', PACKAGE, 'rewire')
    return bundled if os.path.isfile(bundled) else 'rewire'


def launch_setup(context, *args, **kwargs):
    def value(name):
        return LaunchConfiguration(name).perform(context)

    command = [rewire_executable(), 'record']
    if value('config'):
        command += ['--config', value('config')]
    if value('connect'):
        command += ['--connect', value('connect')]
    if value('save'):
        command += ['--save', value('save')]
    command += shlex.split(value('args'))

    return [ExecuteProcess(cmd=command, output='screen', emulate_tty=True)]


def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument(
            'config',
            default_value='',
            description='JSON5 config file holding topic filters and per-topic overrides. '
                        'Leave empty to use rewire config path, normally '
                        '~/.config/rewire/config.json5',
        ),
        DeclareLaunchArgument(
            'connect',
            default_value='',
            description='Rerun viewer or relay to stream to, as host or host:port. '
                        'Leave empty to probe for a local viewer and spawn one',
        ),
        DeclareLaunchArgument(
            'save',
            default_value='',
            description='Write an .rrd archive with this path stem. Relative stems land in '
                        'the directory ros2 launch was started from',
        ),
        DeclareLaunchArgument(
            'args',
            default_value='',
            description='Extra flags passed through to rewire record verbatim',
        ),
        OpaqueFunction(function=launch_setup),
    ])
