#!/usr/bin/env zsh

# ---------------------------------------------------------------
# File:     macos-functions.sh
# Purpose:  Setup step functions sourced by macos-setup.sh
# Project:  macos-setup-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# Set by check_sip_status and read on exit to decide whether to show the SIP warning.
SIP_DISABLED=false

# 1. Update and patch your Mac.
# Installs all updates and restarts if needed, so later steps run on a patched system.
update_patch_mac() {
  echo "Updating and patching Mac..."  
  sudo softwareupdate -iaR --agree-to-license --verbose
}

# 2. Rename your Mac.
# All three names are set because macOS uses each one in a different place (DNS, Bonjour, and Finder).
rename_mac() {
    echo "Renaming Mac..."
    echo 'What would your like to rename your Mac to?'
    read choice
    sudo scutil --set HostName "$choice"
    sudo scutil --set LocalHostName "$choice"
    sudo scutil --set ComputerName "$choice"
    local newHostName
    newHostName=$(scutil --get HostName)
    local newLocalHostName
    newLocalHostName=$(scutil --get LocalHostName)
    local newComputerName
    newComputerName=$(scutil --get ComputerName) 
    echo '#### Computer renaming successful! ####'
    echo "Your new HostName is $newHostName" 
    echo "Your new LocalHostName is $newLocalHostName"
    echo "Your new ComputerName is $newComputerName"
    echo '#######################################'
}

# 3. Install Xcode Command Line Tools.
# Git, make, and compilers come from these tools, and Homebrew needs them.
install_xcode_clt () {
    echo 'Installing XCode Command Line Tools...'
    xcode-select --install
    echo 'Xcode Command Line Tools installed successfully.'
}

# 4. Check System Integrity Protection (SIP) status.
# SECURITY: SIP blocks changes to protected system files, so a disabled state is flagged.
check_sip_status() {
    echo "Checking System Integrity Protection (SIP) status..."
    if ! csrutil status | grep -q "enabled"; then
        echo "SIP is disabled."
        SIP_DISABLED=true
    else
        echo "SIP is enabled."
        SIP_DISABLED=false
    fi
}

# 5. Enable firewall.
# SECURITY: Stealth mode stops the Mac from answering probes such as ping.
enable_firewall() {
    echo "Enabling firewall and firewall stealth mode..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    echo "Firewall enabled."
}

# 6. Disable auto-allow for built-in and downloaded software.
# SECURITY: Signed apps must be approved by hand instead of being let through the firewall silently.
disable_auto_allow() {
    echo "Disabling auto-allow for built-in and downloaded software..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off
    echo "Auto-allow disabled."
}

# Shown on exit so the SIP warning is the last thing the user sees.
display_sip_warning_if_needed() {
    if [ "$SIP_DISABLED" = true ]; then
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "WARNING: System Integrity Protection (SIP) is currently disabled."
        echo "For improved security, it is highly recommended to enable it."
        echo "To enable SIP, reboot into Recovery Mode and run the following command:"
        echo "    csrutil enable && reboot"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi
}

# 7. Install Homebrew.
install_homebrew() {
    local user_ack=${1:-}
    echo 'Installing Homebrew...'
    local cmd_to_run='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    
    if prompt_for_security_risk "$cmd_to_run" "$user_ack"; then
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/steven/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'Homebrew installed successfully.'
    fi
}

# 8. Install Homebrew packages.
# Package names live in brew_install_list.txt so the list can change without editing code.
install_homebrew_packages() {
    echo 'Installing homebrew packages...'
    local app_list="brew_install_list.txt"
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not installed. Please install Homebrew first."
        exit 1
    fi
    
    while IFS= read -r app || [[ -n "$app" ]]; do
        echo "Installing ${app}..."
        brew install "$app"
        done < "$app_list"

    if command -v gcloud &> /dev/null; then
        echo 'Installing gke-gcloud-auth-plugin...'
        gcloud components install gke-gcloud-auth-plugin --quiet
    fi
    echo 'Homebrew packages installed successfully.'
}

# 9. Install mise.
install_mise() {
    local user_ack=${1:-}
    local zshrc_file="$HOME/.zshrc"
    echo 'Installing mise...'

    if ! command -v mise &> /dev/null; then
        local cmd_to_run='curl -fsSL https://mise.run | sh'
        if prompt_for_security_risk "$cmd_to_run" "$user_ack"; then
            echo 'eval "$(~/.local/bin/mise activate zsh)"' >> "$zshrc_file"
            source "$zshrc_file"
            echo 'mise installed successfully.'
        fi
    else
        echo 'mise is already installed.'
    fi
}

# 10. Install mise packages.
# Tools are pinned globally to their latest version. Projects can still pin their own in .mise.toml.
install_mise_packages() {
    echo 'Installing mise packages...'
    local pkg_list="mise_install_list.txt"
    if ! command -v mise &> /dev/null; then
        echo "mise not installed. Please install mise first."
        return 1
    fi

    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        echo "Installing ${pkg}..."
        mise install "${pkg}@latest"
        mise use --global "${pkg}@latest"
    done < "$pkg_list"
    echo 'mise packages installed successfully.'
}

# 12. Configure faster key repeat.
# NOTE: Takes effect after logging out and back in.
configure_key_repeat() {
    echo "Configuring faster key repeat..."
    defaults write -g KeyRepeat -int 1
    defaults write -g InitialKeyRepeat -int 15
    echo "Faster key repeat configured."
}

# 13. Download and install Droid SansM Nerd Font.
# The Nerd Font provides the icon glyphs that Powerlevel10k draws in the prompt.
download_install_font() {
    local font_dir="./fonttmp"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DroidSansMono.zip"
    mkdir -p "$font_dir"
    echo 'Downloading and Installing Fonts...'
    cd "$font_dir" || exit
    curl -L "$font_url" -o "DroidSansMonoNerdFont.zip"
    echo "Unzipping the font..."
    unzip "DroidSansMonoNerdFont.zip" -d "./"
    cp *.otf ~/Library/Fonts/
    echo "Cleaning up..."
    cd ..
    rm -rf "$font_dir"
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

# 14. Install Oh My Zsh and Powerlevel10k.
install_oh_my_zsh_powerlevel10k() {
    local user_ack=${1:-}
    local zshrc_file="$HOME/.zshrc"
    echo 'Installing Oh My Zsh...'
    local cmd_to_run='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    if prompt_for_security_risk "$cmd_to_run" "$user_ack"; then
        echo 'Installing Powerlevel10k...'
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k"
        cp -p ~/.zshrc ~/.zshrc.orig
        ls -al ~/.zshrc*
        sed -i .bak 's|ZSH_THEME="robbyrussell"|ZSH_THEME="powerlevel10k/powerlevel10k"|g' "$zshrc_file"
        source "$zshrc_file"
        echo 'Oh My Zsh and Powerlevel10k installed and configured successfully.'
    fi
}

# 15. Configure Git.
configure_git() {
    cp configs/.gitignore_global ~/
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor vim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
}

# 16. Configure application themes.
configure_themes() {
    echo "Configuring application themes..."

    local nvim_config_dir="$HOME/.config/nvim"
    mkdir -p "$nvim_config_dir"

    # The init.lua uses vim.pack.add to fetch the Catppuccin theme on first launch.
    if [[ -f "$script_dir/configs/nvim/init.lua" ]]; then
        cp "$script_dir/configs/nvim/init.lua" "$nvim_config_dir/init.lua"
        echo "Neovim configuration installed."
    else
        echo "Warning: Neovim config file not found at $script_dir/configs/nvim/init.lua"
    fi

    # A home level .editorconfig gives every editor the same defaults outside of repos.
    if [[ -f "$script_dir/configs/.editorconfig" ]]; then
        cp "$script_dir/configs/.editorconfig" "$HOME/.editorconfig"
        echo "EditorConfig installed to home directory."
    fi

    echo "Theme configuration completed."
}

# SECURITY: Every curl | sh install goes through this gate so remote code never runs without consent.
# A "y" or "n" passed in from Execute All skips the prompt.
prompt_for_security_risk() {
    local cmd_to_run=$1
    local user_ack=${2:-}

    if [[ "$user_ack" =~ ^[Yy]$ ]]; then
        eval "$cmd_to_run"
        return 0
    fi

    if [[ "$user_ack" =~ ^[Nn]$ ]]; then
        echo "Installation skipped by pre-acknowledged user choice."
        return 1
    fi

    echo "WARNING: You are about to execute a script from the internet using 'curl | sh'."
    echo "This can be a security risk as it runs the script with the same permissions as your user account."
    echo "Please make sure you trust the source of the script."
    echo
    echo "Command to be executed:"
    echo "$cmd_to_run"
    echo
    read "reply?Do you want to proceed? (y/n) "
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        eval "$cmd_to_run"
        return 0
    else
        echo "Installation aborted by user."
        return 1
    fi
}