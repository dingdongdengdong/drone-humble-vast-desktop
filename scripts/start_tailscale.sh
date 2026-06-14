#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${TAILSCALE_STATE_DIR:-/var/lib/tailscale}"
mkdir -p "${STATE_DIR}"

if ! command -v tailscaled >/dev/null 2>&1 || ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale is not installed in this image" >&2
  exit 1
fi

if ! pgrep -x tailscaled >/dev/null 2>&1; then
  echo "Starting tailscaled"
  tailscaled --state="${STATE_DIR}/tailscaled.state" --socket=/var/run/tailscale/tailscaled.sock &
  sleep 2
fi

if [ -n "${TS_AUTHKEY:-}" ]; then
  echo "Running tailscale up using TS_AUTHKEY"
  tailscale up --authkey="${TS_AUTHKEY}" --hostname="${TS_HOSTNAME:-drone-humble-vast}" ${TS_EXTRA_ARGS:-}
else
  echo "No TS_AUTHKEY set. Run this manually:"
  echo "  tailscale up --hostname=${TS_HOSTNAME:-drone-humble-vast}"
fi

tailscale status || true
tailscale ip -4 || true
