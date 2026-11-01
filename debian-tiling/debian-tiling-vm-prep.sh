#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-tiling-vm-prep.sh
# Purpose:  Prepare a VirtualBox test VM before running the main setup
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Run this only inside a VirtualBox test VM, never on real hardware.

sudo apt-get update && sudo apt-get -y upgrade

# Guest Additions need DKMS and headers that match the running kernel to build their modules.
sudo apt-get -y install dkms
sudo apt-get -y install "linux-headers-$(uname -r)"
