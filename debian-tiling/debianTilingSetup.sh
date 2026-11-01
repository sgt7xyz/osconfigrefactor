#!/usr/bin/env bash

declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/functions.sh

# Menu for selecting the installation steps
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
    echo '15. Execute all'
    echo '0. Exit'
    echo -n 'Enter the number of your choice: '
    read choice

    case $choice in
        1)  
            backup_configs 
            update_debian
            install_packages
            remove_packages
            ;; 
            
        2)  create_directories
            ;;          

        3)  install_font
            ;;         
     
        4)  
            configure_console
            ;; 
      
        5)  
            copy_wallpapers
            ;; 
    
        6)  
            customize_tiling
            ;;

        7)  
            configure_vimrc
            ;;
        
        8)  
            install_vlc_restricted_extras
            ;;
        
        9) 
            install_ufw_enable
            ;;
            
        10)  
            configure_swappiness
            ;;
            
        11)  
            speed_boot_time
            ;;

        12) 
            prep_for_vscode_install
            install_vscode
            ;;

        13) 
            configure_git
            ;;

        15) 
            backup_configs
            update_debian
            install_packages
            remove_packages
            create_directories
            install_font
            configure_console
            copy_wallpapers
            customize_tiling
            configure_vimrc
            install_vlc_restricted_extras
            install_ufw_enable
            configure_swappiness
            speed_boot_time
            prep_for_vscode_install
            install_vscode
            configure_git
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
