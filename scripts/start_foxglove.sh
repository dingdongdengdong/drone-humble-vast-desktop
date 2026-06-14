#!/usr/bin/env bash
set -eo pipefail

source /opt/ros/humble/setup.bash
export ROS_WS="${ROS_WS:-/workspaces/ros2_ws}"
if [ -f "${ROS_WS}/install/setup.bash" ]; then
  source "${ROS_WS}/install/setup.bash"
fi

HOST="${FOXGLOVE_HOST:-0.0.0.0}"
PORT="${FOXGLOVE_PORT:-8765}"

echo "Starting Foxglove Bridge on ${HOST}:${PORT}"
exec ros2 launch foxglove_bridge foxglove_bridge_launch.xml port:="${PORT}" address:="${HOST}"
