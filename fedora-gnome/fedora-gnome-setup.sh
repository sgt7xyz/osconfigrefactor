#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-gnome-setup.sh
# Purpose:  Interactive menu that runs the Fedora GNOME post-install setup steps
# Project:  fedora-gnome-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

set -euo pipefail

# Resolve the repo directory so the functions file is found no matter where the script is run from.
declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/fedora-gnome-functions.sh

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
    echo
    echo '==============================================='
    echo '         Fedora GNOME Setup Script'
    echo '==============================================='
    echo 'Please select an option:'
    echo
    echo '  System Preparation:'
    echo '1.  Backup configs and create .ssh directory'
    echo '2.  Update DNF for faster downloads'
    echo '3.  Upgrade Fedora'
    echo '4.  Update firmware'
    echo
    echo '  Package Management:'
    echo '5.  Install and Remove Packages'
    echo '6.  Enable Flathub repository'
    echo '7.  Install development tools'
    echo '8.  Enable RPM Fusion Free repository'
    echo '9.  Install codecs'
    echo '10. Install VLC and multimedia codecs'
    echo
    echo '  Environment Setup:'
    echo '11. Create custom directories'
    echo '12. Install fonts'
    echo '13. Copy wallpapers'
    echo '14. Customize GNOME settings'
    echo '15. Configure Vim'
    echo '16. Install Papirus icons'
    echo
    echo '  Applications & Tools:'
    echo '17. Install VSCode'
    echo '18. Configure Git'
    echo
    echo '  System Configuration:'
    echo '19. Install and enable firewalld'
    echo '20. Configure swappiness'
    echo '21. Speed up boot time'
    echo
    echo '22. Execute all steps'
    echo '0.  Exit'
    echo
    echo -n 'Enter the number of your choice: '
    read -r choice

    case $choice in
        1)  
            run_step backup_configs
            run_step create_ssh_directory
            ;; 
            
        2)  
            run_step update_dnf
            ;; 

        3)  
            run_step upgrade_fedora
            ;; 
    
        4)  
            run_step update_firmware
            ;;

        5)  
            run_step install_packages
            run_step remove_packages
            ;;
        
        6)  
            run_step enable_flathub
            ;;
        
        7)  
            run_step install_development_tools
            ;;

        8) 
            run_step enable_rpmfusion
            ;;
            

        9) 
            run_step install_codecs
            ;;

        10) 
            run_step install_vlc_multimedia_codecs
            ;;
        
        11)  
            run_step create_directories
            ;;
            
        12)  
            run_step install_font
            ;;
            
        13)  
            run_step copy_wallpapers
            ;;

        14) 
            run_step customize_gnome
            ;;
        
        15) 
            run_step configure_vimrc
            ;;

        16) 
            run_step install_papirus_icons
            ;;

        17) 
            run_step install_vscode
            ;;

        18) 
            run_step configure_git
            ;;

        19) 
            run_step install_firewalld_enable
            ;;

        20) 
            run_step configure_swappiness
            ;;

        21) 
            run_step speed_boot_time
            ;;

        22) 
            echo 'Executing all setup steps...'
            echo
            run_step backup_configs
            run_step create_ssh_directory
            run_step update_dnf
            run_step upgrade_fedora
            run_step update_firmware
            run_step install_packages
            run_step remove_packages
            run_step enable_flathub
            run_step install_development_tools
            run_step enable_rpmfusion
            run_step install_codecs
            run_step install_vlc_multimedia_codecs
            run_step create_directories
            run_step install_font
            run_step copy_wallpapers
            run_step customize_gnome
            run_step configure_vimrc
            run_step install_papirus_icons
            run_step install_vscode
            run_step configure_git
            run_step install_firewalld_enable
            run_step configure_swappiness
            run_step speed_boot_time
            echo
            echo 'All setup steps completed!'
            ;;

        0)
            echo 'Exiting.'
            break
            ;;
        *)
            echo 'Invalid option. Please try again.'
            ;;
    esac
    echo
    echo 'Press Enter to continue...'
    read -r
done