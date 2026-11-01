#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-gnome-setup.sh
# Purpose:  Interactive menu that runs the Debian GNOME post-install setup steps
# Project:  debian-gnome-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Resolve the repo directory so the functions file is found no matter where the script is run from.
declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/debian-gnome-functions.sh

# The functions read package lists, configs, and wallpapers by relative path.
cd "$script_dir"

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
    fi
}

# Each menu number maps to one or more functions so steps can be rerun individually.
while true; do
    echo 'Please select an option:'
    echo '1. Update, install, and remove packages (Will be prompted for root/admin password)'
    echo '2. Create custom directories in your home directory'
    echo '3. Copy wallpapers to your ~/Pictures/wallpapers directory'
    echo '4. Customize Gnome settings'
    echo '5. Customize vimrc file settings'
    echo '6. Install VLC, plugins, and restricted extras'
    echo '7. Install UFW and enable it'
    echo '8. Configure swappiness'
    echo '9. Speed up boot time'
    echo '10. Install Numix theme and icons'
    echo '11. Prep and install VSCode'
    echo '12. Configure Git'
    echo '13. Execute all'
    echo '0. Exit'
    echo -n 'Enter the number of your choice: '
    read -r choice

    case $choice in
        1)  
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            ;; 
            
        2)  
            run_step create_directories
            ;; 

        3)  
            run_step copy_wallpapers
            ;; 
    
        4)  
            run_step customize_gnome
            ;;

        5)  
            run_step configure_vimrc
            ;;
        
        6)  
            run_step install_vlc_restricted_extras
            ;;
        
        7) 
            run_step install_ufw_enable
            ;;
            
        8)  
            run_step configure_swappiness
            ;;
            
        9)  
            run_step speed_boot_time
            ;;

        10) 
            run_step install_numix_theme
            ;;
        
        11) 
            run_step prep_for_vscode_install
            run_step install_vscode
            ;;

        12) 
            run_step configure_git
            ;;

        13) 
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            run_step create_directories
            run_step copy_wallpapers
            run_step customize_gnome
            run_step configure_vimrc
            run_step install_vlc_restricted_extras
            run_step install_ufw_enable
            run_step configure_swappiness
            run_step speed_boot_time
            run_step install_numix_theme
            run_step prep_for_vscode_install
            run_step install_vscode
            run_step configure_git
            ;;

        0)
            echo 'Exiting.'
            break
            ;;
        *)
            echo 'Invalid option. Please try again.'
            ;;
    esac
done