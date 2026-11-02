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

source "$script_dir"/debian-tiling-functions.sh

# The functions read package lists, configs, and wallpapers by relative path.
cd "$script_dir"

# Names of steps that failed during the current menu choice, printed after Execute all.
failed_steps=()

# Runs one step in a subshell with errexit on, so a failing command stops that step only and the
# menu keeps running. The subshell also keeps a step's cd from leaking into later steps.
# NOTE: Bash ignores errexit inside `|| ...` contexts, so errexit is paused here instead.
run_step() {
    local status
    set +e
    ( set -e; "$@" )
    status=$?
    set -e
    if (( status != 0 )); then
        echo "Step '$1' failed with exit code $status." >&2
        failed_steps+=("$1")
    fi
}

# Runs every function named in one menu entry, in order.
run_entry() {
    local functions function
    read -r -a functions <<< "$1"
    for function in "${functions[@]}"; do
        run_step "$function"
    done
}

# Prints a menu built from the entries passed in and runs the chosen step. Entries starting with
# "# " are section titles. Every other entry is "function [function...]|Label" and gets the next
# number. The number after the last step runs every step in order, so the numbering, the menu
# text, and Execute all always agree.
run_menu() {
    local title="$1"
    shift
    local entries=("$@")
    local steps=()
    local entry
    for entry in "${entries[@]}"; do
        [[ "$entry" == "# "* ]] && continue
        steps+=("${entry%%|*}")
    done
    local all=$(( ${#steps[@]} + 1 ))
    local choice number
    while true; do
        echo
        echo '==============================================='
        echo "    $title"
        echo '==============================================='
        number=0
        for entry in "${entries[@]}"; do
            if [[ "$entry" == "# "* ]]; then
                echo
                echo "  ${entry#\# }:"
            else
                number=$(( number + 1 ))
                printf '%2d. %s\n' "$number" "${entry#*|}"
            fi
        done
        echo
        printf '%2d. %s\n' "$all" 'Execute all steps'
        printf '%2d. %s\n' 0 'Exit'
        echo
        # End of input, such as Ctrl-D, is treated as Exit.
        read -r -p 'Enter the number of your choice: ' choice || choice=0
        failed_steps=()
        # The 10# prefix reads input such as 08 as decimal instead of failing as octal.
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            echo 'Invalid option. Please try again.'
        elif (( 10#$choice == 0 )); then
            echo 'Exiting.'
            break
        elif (( 10#$choice <= ${#steps[@]} )); then
            run_entry "${steps[10#$choice - 1]}"
        elif (( 10#$choice == all )); then
            for entry in "${steps[@]}"; do
                run_entry "$entry"
            done
            if (( ${#failed_steps[@]} > 0 )); then
                echo "Finished with failed steps: ${failed_steps[*]}" >&2
            else
                echo 'All setup steps completed!'
            fi
        else
            echo 'Invalid option. Please try again.'
        fi
        echo
        read -r -p 'Press Enter to continue...' || true
    done
}

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
