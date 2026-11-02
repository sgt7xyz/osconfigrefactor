#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-setup.sh
# Purpose:  Interactive menu that runs the Fedora Sway tiling post-install setup steps
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Resolve the repo directory so the functions file is found no matter where the script is run from.
declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

# The shared menu engine and steps load first, then the Fedora specific steps.
source "$script_dir"/common-functions.sh
source "$script_dir"/fedora-tiling-functions.sh

# The functions read package lists, configs, and wallpapers by relative path.
cd "$script_dir"

# Steps in run order. Steps shared with debian-tiling keep the same numbers in both repositories,
# and Fedora only steps come last.
menu=(
    "# System preparation"
    "backup_configs|Back up shell dotfiles"
    "update_dnf upgrade_fedora|Update and upgrade the system"
    "install_packages remove_packages|Install and remove packages"
    "# Environment setup"
    "create_directories|Create custom directories"
    "install_font|Install Nerd font"
    "copy_wallpapers|Copy wallpapers"
    "customize_tiling|Install Sway, foot, and rofi configs"
    "configure_vimrc|Customize vimrc file"
    "configure_git|Configure Git"
    "# Applications"
    "install_vlc_restricted_extras|Install VLC, plugins, and codecs"
    "install_vscode|Install VSCode"
    "# System configuration"
    "install_firewalld_enable|Enable the firewall (deny all inbound)"
    "configure_swappiness|Configure swappiness"
    "speed_up_boot_time|Speed up boot time"
    "# Fedora extras"
    "update_firmware|Update firmware"
    "enable_flathub|Enable Flathub repository"
    "install_development_tools|Install development tools"
    "install_obs|Install OBS Studio"
    "install_docker|Install Docker"
    "install_virtualbox|Install VirtualBox"
    "install_brave_browsers|Install Brave browser"
)

run_menu 'Fedora Tiling Window Manager Setup' "${menu[@]}"

# TODO(sgt7): Add a menu step to install Google Chrome.
# TODO(sgt7): Add a menu step to install mise-en-place.
