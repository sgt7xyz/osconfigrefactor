#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     debian-tiling-functions.sh
# Purpose:  Setup step functions sourced by debian-tiling-setup.sh
# Project:  debian-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

update_debian() {
    sudo apt-get -y update
    sudo apt-get -y upgrade
    echo 'System updated successfully!'
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

# 4. Configure console terminal settings.
configure_console() {
    sudo dpkg-reconfigure console-setup
}

# 6. Customize tiling settings.
# Installs the i3, polybar, rofi, picom, and alacritty configs plus the volume helpers.
# NOTE: .Xresources, .xsessionrc, and xorg.conf.new are tuned for one monitor setup, so they are
# left for the user to copy by hand.
customize_tiling() {
    install_config configs/i3config ~/.config/i3/config
    install_config configs/polybar/config.ini ~/.config/polybar/config.ini
    install_config configs/polybar/launch.sh ~/.config/polybar/launch.sh
    # i3 runs the launcher directly, so it must be executable even if an old copy was not.
    chmod +x ~/.config/polybar/launch.sh
    install_config configs/rofi/config.rasi ~/.config/rofi/config.rasi
    install_config configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi
    install_config configs/picom.conf ~/.config/picom.conf
    # Alacritty 0.13 and newer (Debian 13) reads only TOML. Older releases (Debian 12) read only YAML.
    # Both are installed so either version finds its config and ignores the other.
    local file
    for file in alacritty.toml catppuccin-macchiato.toml alacritty.yml catppuccin-macchiato.yml; do
        install_config "configs/alacritty/$file" ~/.config/alacritty/"$file"
    done
    install_config scripts/volume-down.sh ~/scripts/volume-down.sh
    install_config scripts/volume-up.sh ~/scripts/volume-up.sh
    echo 'Tiling configs installed. Press Mod+Shift+r in i3 to reload them.'
}

# 8. Install VLC, plugins, and restricted extras.
# The extra codec packages are needed for formats Debian does not play out of the box.
install_vlc_restricted_extras() {
    sudo apt-get -y install vlc vlc-plugin-samba vlc-plugin-video-splitter
    sudo apt-get -y install libavcodec-extra gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
    echo 'VLC installed successfully!'
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

# 11. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
# Two seconds keeps the menu reachable for an older kernel or recovery mode.
speed_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
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
    echo 'VSCode repository configured successfully!'
}

# Runs after the repository is added, so apt can see the code package.
install_vscode() {
    sudo apt-get -y install apt-transport-https
    sudo apt-get update
    sudo apt-get -y install code
    echo 'VSCode installed successfully!'
}
