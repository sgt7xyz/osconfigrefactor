#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-tiling-setup.sh
# Purpose:  Interactive menu that runs the Debian i3 tiling post-install setup steps
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Resolve the repo directory so the functions file is found no matter where the script is run from.
declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

# The shared menu engine and steps load first, then the Debian specific steps.
source "$script_dir"/common-functions.sh
source "$script_dir"/debian-tiling-functions.sh

# The functions read package lists, configs, and wallpapers by relative path.
cd "$script_dir"

# Steps in run order. Steps shared with fedora-tiling keep the same numbers in both repositories,
# and Debian only steps come last.
menu=(
    "# System preparation"
    "backup_configs|Back up shell dotfiles"
    "update_debian|Update and upgrade the system"
    "install_packages remove_packages|Install and remove packages"
    "# Environment setup"
    "create_directories|Create custom directories"
    "install_font|Install Nerd font"
    "copy_wallpapers|Copy wallpapers"
    "customize_tiling|Install i3, polybar, rofi, and alacritty configs"
    "configure_vimrc|Customize vimrc file"
    "configure_git|Configure Git"
    "# Applications"
    "install_vlc_restricted_extras|Install VLC, plugins, and codecs"
    "prep_for_vscode_install install_vscode|Install VSCode"
    "# System configuration"
    "install_ufw_enable|Enable the firewall (deny all inbound)"
    "configure_swappiness|Configure swappiness"
    "speed_boot_time|Speed up boot time"
    "# Debian extras"
    "configure_console|Configure console font and size"
)

run_menu 'Debian Tiling Window Manager Setup' "${menu[@]}"
