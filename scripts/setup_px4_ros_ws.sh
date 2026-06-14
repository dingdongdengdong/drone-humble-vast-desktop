#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/humble/setup.bash
ROS_WS="${ROS_WS:-/workspaces/ros2_ws}"
PX4_MSGS_REF="${PX4_MSGS_REF:-main}"
PX4_ROS_COM_REF="${PX4_ROS_COM_REF:-main}"

mkdir -p "${ROS_WS}/src"
cd "${ROS_WS}/src"

if [ ! -d px4_msgs ]; then
  git clone --branch "${PX4_MSGS_REF}" --depth 1 https://github.com/PX4/px4_msgs.git
else
  echo "px4_msgs already exists; skipping clone"
fi

if [ ! -d px4_ros_com ]; then
  git clone --branch "${PX4_ROS_COM_REF}" --depth 1 https://github.com/PX4/px4_ros_com.git
else
  echo "px4_ros_com already exists; skipping clone"
fi

cd "${ROS_WS}"
rosdep update || true
rosdep install --from-paths src --ignore-src -r -y || true
colcon build --symlink-install --packages-select px4_msgs px4_ros_com || colcon build --symlink-install

echo "PX4 ROS2 workspace prepared at ${ROS_WS}"
