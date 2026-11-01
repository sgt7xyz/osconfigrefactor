#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-vm-prep.sh
# Purpose:  Prepare a VirtualBox test VM before running the main setup
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Run this only inside a VirtualBox test VM, never on real hardware.

sudo dnf -y upgrade

# Guest Additions need DKMS and kernel headers to build their modules.
sudo dnf -y install dkms kernel-headers kernel-devel
