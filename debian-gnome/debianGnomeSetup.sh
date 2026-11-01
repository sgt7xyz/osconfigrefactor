#!/usr/bin/env bash

declare script_dir_path
script_dir_path="$(dirname -- "$0")"

declare script_dir
script_dir="$(realpath "$script_dir_path")"

source "$script_dir"/functions.sh

# Menu for selecting the installation steps
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
            update_debian
            install_packages
            remove_packages
            ;; 
            
        2)  
            create_directories
            ;; 

        3)  
            copy_wallpapers
            ;; 
    
        4)  
            customize_gnome
            ;;

        5)  
            configure_vimrc
            ;;
        
        6)  
            install_vlc_restricted_extras
            ;;
        
        7) 
            install_ufw_enable
            ;;
            
        8)  
            configure_swappiness
            ;;
            
        9)  
            speed_boot_time
            ;;

        10) 
            install_numix_theme
            ;;
        
        11) 
            prep_for_vscode_install
            install_vscode
            ;;

        12) 
            configure_git
            ;;

        13) 
            update_debian
            install_packages
            remove_packages
            create_directories
            copy_wallpapers
            customize_gnome
            configure_vimrc
            install_vlc_restricted_extras
            install_ufw_enable
            configure_swappiness
            speed_boot_time
            install_numix_theme
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