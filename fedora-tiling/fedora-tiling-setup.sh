#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-setup.sh
# Purpose:  Interactive menu that runs the Fedora Sway tiling post-install setup steps
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# Resolve the repo directory so the functions file is found no matter where the script is run from.
declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/fedora-tiling-functions.sh

# Each menu number maps to one or more functions so steps can be rerun individually.
while true; do
    echo
    echo '==============================================='
    echo '    Fedora Tiling Window Manager Setup'
    echo '==============================================='
    echo 'Please select an option:'
    echo
    echo '  System Preparation:'
    echo '1.  Backup configs'
    echo '2.  Update DNF for faster downloads'
    echo '3.  Upgrade Fedora'
    echo '4.  Update firmware'
    echo
    echo '  Package Management:'
    echo '5.  Install and Remove Packages'
    echo '6.  Enable Flathub repository'
    echo '7.  Install development tools'
    echo '8.  Install codecs'
    echo
    echo '  Environment Setup:'
    echo '9.  Create custom directories'
    echo '10. Install Nerd font'
    echo '11. Copy wallpapers'
    echo '12. Customize tiling settings'
    echo '13. Customize vimrc file'
    echo
    echo '  Applications & Tools:'
    echo '14. Install VLC, plugins, and restricted extras'
    echo '15. Install VSCode'
    echo '16. Install OBS Studio'
    echo '17. Configure Git'
    echo
    echo '  System Configuration:'
    echo '18. Install and enable firewalld'
    echo '19. Configure swappiness'
    echo '20. Speed up boot time'
    echo '21. Install Docker'
    echo '22. Install VirtualBox'
    echo
    echo '23. Execute all steps'
    echo '0.  Exit'
    echo
    echo -n 'Enter the number of your choice: '
    read choice

    case $choice in
        1)  
            backup_configs
            ;; 
            
        2)  
            update_dnf
            ;;          

        3)  
            upgrade_fedora
            ;;         
     
        4)  
            update_firmware
            ;; 
      
        5)  
            install_packages
            remove_packages
            ;; 
    
        6)  
            enable_flathub
            ;;

        7) 
            install_development_tools 
            ;;
        
        8)  
            install_codecs
            ;;
        
        9) 
            create_directories
            ;;
            
        10)  
            install_font
            ;;
            
        11)  
            copy_wallpapers
            ;;

        12) 
            customize_tiling
            ;;

        13) 
            configure_vimrc
            ;;

        14) 
            install_vlc_restricted_extras
            ;;

        15)
            install_vscode
            ;;

        16)
            install_obs
            ;;

        17)
            configure_git
            ;;

        18) 
            install_firewalld_enable
            ;;

        19) 
            configure_swappiness
            ;;

        20) 
            speed_up_boot_time
            ;;

        21)
            install_docker
            ;;

        22)
            install_virtualbox
            ;;
        
        23)
            echo 'Executing all setup steps...'
            echo
            backup_configs
            update_dnf
            upgrade_fedora
            update_firmware
            install_packages
            remove_packages
            enable_flathub
            install_development_tools
            install_codecs
            create_directories
            install_font
            copy_wallpapers
            customize_tiling
            configure_vimrc
            install_vlc_restricted_extras
            install_vscode
            install_obs
            configure_git
            install_firewalld_enable
            configure_swappiness
            speed_up_boot_time
            install_docker
            install_virtualbox
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
    read
done

# TODO(sgt7): Add a menu step to install Google Chrome.
# TODO(sgt7): Add a menu step to install mise-en-place.
