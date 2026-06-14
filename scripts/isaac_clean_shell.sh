#!/usr/bin/env bash
set -euo pipefail

# Use this shell to launch Isaac Sim / Pegasus.
# It intentionally does not source ROS2 Humble to avoid Python/library conflicts.
export DISPLAY="${DISPLAY:-:1}"
export ISAACSIM_PATH="${ISAACSIM_PATH:-/workspace/isaacsim}"
export PEGASUS_PATH="${PEGASUS_PATH:-/workspace/pegasus}"

echo "Clean Isaac/Pegasus shell"
echo "ISAACSIM_PATH=${ISAACSIM_PATH}"
echo "PEGASUS_PATH=${PEGASUS_PATH}"
echo "DISPLAY=${DISPLAY}"
exec bash --noprofile --norc
