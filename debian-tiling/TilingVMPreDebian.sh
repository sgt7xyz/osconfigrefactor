#!/usr/bin/env bash

# I created this simple script to run on a VirtualBox image for testing purposes.

sudo apt-get update && sudo apt-get -y upgrade

#For VirtualBox VM
sudo apt-get -y install dkms
sudo apt-get -y install linux-headers-$(uname -r)
