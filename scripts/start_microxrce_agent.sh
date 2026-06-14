#!/usr/bin/env bash
set -euo pipefail

TRANSPORT="${MICRO_XRCE_TRANSPORT:-udp4}"
PORT="${MICRO_XRCE_PORT:-8888}"
VERBOSE="${MICRO_XRCE_VERBOSE:-4}"

if ! command -v MicroXRCEAgent >/dev/null 2>&1; then
  echo "MicroXRCEAgent not found. The Docker build should install it." >&2
  exit 1
fi

echo "Starting Micro XRCE-DDS Agent: ${TRANSPORT} -p ${PORT} -v ${VERBOSE}"
exec MicroXRCEAgent "${TRANSPORT}" -p "${PORT}" -v "${VERBOSE}"
