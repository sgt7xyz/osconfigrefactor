#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-gnome-functions.sh
# Purpose:  Setup step functions sourced by debian-gnome-setup.sh
# Project:  debian-gnome-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# 1. Back up configs.
# Keeps copies of the stock shell dotfiles before later steps change them. Debian uses ~/.profile,
# so it is included, and missing files are skipped.
backup_configs() {
    mkdir -p ~/.config-backups
    local file
    for file in ~/.bashrc ~/.profile ~/.bash_profile ~/.bash_logout; do
        if [ -f "$file" ]; then
            cp "$file" ~/.config-backups/
        else
            echo "Skipping $file, it does not exist."
        fi
    done
    echo 'Config files backed up successfully!'
}

# Runs right after the backup as part of step 1, so ~/.ssh is ready before any key is copied in.
# SECURITY: Mode 700 keeps other users out of ~/.ssh. Setting it on every run also fixes a folder
# that was created with looser permissions earlier.
create_ssh_directory() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo 'SSH directory ready at ~/.ssh with permissions 700.'
}

# 2. Update, install, and remove packages.
update_debian() {
    sudo apt-get -y update
    sudo apt-get -y upgrade
    echo 'System updated successfully!'
}

# Package names live in package_install.txt so the list can change without editing code.
install_packages() {
    # The -n test also reads a last line that has no trailing newline.
    while IFS= read -r package || [ -n "$package" ]; do
        sudo apt-get -y install "$package" || echo "Could not install $package, continuing." >&2
    done < package_install.txt
    echo 'Packages installed successfully!'
}

# Purges the default GNOME games and apps listed in package_remove.txt, then drops orphaned dependencies.
remove_packages() {
    while IFS= read -r package || [ -n "$package" ]; do
        sudo apt-get -y purge "$package" || echo "Could not purge $package, continuing." >&2
    done < package_remove.txt
    sudo apt-get -y autoremove
    echo 'Packages removed successfully!'
}

# 3. Create custom directories in the home directory.
create_directories() {
    local dirs=(~/.themes ~/.icons ~/software ~/scripts ~/Pictures/wallpapers)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

# 4. Copy wallpapers to ~/Pictures/wallpapers.
copy_wallpapers() {
    cp ./wallpapers/Wallpaper-House.com_391811.jpg ~/Pictures/wallpapers
    echo 'Wallpaper copied successfully!'
    echo 'Sometimes you need to log out and login because of a feature in Gnome that does not update the wallpaper immediately.'
}

# 5. Customize GNOME settings.
# Sets both light and dark wallpaper keys because GNOME picks one based on the active theme.
customize_gnome() {
    local wallpaper_path="$HOME/Pictures/wallpapers/Wallpaper-House.com_391811.jpg"
    gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_path"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_path"
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
    echo 'Gnome customized successfully!'
}

# 6. Customize vimrc file settings.
# NOTE: This overwrites any existing ~/.vimrc.
configure_vimrc() {
    echo "syntax on" > ~/.vimrc
    echo "set number" >> ~/.vimrc
    echo "set mouse=r" >> ~/.vimrc
    echo 'Vim customized successfully!'
}

# 7. Install VLC, plugins, and restricted extras.
# The extra codec packages are needed for formats Debian does not play out of the box.
install_vlc_restricted_extras() {
    sudo apt-get -y install vlc vlc-plugin-samba vlc-plugin-video-splitter
    sudo apt-get -y install libavcodec-extra gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
    echo 'VLC installed and successfully!'
}

# 8. Install UFW and enable it.
# SECURITY: Enables a host firewall that denies inbound traffic by default.
install_ufw_enable() {
    sudo apt-get -y install ufw
    sudo ufw enable
    sudo ufw status verbose
    sudo ufw app list
    echo 'UFW installed and successfully!'
}

# 9. Configure swappiness.
# A value of 10 keeps more of the desktop in RAM instead of swapping it out early.
configure_swappiness() {
    echo 'swappiness before configuration:'
    sudo cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'swappiness after configuration:'
    sysctl vm.swappiness
}

# 10. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
speed_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
    sudo update-grub
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}

# 11. Install Numix theme and icons.
install_numix_theme() {
    sudo apt-get -y install numix-gtk-theme numix-icon-theme-circle
    gsettings set org.gnome.desktop.interface gtk-theme Numix
    gsettings set org.gnome.desktop.interface icon-theme Numix-Circle
    echo 'Numix theme installed and configured successfully!'
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