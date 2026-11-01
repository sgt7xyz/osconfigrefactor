#!/usr/bin/env bash

declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/functions.sh

# Menu for selecting the installation steps
while true; do
    echo
    echo '==============================================='
    echo '         Fedora GNOME Setup Script'
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
    echo '9.  Install VLC and multimedia codecs'
    echo
    echo '  Environment Setup:'
    echo '10. Create custom directories'
    echo '11. Install fonts'
    echo '12. Copy wallpapers'
    echo '13. Customize GNOME settings'
    echo '14. Configure Vim'
    echo '15. Install Numix theme and icons'
    echo
    echo '  Applications & Tools:'
    echo '16. Install VSCode'
    echo '17. Configure Git'
    echo
    echo '  System Configuration:'
    echo '18. Install and enable firewalld'
    echo '19. Configure swappiness'
    echo '20. Speed up boot time'
    echo
    echo '21. Execute all steps'
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
            install_vlc_multimedia_codecs
            ;;
        
        10)  
            create_directories
            ;;
            
        11)  
            install_font
            ;;
            
        12)  
            copy_wallpapers
            ;;

        13) 
            customize_gnome
            ;;
        
        14) 
            configure_vimrc
            ;;

        15) 
            install_numix_theme
            ;;

        16) 
            install_vscode
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
            speed_boot_time
            ;;

        21) 
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
            install_vlc_multimedia_codecs
            create_directories
            install_font
            copy_wallpapers
            customize_gnome
            configure_vimrc
            install_numix_theme
            install_vscode
            configure_git
            install_firewalld_enable
            configure_swappiness
            speed_boot_time
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