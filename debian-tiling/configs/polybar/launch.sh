#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     launch.sh
# Purpose:  Restart polybar so config changes take effect
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# Stop running bars first so i3 reloads do not stack duplicate bars.
# This needs enable-ipc in the polybar config.
polybar-msg cmd quit
# NOTE: If IPC is disabled, use the line below instead.
# killall -q polybar

# Append to a log so startup errors survive across restarts.
echo "---" | tee -a /tmp/polybar1.log
polybar bar1 2>&1 | tee -a /tmp/polybar1.log & disown

echo "Bars launched..."
