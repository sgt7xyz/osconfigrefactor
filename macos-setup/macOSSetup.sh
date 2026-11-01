#!/usr/bin/env zsh

declare script_dir="$(realpath $(dirname -- "$0"))"
source $script_dir/macOSFunctions.sh
NETWORK_SCRIPT="$script_dir/macOSNetwork.sh"

# --- Global Variables ---
log_file="setup_log_$(date +'%Y-%m-%d_%H-%M-%S').log"

# --- Helper Functions ---
log_execution() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Executing: $1" >> "$log_file"
    echo "Logging execution of $1 to $log_file"
}

# --- Main Menu Loop ---
while true; do
    echo
    echo '==============================================='
    echo '    macOS Setup'
    echo '==============================================='
    echo 'Please select an option:'
    echo
    echo '  System Preparation:'
    echo '1. Update and patch your Mac (Will be prompted for admin password)'
    echo '2. Rename your Mac (Will be prompted for admin password)'
    echo '3. Install Xcode Command Line Tools'
    echo
    echo '  Security:'
    echo '4. Check System Integrity Protection (SIP) Status'
    echo '5. Enable Firewall'
    echo '6. Disable auto-allow for built-in and downloaded software'
    echo
    echo '  Package Management:'
    echo '7. Install Homebrew'
    echo '8. Install Homebrew Packages'
    echo '9. Install mise'
    echo '10. Install mise Packages'
    echo
    echo '  Network:'
    echo '11. Configure DNS (macOS Network Utility)'
    echo
    echo '  Environment Setup:'
    echo '12. Configure faster key repeat'
    echo '13. Download and install Droid SansM Nerd Font'
    echo '14. Install Oh My Zsh and Powerlevel10k'
    echo '15. Configure git'
    echo '16. Configure application themes (Catppuccin Macchiato)'
    echo
    echo '17. Execute All'
    echo '0. Exit'
    echo
    echo -n 'Enter the number of your choice: '
    read choice

    case $choice in
        1)  
            log_execution "update_patch_mac"
            update_patch_mac
            ;; 
            
        2)  
            log_execution "rename_mac"
            rename_mac
            ;; 

        3)  
            log_execution "install_xcode_clt"
            install_xcode_clt 
            ;; 
    
        4)
            log_execution "check_sip_status"
            check_sip_status
            ;;

        5)
            log_execution "enable_firewall"
            enable_firewall
            ;;
        
        6)
            log_execution "disable_auto_allow"
            disable_auto_allow
            ;;

        7)
            log_execution "install_homebrew"
            install_homebrew
            ;;

        8)
            log_execution "install_homebrew_packages"
            install_homebrew_packages
            ;;
        
        9)
            log_execution "install_mise"
            install_mise
            ;;

        10)
            log_execution "install_mise_packages"
            install_mise_packages
            ;;

        11)
            log_execution "macOSNetwork"
            if [[ -x "$NETWORK_SCRIPT" ]]; then
                sudo zsh "$NETWORK_SCRIPT"
            else
                echo "Error: $NETWORK_SCRIPT not found or not executable."
            fi
            ;;

        12)
            log_execution "configure_key_repeat"
            configure_key_repeat
            ;;

        13)
            log_execution "download_install_font"
            download_install_font
            ;;

        14)
            log_execution "install_oh_my_zsh_powerlevel10k"
            install_oh_my_zsh_powerlevel10k
            ;;

        15)
            log_execution "configure_git"
            configure_git
            ;;

        16)
            log_execution "configure_themes"
            configure_themes
            ;;

        17)
            log_execution "Execute All"
            echo "The 'Execute All' option includes steps that execute scripts from the internet via 'curl | sh'."
            echo "This can be a security risk."
            local user_ack_unsafe
            read -p "Do you want to approve all of these for this run? (y/n) " -n 1 -r reply
            echo
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                user_ack_unsafe="y"
            else
                user_ack_unsafe="n"
            fi

            log_execution "update_patch_mac"
            update_patch_mac
            log_execution "rename_mac"
            rename_mac
            log_execution "install_xcode_clt"
            install_xcode_clt
            log_execution "check_sip_status"
            check_sip_status
            log_execution "enable_firewall"
            enable_firewall
            log_execution "disable_auto_allow"
            disable_auto_allow
            log_execution "install_homebrew"
            install_homebrew "$user_ack_unsafe"
            log_execution "install_homebrew_packages"
            install_homebrew_packages
            log_execution "install_mise"
            install_mise "$user_ack_unsafe"
            log_execution "install_mise_packages"
            install_mise_packages
            log_execution "macOSNetwork"
            if [[ -x "$NETWORK_SCRIPT" ]]; then
                sudo zsh "$NETWORK_SCRIPT"
            fi
            log_execution "configure_key_repeat"
            configure_key_repeat
            log_execution "download_install_font"
            download_install_font
            log_execution "install_oh_my_zsh_powerlevel10k"
            install_oh_my_zsh_powerlevel10k "$user_ack_unsafe"
            log_execution "configure_git"
            configure_git
            log_execution "configure_themes"
            configure_themes
            ;;

        0)
            display_sip_warning_if_needed
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