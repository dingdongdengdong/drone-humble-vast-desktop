#!/usr/bin/env bash
set -eo pipefail

# ROS setup files reference optional variables, so do not use bash nounset while sourcing them.
source /opt/ros/humble/setup.bash
export ROS_WS="${ROS_WS:-/workspaces/ros2_ws}"
export PEGASUS_WS="${PEGASUS_WS:-/workspaces/pegasus_ws}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}"
export CYCLONEDDS_URI="${CYCLONEDDS_URI:-file:///etc/cyclonedds/px4_humble.xml}"

if [ -f "${ROS_WS}/install/setup.bash" ]; then
  source "${ROS_WS}/install/setup.bash"
fi
if [ -f "${PEGASUS_WS}/install/setup.bash" ]; then
  source "${PEGASUS_WS}/install/setup.bash"
fi

echo "ROS_DISTRO=${ROS_DISTRO:-humble}"
echo "ROS_WS=${ROS_WS}"
echo "PEGASUS_WS=${PEGASUS_WS}"
echo "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}"
echo "CYCLONEDDS_URI=${CYCLONEDDS_URI}"
exec bash
