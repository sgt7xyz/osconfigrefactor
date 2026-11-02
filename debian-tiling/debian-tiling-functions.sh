#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-tiling-functions.sh
# Purpose:  Setup step functions sourced by debian-tiling-setup.sh
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# 1. Backup configs, update, install, and remove packages.
# Keeps copies of the stock shell dotfiles before later steps or stow can replace them.
backup_configs() {
    mkdir -p ~/.config-backups
    local file
    for file in ~/.bashrc ~/.profile ~/.bash_logout; do
        cp "$file" ~/.config-backups/ || echo "Warning: $file not found, skipping." >&2
    done
    echo 'Config files backed up successfully!'
}

update_debian() {
    sudo apt-get -y update
    sudo apt-get -y upgrade
    echo 'System updated successfully!'
}

# Runs a package command once per name in a list file. A bad name does not stop the rest, but every
# failure is listed at the end and the step returns non-zero so run_step reports it.
apply_package_list() {
    local list_file="$1"
    shift
    if [ ! -f "$list_file" ]; then
        echo "Error: $list_file not found." >&2
        return 1
    fi
    local package
    local failed=()
    # The list is read on fd 3 so a package tool that reads stdin cannot swallow the remaining names.
    # The -n test also reads a last line that has no trailing newline. Blank and # lines are skipped.
    while read -r package <&3 || [ -n "$package" ]; do
        [[ -z "$package" || "$package" == \#* ]] && continue
        "$@" "$package" || failed+=("$package")
    done 3< "$list_file"
    if (( ${#failed[@]} > 0 )); then
        echo "Failed for these packages in $list_file: ${failed[*]}" >&2
        return 1
    fi
}

# Package names live in package_install.txt so the list can change without editing code.
install_packages() {
    apply_package_list package_install.txt sudo apt-get -y install
    echo 'Packages installed successfully!'
}

# Purges unwanted packages listed in package_remove.txt, then drops orphaned dependencies.
remove_packages() {
    apply_package_list package_remove.txt sudo apt-get -y purge
    sudo apt-get -y autoremove
    echo 'Packages removed successfully!'
}

# 2. Create custom directories in the home directory.
create_directories() {
    local dirs=(~/.config ~/dotfiles ~/.local/share/themes ~/.local/share/fonts ~/.local/share/icons ~/software ~/scripts ~/Pictures/wallpapers)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

# 3. Install fonts.
# The Nerd Font provides the glyphs that polybar and the terminal theme rely on.
# SECURITY: The archive is checked against the SHA-256 published with the release, so a changed
# download is rejected before anything is installed.
install_font() {
    local font_dir=~/fonttmp
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DroidSansMono.zip"
    local font_sha256="030229341907c833862f00682f0f4bce65d0dc8d281fc9a40d80b7ee9d306e88"
    # A failed earlier run can leave files behind, so the work folder starts empty.
    rm -rf "$font_dir"
    mkdir -p "$font_dir" ~/.local/share/fonts
    echo 'Downloading and Installing Fonts...'
    curl -fL "$font_url" -o "$font_dir/DroidSansMonoNerdFont.zip"
    echo "$font_sha256  $font_dir/DroidSansMonoNerdFont.zip" | sha256sum --check --strict
    echo "Unzipping the font..."
    unzip -o "$font_dir/DroidSansMonoNerdFont.zip" -d "$font_dir"
    cp "$font_dir"/*.otf ~/.local/share/fonts/
    echo "Refreshing font cache..."
    fc-cache -f
    echo "Cleaning up..."
    rm -rf "$font_dir"
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

# 4. Configure console terminal settings.
configure_console() {
    sudo dpkg-reconfigure console-setup
}

# 5. Copy wallpapers to ~/Pictures/wallpapers.
copy_wallpapers() {
    cp ./wallpapers/* ~/Pictures/wallpapers/
    echo 'Wallpaper copied successfully!'
}

# 6. Customize tiling settings.
# NOTE: Most config copies below are commented out, so only alacritty and the volume scripts are installed.
customize_tiling() {
    #local dirs=(~/.config/i3/themes ~/.config/alacritty  ~/.config/polybar  ~/.config/rofi) 
    #for dir in "${dirs[@]}"; do
    #   [ -d "$dir" ] || mkdir -p "$dir"
    #done
    #echo 'Tiling Specific Directories created successfully!'
    
    #cp configs/picom.conf ~/.config/picom.conf
    #cp configs/i3config ~/.config/i3/config
    mkdir -p ~/.config/alacritty ~/scripts
    cp configs/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
    #cp configs/alacritty/catppuccin-macchiato.yml ~/.config/alacritty/catppuccin-macchiato.yml
    #cp configs/polybar/config.ini ~/.config/polybar/config.ini
    #cp configs/polybar/launch.sh ~/.config/polybar/launch.sh
    #cp configs/rofi/config.rasi ~/.config/rofi/config.rasi
    #cp configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi
    cp scripts/volume-down.sh ~/scripts/volume-down.sh
    cp scripts/volume-up.sh ~/scripts/volume-up.sh
    
    #echo "" > ~/.Xresources
    #echo "" >> ~/.Xresources
    #echo "" >> ~/.Xresources
    echo 'tiling setup successfully!'
    # Set up scaling for 4k monitor if you manually start your X session with startx. If you use a display manager change it to .xprofile.
    #echo 'xrandr --output HDMI-A-0 --primary --mode 3840x2160 --fb 9000x5760 --rotate normal --scale .8x.8 --panning 5760x3240+0+0' > ~/.xinitrc
}

# 7. Customize vimrc file settings.
# NOTE: This overwrites any existing ~/.vimrc. The bell settings silence the terminal beep.
configure_vimrc() {
    cat > ~/.vimrc <<'VIMRC'
set noerrorbells
set visualbell
set t_vb=
syntax on
set number
set mouse=r
VIMRC
    echo 'Vim customized successfully!'
}

# 8. Install VLC, plugins, and restricted extras.
# The extra codec packages are needed for formats Debian does not play out of the box.
install_vlc_restricted_extras() {
    sudo apt-get -y install vlc vlc-plugin-samba vlc-plugin-video-splitter
    sudo apt-get -y install libavcodec-extra gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
    echo 'VLC installed and successfully!'
}

# 9. Install UFW and enable it.
# SECURITY: A workstation offers no network services, so every inbound connection the host did not
# start is denied. UFW is stateful, so replies to traffic the host started are still let back in.
install_ufw_enable() {
    sudo apt-get -y install ufw
    # SECURITY: Stock UFW also accepts inbound mDNS and UPnP multicast for service discovery. Those
    # rules are deleted so nothing on the LAN can reach discovery services on this host. Each rules
    # file is backed up once, so a rerun cannot replace the original with an edited copy.
    local rules
    for rules in /etc/ufw/before.rules /etc/ufw/before6.rules; do
        [ -f "$rules.original" ] || sudo cp -p "$rules" "$rules.original"
        sudo sed -i -E '/^-A ufw6?-before-input .*--dport (5353|1900) -j ACCEPT$/d' "$rules"
    done
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    # NOTE: --force skips the confirmation prompt, which would otherwise read the next menu answer.
    sudo ufw --force enable
    # The reload applies the edited rules files when UFW was already enabled before this step.
    sudo ufw reload
    sudo ufw status verbose
    echo 'UFW enabled. Inbound connections the host did not start are denied.'
}

# 10. Configure swappiness.
# A value of 10 keeps more of the desktop in RAM instead of swapping it out early.
configure_swappiness() {
    echo 'swappiness before configuration:'
    sudo cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'swappiness after configuration:'
    sysctl vm.swappiness
}

# 11. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
speed_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
    sudo update-grub
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}

# 12. Prep and install VSCode.
# SECURITY: Adds the Microsoft signing key so apt verifies VSCode packages.
prep_for_vscode_install() {
    sudo apt-get -y install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    echo 'VSScode configured for installation successfully!'
}

# Runs after the repository is added, so apt can see the code package.
install_vscode() {
    sudo apt-get -y install apt-transport-https
    sudo apt-get update
    sudo apt-get -y install code
    echo 'VSScode installed successfully!'
}

# 13. Configure Git.
configure_git() {
    cp configs/.gitignore_global ~/
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor vim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
}
