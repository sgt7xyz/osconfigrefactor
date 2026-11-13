#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-gnome-functions.sh
# Purpose:  Setup step functions sourced by fedora-gnome-setup.sh
# Project:  fedora-gnome-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# 1. Backup configs.
# Keeps copies of the stock shell dotfiles before later steps or stow can replace them. Fedora uses
# ~/.bash_profile and Debian uses ~/.profile, so both are tried and missing ones are skipped.
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

# 2. Update DNF for faster downloads.
# Parallel downloads and the fastest mirror cut the time of every later dnf step.
# Each line is only added once, so the step is safe to rerun.
update_dnf() {
    local setting
    for setting in 'max_parallel_downloads=10' 'fastestmirror=true'; do
        grep -qxF "$setting" /etc/dnf/dnf.conf || echo "$setting" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    done
    echo 'DNF configuration updated for faster downloads!'
}

# 3. Upgrade Fedora.
upgrade_fedora() {
    sudo dnf -y upgrade
    echo 'System updated successfully!'
}

# 4. Update firmware.
# Refreshes LVFS metadata first, because a stale cache hides available firmware updates.
# NOTE: fwupdmgr exits with 2 when there is nothing to update, so that case is not an error.
update_firmware() {
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates || echo 'No firmware updates available.'
    sudo fwupdmgr update || echo 'No firmware updates applied.'
}

# 5. Install and remove packages.
# Package names live in package_install.txt so the list can change without editing code.
install_packages() {
    # The -n test also reads a last line that has no trailing newline.
    while IFS= read -r package || [ -n "$package" ]; do
        sudo dnf -y install "$package" || echo "Could not install $package, continuing." >&2
    done < package_install.txt
    echo 'Packages installed successfully!'
}

# Removes unwanted packages listed in package_remove.txt, then drops orphaned dependencies.
remove_packages() {
    while IFS= read -r package || [ -n "$package" ]; do
        sudo dnf -y remove "$package" || echo "Could not remove $package, continuing." >&2
    done < package_remove.txt
    sudo dnf -y autoremove
    echo 'Packages removed successfully!'
}

# 6. Enable Flathub repository.
# Fedora does not enable the full Flathub remote by default, so it is added here.
enable_flathub() {
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo 'Flathub repository enabled successfully!'
}

# 7. Install development tools.
install_development_tools(){
    sudo dnf -y group install development-tools
}

# 8. Enable RPM Fusion Free.
# Enables the only repository that packages full ffmpeg. It is a third party repository, so it is a
# separate step that is only run on machines that want it.
# SECURITY: The release package comes over HTTPS and installs the RPM Fusion signing key, so later
# packages from the repository are checked with gpgcheck. Skipped when the package is already there.
enable_rpmfusion() {
    local fedora_version
    fedora_version="$(rpm -E %fedora)"
    if ! rpm -q rpmfusion-free-release > /dev/null 2>&1; then
        sudo dnf -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$fedora_version.noarch.rpm"
    fi
    echo 'RPM Fusion Free repository enabled.'
}

# 9. Install codecs.
# Swaps the patent-limited ffmpeg-free build for full ffmpeg so common video formats play.
# Needs RPM Fusion Free from step 8, so it stops with a message when that repository is missing.
install_codecs() {
    if ! rpm -q rpmfusion-free-release > /dev/null 2>&1; then
        echo 'Error: RPM Fusion Free is not enabled. Run step 8 first.' >&2
        return 1
    fi
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    # dnf swap can exit 0 without installing ffmpeg, for example when the package is unavailable,
    # so the install is checked here instead of trusting the exit code.
    if ! rpm -q ffmpeg > /dev/null 2>&1; then
        echo 'Error: ffmpeg is not installed after the swap.' >&2
        return 1
    fi
    echo 'Codecs installed successfully!'
}

# 10. Install VLC and multimedia codecs.
install_vlc_multimedia_codecs() {
    # vlc-plugins-extra is the Fedora package for the extra VLC plugins. There is no vlc-extras package.
    sudo dnf -y install vlc vlc-plugins-extra

    # Only default repository plugins are used, so RPM Fusion is not required.
    sudo dnf -y install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras

    echo 'VLC and available multimedia codecs installed successfully!'
    echo 'Note: Some additional codecs may require RPM Fusion repositories for full multimedia support.'
}

# 11. Create custom directories in the home directory.
create_directories() {
    local dirs=(~/.themes ~/software ~/code ~/scripts ~/.local/share/fonts ~/.local/share/icons ~/Pictures/wallpapers ~/.config/tilix/schemes)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

# 12. Install fonts.
# The Nerd Font provides the icon glyphs used by terminal prompts and themes.
# The URLs point at the newest release, so the font is not pinned to one version.
# SECURITY: The archive is checked against SHA-256.txt from the same release. That catches a damaged
# or partial download. It does not catch a tampered release, because both files come from GitHub.
install_font() {
    local font_dir=~/fonttmp
    local release_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    # A failed earlier run can leave files behind, so the work folder starts empty.
    rm -rf "$font_dir"
    mkdir -p "$font_dir" ~/.local/share/fonts
    echo 'Downloading and Installing Fonts...'
    curl -fL "$release_url/SHA-256.txt" -o "$font_dir/SHA-256.txt"
    curl -fL "$release_url/DroidSansMono.zip" -o "$font_dir/DroidSansMono.zip"
    # Only the checksum line for this archive is checked. A missing line makes the check fail.
    (cd "$font_dir" && grep ' DroidSansMono.zip$' SHA-256.txt | sha256sum --check --strict)
    echo "Unzipping the font..."
    unzip -o "$font_dir/DroidSansMono.zip" -d "$font_dir"
    cp "$font_dir"/*.otf ~/.local/share/fonts/
    echo "Refreshing font cache..."
    fc-cache -f -v
    echo "Cleaning up..."
    rm -rf "$font_dir"
    fc-list | grep -i DroidSansMNerdFont || echo 'Warning: the font is not listed by fc-list yet.' >&2
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

# 13. Copy wallpapers to ~/Pictures/wallpapers.
copy_wallpapers() {
    cp wallpapers/* ~/Pictures/wallpapers
    echo 'Wallpaper copied successfully!'
    echo 'Sometimes you need to log out and login because of a feature in Gnome that does not update the wallpaper immediately.'
}

# 14. Customize GNOME settings.
# Sets both light and dark wallpaper keys because GNOME picks one based on the active theme.
customize_gnome() {
    local wallpaper_path="$HOME/Pictures/wallpapers/fedora-black-4k.png"
    gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_path"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_path"
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
    echo 'Gnome customized successfully!'
}

# 15. Configure Neovim.
# NOTE: This overwrites any existing ~/.config/nvim/init.lua. The config matches the macOS setup.
configure_neovim() {
    mkdir -p ~/.config/nvim
    if [ -f configs/nvim/init.lua ]; then
        cp configs/nvim/init.lua ~/.config/nvim/init.lua
    else
        echo 'Warning: configs/nvim/init.lua not found!' >&2
    fi
    echo 'Neovim configured successfully!'
}

# 16. Install Papirus icons.
# Numix was removed from Fedora 45, so Papirus, which Fedora still packages, replaces it. The GTK
# theme is left as it is.
install_papirus_icons() {
    sudo dnf -y install papirus-icon-theme
    gsettings set org.gnome.desktop.interface icon-theme Papirus
    echo 'Papirus icon theme installed and configured successfully!'
}

# 17. Prep and install VSCode.
# SECURITY: Imports the Microsoft signing key and enables gpgcheck so dnf verifies VSCode packages.
install_vscode() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    echo 'VSCode repository configured successfully!'

    # NOTE: makecache refreshes metadata. dnf check-update exits with 100 when updates exist.
    sudo dnf makecache
    sudo dnf -y install code
    echo 'VSCode installed successfully!'
}

# 18. Configure Git.
configure_git() {
    if [ -f configs/.gitignore_global ]; then
        cp configs/.gitignore_global ~/
    else
        echo 'Warning: configs/.gitignore_global not found!'
    fi
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor nvim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    git config --global --list
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
}

# 19. Install and enable firewalld.
# SECURITY: Makes sure the host firewall is running and prints the active zone for review.
install_firewalld_enable() {
    # firewalld usually ships with Fedora, so this install is a no-op unless it was removed.
    sudo dnf -y install firewalld

    sudo systemctl enable firewalld
    sudo systemctl start firewalld

    sudo firewall-cmd --state
    sudo firewall-cmd --get-default-zone
    sudo firewall-cmd --list-all

    echo 'firewalld installed and enabled successfully!'
}

# 20. Configure swappiness.
# A value of 10 keeps more of the desktop in RAM instead of swapping it out early.
configure_swappiness() {
    echo 'swappiness before configuration:'
    sudo cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'swappiness after configuration:'
    sysctl vm.swappiness
}

# 21. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
speed_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}
