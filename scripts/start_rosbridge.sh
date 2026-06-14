#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/humble/setup.bash
PORT="${ROSBRIDGE_PORT:-9090}"
echo "Starting rosbridge websocket on port ${PORT}"
exec ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:="${PORT}"
