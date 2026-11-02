#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     fedora-tiling-functions.sh
# Purpose:  Setup step functions sourced by fedora-tiling-setup.sh
# Project:  fedora-tiling-sgt7
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# 1. Backup configs.
# Keeps copies of the stock shell dotfiles before later steps change them.
backup_configs() {
  mkdir -p ~/.config-backups
  cp ~/.bashrc ~/.config-backups 2>/dev/null || echo "Warning: ~/.bashrc not found"
  cp ~/.bash_profile ~/.config-backups 2>/dev/null || echo "Warning: ~/.bash_profile not found"
  cp ~/.bash_logout ~/.config-backups 2>/dev/null || echo "Warning: ~/.bash_logout not found"
  echo 'Config files backed up successfully!'
}

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

# 5. Install and remove packages.
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

# 8. Install codecs.
# Swaps the patent-limited ffmpeg-free build for full ffmpeg so common video formats play.
install_codecs() {
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    echo 'Codecs installed successfully!'
}

# 9. Create custom directories in the home directory.
create_directories() {
    local dirs=(~/dotfiles ~/.local/share/themes ~/.local/share/fonts ~/.local/share/icons ~/software ~/scripts ~/Pictures/wallpapers)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

# 10. Install Nerd font.
# The Nerd Font provides the icon glyphs used by the bar, launcher, and terminal.
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

# 11. Copy wallpapers to ~/Pictures/wallpapers.
copy_wallpapers() {
    if [ -d "./wallpapers" ]; then
        cp ./wallpapers/* ~/Pictures/wallpapers/
        echo 'Wallpapers copied successfully!'
    else
        echo 'Warning: ./wallpapers directory not found!'
    fi
}

# 12. Customize tiling settings.
customize_tiling() {
    # Sway and foot are the active setup. Only their configs are copied for now.
    local dirs=(~/.config/sway ~/.config/foot ~/.config/alacritty ~/.config/waybar ~/.config/rofi) 
    for dir in "${dirs[@]}"; do
       [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Tiling Specific Directories created successfully!'
     
    cp configs/sway/config ~/.config/sway/config
    cp configs/foot/foot.ini ~/.config/foot/foot.ini
    
    #cp configs/alacritty/catppuccin-macchiato.yml ~/.config/alacritty/catppuccin-macchiato.yml
    #cp configs/polybar/config.ini ~/.config/polybar/config.ini
    #cp configs/polybar/launch.sh ~/.config/polybar/launch.sh
    #cp configs/rofi/config.rasi ~/.config/rofi/config.rasi
    #cp configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi

    

    # NOTE: The i3 block below is kept as a reference for an X11 setup and is not used by Sway.
    #local dirs=(~/.config/i3/themes ~/.config/alacritty  ~/.config/polybar  ~/.config/rofi) 
    #for dir in "${dirs[@]}"; do
    #   [ -d "$dir" ] || mkdir -p "$dir"
    #done
    #echo 'Tiling Specific Directories created successfully!'
    
    #cp configs/picom.conf ~/.config/picom.conf
    #cp configs/i3config ~/.config/i3/config
    #cp configs/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
    #cp configs/alacritty/catppuccin-macchiato.yml ~/.config/alacritty/catppuccin-macchiato.yml
    #cp configs/polybar/config.ini ~/.config/polybar/config.ini
    #cp configs/polybar/launch.sh ~/.config/polybar/launch.sh
    #cp configs/rofi/config.rasi ~/.config/rofi/config.rasi
    #cp configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi

    # Set up scaling for 4k monitor if you manually start your X session with startx
    #echo 'xrandr --output HDMI-A-0 --primary --mode 3840x2160 --fb 9000x5760 --rotate normal --scale .8x.8 --panning 5760x3240+0+0' > ~/.xinitrc
    
    echo 'Tiling setup completed (placeholder - customize as needed)!'
}

# 13. Customize vimrc file settings.
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

# 14. Install VLC, plugins, and restricted extras.
install_vlc_restricted_extras() {
    # NOTE: The nonfree and ugly plugins come from RPM Fusion. Uncomment these lines if it is not enabled yet.
    #sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    #sudo dnf -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    
    sudo dnf -y install vlc vlc-extras
    sudo dnf -y install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly gstreamer1-plugins-bad-nonfree
    sudo dnf -y install ffmpeg
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

# 17. Configure Git.
configure_git() {
    if [ -f configs/.gitignore_global ]; then
        cp configs/.gitignore_global ~/
    else
        echo 'Warning: configs/.gitignore_global not found!'
    fi
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor vim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    git config --global --list
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
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

# 19. Configure swappiness.
# A value of 10 keeps more of the desktop in RAM instead of swapping it out early.
configure_swappiness() {
    echo 'Swappiness before configuration:'
    cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'Swappiness after configuration:'
    sysctl vm.swappiness
    echo 'Swappiness configured successfully!'
}

# 20. Speed up boot time.
# Backs up the GRUB config once, so a rerun cannot replace the original with an edited copy.
speed_up_boot_time() {
    [ -f /etc/default/grub.original ] || sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
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

    sudo systemctl enable docker
    sudo systemctl start docker

    # SECURITY: Docker group membership is root equivalent on this host.
    sudo usermod -aG docker "$USER"
    echo 'User added to the docker group. You need to reboot in order for this to take effect.'
}

# 22. Install VirtualBox.
install_virtualbox() {

    # Kernel headers and DKMS are needed to build the VirtualBox kernel modules.
    sudo dnf -y install @development-tools
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
# TODO(sgt7): Add this to the menu. It is not called from fedora-tiling-setup.sh yet.
install_brave_browsers() {
	sudo dnf install dnf-plugins-core
	sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
	sudo dnf install brave-browser
}
