#!/bin/bash
# NOTE: GitHub Codespaces auto-suspend when you disconnect and have monthly
# free-hour limits, so this is NOT a reliable 24/7 host. To run OpenClaw
# non-stop, deploy the Gateway to an always-on server: see deploy/vps/README.md.
#
# This script only starts the Gateway in the foreground of a background process
# while the Codespace happens to be awake.

# Apply gateway config if present.
if [ -f "$(dirname "$0")/openclaw.json" ]; then
  mkdir -p ~/.openclaw
  cp "$(dirname "$0")/openclaw.json" ~/.openclaw/openclaw.json
  echo "Gateway config applied!"
fi

# `gateway run` runs the Gateway in the foreground. (`gateway start` manages a
# systemd/launchd service, which is not available in a Codespace.)
nohup openclaw gateway run > /tmp/openclaw.log 2>&1 &
echo "Gateway started!"
nohup bash .devcontainer/keepalive.sh > /tmp/keepalive.log 2>&1 &
echo "Keepalive started!"
