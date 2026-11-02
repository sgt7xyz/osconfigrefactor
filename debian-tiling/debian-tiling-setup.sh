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
    echo '1. Backup configs, Update, install, and remove packages (Will be prompted for root/admin password)'
    echo '2. Create custom directories in your home directory'
    echo '3. Install fonts'
    echo '4. Configure console terminal settings'
    echo '5. Copy wallpapers to your ~/Pictures/wallpapers directory'
    echo '6. Customize tiling settings'
    echo '7. Customize vimrc file settings'
    echo '8. Install VLC, plugins, and restricted extras'
    echo '9. Install UFW and enable it'
    echo '10. Configure swappiness'
    echo '11. Speed up boot time'
    echo '12. Prep and install VSCode'
    echo '13. Configure Git'
    echo '14. Execute all'
    echo '0. Exit'
    echo -n 'Enter the number of your choice: '
    read -r choice

    case $choice in
        1)  
            run_step backup_configs
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            ;; 
            
        2)  run_step create_directories
            ;;          

        3)  run_step install_font
            ;;         
     
        4)  
            run_step configure_console
            ;; 
      
        5)  
            run_step copy_wallpapers
            ;; 
    
        6)  
            run_step customize_tiling
            ;;

        7)  
            run_step configure_vimrc
            ;;
        
        8)  
            run_step install_vlc_restricted_extras
            ;;
        
        9) 
            run_step install_ufw_enable
            ;;
            
        10)  
            run_step configure_swappiness
            ;;
            
        11)  
            run_step speed_boot_time
            ;;

        12) 
            run_step prep_for_vscode_install
            run_step install_vscode
            ;;

        13) 
            run_step configure_git
            ;;

        14) 
            run_step backup_configs
            run_step update_debian
            run_step install_packages
            run_step remove_packages
            run_step create_directories
            run_step install_font
            run_step configure_console
            run_step copy_wallpapers
            run_step customize_tiling
            run_step configure_vimrc
            run_step install_vlc_restricted_extras
            run_step install_ufw_enable
            run_step configure_swappiness
            run_step speed_boot_time
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
