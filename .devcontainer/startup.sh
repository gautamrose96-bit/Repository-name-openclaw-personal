#!/bin/bash
# Ensure openclaw config directory exists and apply gateway config
mkdir -p ~/.openclaw
cp "$(dirname "$0")/openclaw.json" ~/.openclaw/openclaw.json
echo "Gateway config applied!"

nohup openclaw gateway start > /tmp/openclaw.log 2>&1 &
echo "Gateway started!"
nohup bash .devcontainer/keepalive.sh > /tmp/keepalive.log 2>&1 &
echo "Keepalive started!"
