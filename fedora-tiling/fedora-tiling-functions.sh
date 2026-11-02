#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-functions.sh
# Purpose:  Setup step functions sourced by fedora-tiling-setup.sh
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# 2. Update DNF for faster downloads.
# Parallel downloads and the fastest mirror cut the time of every later dnf step.
# The backup is taken once and each line is only added once, so the step is safe to rerun.
update_dnf() {
    [ -f /etc/dnf/dnf.original ] || sudo cp -p /etc/dnf/dnf.conf /etc/dnf/dnf.original
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
    echo 'Firmware update completed!'
}

# Package names live in package_install.txt so the list can change without editing code.
install_packages() {
    apply_package_list package_install.txt sudo dnf -y install
    echo 'Packages installed successfully!'
}

# Removes unwanted packages listed in package_remove.txt, then drops orphaned dependencies.
remove_packages() {
    apply_package_list package_remove.txt sudo dnf -y remove
    sudo dnf -y autoremove
    echo 'Packages removed successfully!'
}

# 6. Enable Flathub repository.
# Fedora does not enable the full Flathub remote by default, so it is added here.
enable_flathub() {
    sudo dnf -y install flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo 'Flathub repository enabled successfully!'
}

# 7. Install development tools.
install_development_tools(){
    sudo dnf -y group install development-tools
    echo 'Development tools installed successfully!'
}

# Enables the RPM Fusion free and nonfree repositories, which carry the full ffmpeg build and the
# codecs Fedora cannot ship. Release packages that are already installed are skipped on a rerun.
# SECURITY: The release packages are fetched over HTTPS, as RPM Fusion documents, and they install
# the RPM Fusion signing keys with gpgcheck on, so every later package from them is verified.
enable_rpmfusion() {
    local fedora_version repo
    fedora_version="$(rpm -E %fedora)"
    for repo in free nonfree; do
        if ! rpm -q "rpmfusion-$repo-release" > /dev/null 2>&1; then
            sudo dnf -y install "https://mirrors.rpmfusion.org/$repo/fedora/rpmfusion-$repo-release-$fedora_version.noarch.rpm"
        fi
    done
    echo 'RPM Fusion repositories enabled.'
}

# 8. Install codecs.
# Swaps the patent-limited ffmpeg-free build for full ffmpeg so common video formats play.
install_codecs() {
    enable_rpmfusion
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    echo 'Codecs installed successfully!'
}

# 12. Customize tiling settings.
# Installs the Sway, foot, and rofi configs plus the volume helpers. There is no waybar config yet,
# so Sway keeps the bar from Fedora's own /usr/share/sway/config.d files.
customize_tiling() {
    install_config configs/sway/config ~/.config/sway/config
    install_config configs/foot/foot.ini ~/.config/foot/foot.ini
    install_config configs/rofi/config.rasi ~/.config/rofi/config.rasi
    install_config configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi
    install_config scripts/volume-down.sh ~/scripts/volume-down.sh
    install_config scripts/volume-up.sh ~/scripts/volume-up.sh
    echo 'Tiling configs installed. Press Mod+Shift+c in Sway to reload them.'
}

# 14. Install VLC, plugins, and restricted extras.
# The freeworld and ugly packages come from RPM Fusion, so install_codecs enables it and swaps in
# full ffmpeg first.
install_vlc_restricted_extras() {
    install_codecs
    sudo dnf -y install vlc vlc-plugins-freeworld
    sudo dnf -y install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free \
        gstreamer1-plugins-ugly gstreamer1-plugins-bad-freeworld gstreamer1-plugin-libav
    echo 'VLC and multimedia codecs installed successfully!'
}

# 15. Install VSCode.
# SECURITY: Imports the Microsoft signing key and enables gpgcheck so dnf verifies VSCode packages.
install_vscode() {
    echo 'Setting up VSCode repository...'
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    echo 'VSCode repository configured successfully!'
    
    echo 'Installing VSCode...'
    # NOTE: makecache refreshes metadata. dnf check-update exits with 100 when updates exist.
    sudo dnf makecache
    sudo dnf -y install code
    echo 'VSCode installed successfully!'
}

# 16. Install OBS Studio.
# The Flathub build is the one maintained by the OBS project itself.
install_obs() {
    echo 'Installing OBS Studio via Flatpak...'
    enable_flathub
    sudo flatpak install flathub com.obsproject.Studio -y
    mkdir -p ~/.var/app/com.obsproject.Studio/config/obs-studio
    echo 'OBS Studio installed and configured successfully!'
}

# 18. Install and enable firewalld.
# SECURITY: A workstation offers no network services, so every inbound connection the host did not
# start is rejected. firewalld is stateful, so replies to traffic the host started are still let in.
install_firewalld_enable() {
    # firewalld usually ships with Fedora, so this install is a no-op unless it was removed.
    sudo dnf -y install firewalld
    sudo dnf -y install firewall-config
    sudo systemctl enable --now firewalld

    # SECURITY: Fedora desktops can default to the FedoraWorkstation zone, which accepts every TCP
    # and UDP port from 1025 to 65535, and even the public zone allows ssh and mdns. The public zone
    # is stripped of all services and ports and made the default, whichever zone was active before.
    local zone=public
    local service port
    for service in $(sudo firewall-cmd --permanent --zone="$zone" --list-services); do
        sudo firewall-cmd --permanent --zone="$zone" --remove-service="$service"
    done
    for port in $(sudo firewall-cmd --permanent --zone="$zone" --list-ports); do
        sudo firewall-cmd --permanent --zone="$zone" --remove-port="$port"
    done
    # NOTE: DHCPv6 replies do not match a tracked connection, so this one service is kept for IPv6
    # addressing to work. IPv4 DHCP uses raw sockets and is not affected by the zone.
    sudo firewall-cmd --permanent --zone="$zone" --add-service=dhcpv6-client
    sudo firewall-cmd --set-default-zone="$zone"
    sudo firewall-cmd --reload

    sudo firewall-cmd --state
    sudo firewall-cmd --get-active-zones
    sudo firewall-cmd --zone="$zone" --list-all
    # NOTE: A NetworkManager connection with its own zone set ignores the default zone.
    echo "firewalld enabled. Check that every network interface above is in the $zone zone."
}

# 20. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
# Two seconds keeps the menu reachable for an older kernel or recovery mode.
speed_up_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
    # Fedora has no update-grub wrapper, so the config is regenerated directly.
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}

# 21. Install Docker.
install_docker() {
    # Distro Docker packages conflict with docker-ce, so they are removed first.
    # On a fresh install none of them are present, so a failed remove is not an error.
    sudo dnf remove -y \
        docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine || true
    echo 'Old Docker versions removed.'

    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo 'Docker installed successfully!'

    sudo systemctl enable --now docker

    # SECURITY: Docker group membership is root equivalent on this host.
    sudo usermod -aG docker "$USER"
    echo 'User added to the docker group. You need to reboot in order for this to take effect.'
}

# 22. Install VirtualBox.
install_virtualbox() {
    # Compilers, kernel headers, and DKMS are needed to build the VirtualBox kernel modules.
    install_development_tools
    sudo dnf -y install kernel-headers kernel-devel dkms

    # SECURITY: Oracle's key lets dnf verify VirtualBox packages and repository metadata.
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo rpm --import -
    echo 'Oracle public key imported.'

    sudo sh -c 'cat > /etc/yum.repos.d/virtualbox.repo <<EOF
[virtualbox]
name=Fedora \$releasever - \$basearch - VirtualBox
baseurl=https://download.virtualbox.org/virtualbox/rpm/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.virtualbox.org/download/oracle_vbox_2016.asc
EOF'
    echo 'VirtualBox Fedora repository added successfully.'

    sudo dnf -y install VirtualBox-7.1
    echo 'VirtualBox installed successfully!'

    # Membership in vboxusers is needed for USB passthrough to guests.
    sudo usermod -aG vboxusers "$USER"
    echo 'User added to the vboxusers group. You may need to log out and log back in for this to take effect.'
}

# Install Brave web browser.
# SECURITY: The Brave repository file turns on gpgcheck with Brave's signing key.
install_brave_browsers() {
    sudo dnf -y install dnf-plugins-core
    # --overwrite lets a rerun replace the repository file instead of failing.
    sudo dnf config-manager addrepo --overwrite --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo dnf -y install brave-browser
    echo 'Brave browser installed successfully!'
}
