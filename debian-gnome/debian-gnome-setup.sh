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
    echo '1. Back up configs and create .ssh directory'
    echo '2. Update, install, and remove packages (Will be prompted for root/admin password)'
    echo '3. Update firmware'
    echo '4. Enable Flathub repository'
    echo '5. Install development tools'
    echo '6. Create custom directories in your home directory'
    echo '7. Install fonts'
    echo '8. Copy wallpapers to your ~/Pictures/wallpapers directory'
    echo '9. Customize Gnome settings'
    echo '10. Customize vimrc file settings'
    echo '11. Install VLC, plugins, and restricted extras'
    echo '12. Install UFW and enable it'
    echo '13. Configure swappiness'
    echo '14. Speed up boot time'
    echo '15. Install Numix theme and icons'
    echo '16. Prep and install VSCode'
    echo '17. Configure Git'
    echo '18. Execute all'
    echo '0. Exit'
    echo -n 'Enter the number of your choice: '
    read -r choice

    case $choice in
        1)
            run_step backup_configs
            run_step create_ssh_directory
            ;;

        2)  
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            ;; 
            
        3)
            run_step update_firmware
            ;;

        4)
            run_step enable_flathub
            ;;

        5)
            run_step install_development_tools
            ;;

        6)  
            run_step create_directories
            ;; 

        7)
            run_step install_font
            ;;

        8)  
            run_step copy_wallpapers
            ;; 
    
        9)  
            run_step customize_gnome
            ;;

        10)  
            run_step configure_vimrc
            ;;
        
        11)  
            run_step install_vlc_restricted_extras
            ;;
        
        12) 
            run_step install_ufw_enable
            ;;
            
        13)  
            run_step configure_swappiness
            ;;
            
        14)  
            run_step speed_boot_time
            ;;

        15) 
            run_step install_numix_theme
            ;;
        
        16) 
            run_step prep_for_vscode_install
            run_step install_vscode
            ;;

        17) 
            run_step configure_git
            ;;

        18) 
            run_step backup_configs
            run_step create_ssh_directory
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            run_step update_firmware
            run_step enable_flathub
            run_step install_development_tools
            run_step create_directories
            run_step install_font
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