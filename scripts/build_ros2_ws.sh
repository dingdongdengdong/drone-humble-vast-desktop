#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/humble/setup.bash
ROS_WS="${ROS_WS:-/workspaces/ros2_ws}"
cd "${ROS_WS}"

if [ ! -d src ]; then
  mkdir -p src
fi

rosdep update || true
rosdep install --from-paths src --ignore-src -r -y || true
colcon build --symlink-install "$@"
