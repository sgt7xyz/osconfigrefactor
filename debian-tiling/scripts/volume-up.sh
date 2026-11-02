#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     volume-up.sh
# Purpose:  Raise the default audio sink volume by 5 percent
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# The -l 1.5 limit stops the volume from going past 150 percent.
wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
