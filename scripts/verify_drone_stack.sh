#!/usr/bin/env bash
set -eo pipefail

echo "=== OS ==="
cat /etc/os-release | sed -n '1,6p'

echo "=== GPU ==="
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi || true
else
  echo "nvidia-smi not found"
fi

echo "=== ROS2 ==="
# ROS setup files reference optional variables, so do not use bash nounset while sourcing them.
source /opt/ros/humble/setup.bash
ros2 --version || true
echo "ROS_DISTRO=${ROS_DISTRO:-unset}"
echo "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-unset}"
echo "CYCLONEDDS_URI=${CYCLONEDDS_URI:-unset}"

echo "=== PX4 / DDS tools ==="
command -v MicroXRCEAgent && MicroXRCEAgent --help | head -20 || echo "MicroXRCEAgent missing"
ros2 pkg prefix mavros >/dev/null 2>&1 && echo "mavros installed" || echo "mavros missing"
ros2 pkg prefix foxglove_bridge >/dev/null 2>&1 && echo "foxglove_bridge installed" || echo "foxglove_bridge missing"
ros2 pkg prefix rosbridge_server >/dev/null 2>&1 && echo "rosbridge_server installed" || echo "rosbridge_server missing"

echo "=== Workspaces ==="
echo "ROS_WS=${ROS_WS:-/workspaces/ros2_ws}"
ls -la "${ROS_WS:-/workspaces/ros2_ws}" || true
echo "PEGASUS_WS=${PEGASUS_WS:-/workspaces/pegasus_ws}"
ls -la "${PEGASUS_WS:-/workspaces/pegasus_ws}" || true

echo "=== Ports expected ==="
echo "VNC 5900, noVNC 6080, Jupyter 8080, Foxglove 8765, rosbridge 9090, backend 8000, frontend 3000/5173, Micro XRCE-DDS UDP 8888"
