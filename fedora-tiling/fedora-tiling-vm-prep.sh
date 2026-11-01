#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-vm-prep.sh
# Purpose:  Prepare a VirtualBox test VM before running the main setup
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# Run this only inside a VirtualBox test VM, never on real hardware.

sudo dnf update && sudo dnf -y upgrade

# Guest Additions need DKMS and kernel headers to build their modules.
sudo dnf install -y install dkms
sudo dnf install -y install linux-headers
sudo dnf install -y install kernel-devel
