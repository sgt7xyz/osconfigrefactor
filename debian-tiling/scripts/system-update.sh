#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     system-update.sh
# Purpose:  Refresh package lists and upgrade all installed packages
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

sudo apt-get update && sudo apt-get -y upgrade
