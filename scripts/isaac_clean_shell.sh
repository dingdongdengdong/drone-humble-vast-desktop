#!/usr/bin/env bash
set -eo pipefail

# Use this shell to launch Isaac Sim / Pegasus.
# It intentionally does not source system ROS2 Humble to avoid Python/library conflicts.
export DISPLAY="${DISPLAY:-:1}"
export ISAACSIM_PATH="${ISAACSIM_PATH:-/workspace/isaacsim}"
export PEGASUS_PATH="${PEGASUS_PATH:-/workspace/pegasus/PegasusSimulator}"
export ISAACSIM_PYTHON="${ISAACSIM_PATH}/python.sh"
export ISAACSIM="${ISAACSIM_PATH}/isaac-sim.sh"

# Isaac Sim 5.1 ships ROS2 bridge libraries. On Ubuntu 22.04 use its Humble bridge.
export ROS_DISTRO=humble
export RMW_IMPLEMENTATION="${ISAAC_RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
if [ -d "${ISAACSIM_PATH}/exts/isaacsim.ros2.bridge/humble/lib" ]; then
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${ISAACSIM_PATH}/exts/isaacsim.ros2.bridge/humble/lib"
fi

isaac_run() {
  if [ ! -x "${ISAACSIM_PYTHON}" ]; then
    echo "Isaac Sim python.sh not found at ${ISAACSIM_PYTHON}" >&2
    return 1
  fi
  if [ ! -x "${ISAACSIM}" ]; then
    echo "Isaac Sim launcher not found at ${ISAACSIM}" >&2
    return 1
  fi

  # Remove system ROS paths to avoid Python/lib conflicts with Isaac Sim.
  unset AMENT_PREFIX_PATH COLCON_PREFIX_PATH PYTHONPATH CMAKE_PREFIX_PATH
  if [ -n "${LD_LIBRARY_PATH:-}" ]; then
    LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | grep -v '^/opt/ros/humble' | paste -sd ':' -)
    export LD_LIBRARY_PATH
  fi

  if [ "$#" -eq 0 ]; then
    exec "${ISAACSIM}"
  elif [[ "$1" == --* ]]; then
    exec "${ISAACSIM}" "$@"
  elif [ -f "$1" ]; then
    local script_path="$1"
    shift
    exec "${ISAACSIM_PYTHON}" "${script_path}" "$@"
  else
    echo "Usage: isaac_run | isaac_run --help | isaac_run script.py" >&2
    return 1
  fi
}
export -f isaac_run

echo "Clean Isaac/Pegasus shell"
echo "ISAACSIM_PATH=${ISAACSIM_PATH}"
echo "PEGASUS_PATH=${PEGASUS_PATH}"
echo "ISAACSIM_PYTHON=${ISAACSIM_PYTHON}"
echo "DISPLAY=${DISPLAY}"
echo "Run: isaac_run --help"
echo "Run GUI: isaac_run"
exec bash --noprofile --norc
