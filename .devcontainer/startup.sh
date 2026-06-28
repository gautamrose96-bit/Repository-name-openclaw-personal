#!/bin/bash
nohup openclaw gateway run > /tmp/openclaw.log 2>&1 &
echo "Gateway started!"
nohup bash .devcontainer/keepalive.sh > /tmp/keepalive.log 2>&1 &
echo "Keepalive started!"
