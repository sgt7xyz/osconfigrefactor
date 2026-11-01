#!/usr/bin/env bash

# I created this simple script to run on a VirtualBox image for testing purposes.

sudo dnf update && sudo dnf -y upgrade

#For VirtualBox VM
sudo dnf install -y install dkms
sudo dnf install -y install linux-headers
sudo dnf install -y install kernel-devel
