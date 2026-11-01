#!/usr/bin/env bash

# 1 Backup configs.
backup_configs() {
  mkdir -p ~/.config-backups
  cp ~/.bashrc ~/.config-backups 2>/dev/null || echo "Warning: ~/.bashrc not found"
  cp ~/.bash_profile ~/.config-backups 2>/dev/null || echo "Warning: ~/.bash_profile not found"
  cp ~/.bash_logout ~/.config-backups 2>/dev/null || echo "Warning: ~/.bash_logout not found"
  echo 'Config files backed up successfully!'
}

#2  Update DNF for faster downloads.
update_dnf() {
   sudo cp -p /etc/dnf/dnf.conf /etc/dnf/dnf.original
   echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
   echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
   echo 'DNF configuration updated for faster downloads!'
}

#3 Upgrade Fedora.
upgrade_fedora() {
    sudo dnf -y upgrade
    echo 'System updated successfully!'
}

#4 Update firmware.
update_firmware() {
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update
    echo 'Firmware update completed!'
}

#5 Install and Remove Packages
install_packages() {
    if [ -f package_install.txt ]; then
        while IFS= read -r package; do
            sudo dnf -y install "$package"
        done < package_install.txt
        echo 'Packages installed successfully!'
    else
        echo 'Warning: package_install.txt not found!'
    fi
}

remove_packages() {
    if [ -f package_remove.txt ]; then
        while IFS= read -r package; do
            sudo dnf -y remove "$package"
        done < package_remove.txt
        sudo dnf -y autoremove
        echo 'Packages removed successfully!'
    else
        echo 'Warning: package_remove.txt not found!'
    fi
}

#6 Enable Flathub repository.
enable_flathub() {
    sudo dnf -y install flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo 'Flathub repository enabled successfully!'
}

#7 Install development tools.
install_development_tools(){
    sudo dnf -y group install development-tools
    echo 'Development tools installed successfully!'
}

#8 Install codecs.
install_codecs() {
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    echo 'Codecs installed successfully!'
}

#9 Create custom directories in your home directory.
create_directories() {
    local dirs=(~/dotfiles ~/.local/share/themes ~/.local/share/fonts ~/.local/share/icons ~/software ~/scripts ~/Pictures/wallpapers)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

#10. Install fonts.
install_font() {
    local font_dir=~/fonttmp
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DroidSansMono.zip"
    mkdir -p "$font_dir"
    echo 'Downloading and Installing Fonts...'
    cd "$font_dir"
    curl -L "$font_url" -o "DroidSansMonoNerdFont.zip"
    echo "Unzipping the font..."
    unzip "DroidSansMonoNerdFont.zip" -d "."
    cp *.otf ~/.local/share/fonts/
    echo "Refreshing font cache..."
    fc-cache -f -v
    echo "Cleaning up..."
    cd - > /dev/null
    rm -rf "$font_dir"
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

#11 Copy wallpapers to your ~/Pictures/wallpapers directory.
copy_wallpapers() {
    if [ -d "./wallpapers" ]; then
        cp ./wallpapers/* ~/Pictures/wallpapers/ 2>/dev/null
        echo 'Wallpapers copied successfully!'
    else
        echo 'Warning: ./wallpapers directory not found!'
    fi
}

#12 Customize tiling settings.
customize_tiling() {
    # Placeholder for sway tiling configuration
    # Uncomment and modify as needed:
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

    

    # Placeholder for i3 tiling configuration
    # Uncomment and modify as needed:
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

#13 Customize vimrc file settings.
configure_vimrc() {
    echo "set noerrorbells" > ~/.vimrc
    echo "set visualbell" >> ~/.vimrc
    echo "set t_vb=" >> ~/.vimrc
    echo "syntax on" >> ~/.vimrc
    echo "set number" >> ~/.vimrc
    echo "set mouse=r" >> ~/.vimrc
    echo 'Vim customized successfully!'
}

#14 Install VLC, plugins, and restricted extras.
install_vlc_restricted_extras() {
    # Enable RPM Fusion repositories for multimedia codecs
    #sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    #sudo dnf -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    
    sudo dnf -y install vlc vlc-extras
    sudo dnf -y install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly gstreamer1-plugins-bad-nonfree
    sudo dnf -y install ffmpeg
    echo 'VLC and multimedia codecs installed successfully!'
}

#15 Install VSCode
install_vscode() {
    echo 'Setting up VSCode repository...'
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    echo 'VSCode repository configured successfully!'
    
    echo 'Installing VSCode...'
    sudo dnf -y check-update
    sudo dnf -y install code
    echo 'VSCode installed successfully!'
}

#16 Install OBS Studio
install_obs() {
    echo 'Installing OBS Studio via Flatpak...'
    enable_flathub
    sudo flatpak install flathub com.obsproject.Studio -y
    mkdir -p ~/.var/app/com.obsproject.Studio/config/obs-studio
    echo 'OBS Studio installed and configured successfully!'
}

#17 Configure Git
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

#18 Install and enable firewalld.
install_firewalld_enable() {
    # firewalld is usually pre-installed on Fedora, but install if missing
    sudo dnf -y install firewalld
    sudo dnf -y install firewall-config
    
    # Enable and start firewalld service
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    
    # Show status and current zones
    sudo firewall-cmd --state
    sudo firewall-cmd --get-default-zone
    sudo firewall-cmd --list-all
    
    echo 'firewalld installed and enabled successfully!'
}

#18 Configure swappiness
#19 Configure swappiness
configure_swappiness() {
    echo 'Swappiness before configuration:'
    cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'Swappiness after configuration:'
    sudo sysctl -a | grep vm.swappiness
    echo 'Swappiness configured successfully!'
}

#19 Speed up boot time
#20 Speed up boot time
speed_up_boot_time() {
    sudo cp /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
    # Fedora uses grub2-mkconfig instead of update-grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}

#20 Install Docker.
#21 Install Docker.
install_docker() {
    # Remove old Docker versions
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
        docker-engine
    echo 'Old Docker versions removed.'

    # Set up the Docker repository
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Install Docker
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo 'Docker installed successfully!'

    #Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add your user to the docker group
    sudo usermod -aG docker "$USER"
    echo 'User added to the docker group. You need to reboot in order for this to take effect.'
}

#21 Install VirtualBox.
#22 Install VirtualBox.
install_virtualbox() {

    #Install VirtualBox dependencies
    sudo dnf install @development-tools
    sudo dnf install kernel-headers kernel-devel dkms

    # Import Oracle public key
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo rpm --import -
    echo 'Oracle public key imported.'

    # Add VirtualBox Fedora repository
    sudo sh -c 'cat > /etc/yum.repos.d/virtualbox.repo <<EOF
[virtualbox]
name=Fedora $releasever - $basearch - VirtualBox
baseurl=http://download.virtualbox.org/virtualbox/rpm/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.virtualbox.org/download/oracle_vbox_2016.asc
EOF'
 
    echo 'VirtualBox Fedora repository added successfully.'    
    
    # Install VirtualBox
    sudo dnf -y install VirtualBox-7.1
    echo 'VirtualBox installed successfully!'

    # Add the user to the vboxusers group
    sudo usermod -aG vboxusers "$USER"
    echo 'User added to the vboxusers group. You may need to log out and log back in for this to take effect.'
}

#22 Install Brave Web Browser
#23 Install Brave Web Browser
install_brave_browsers() {
	#Install Brave
	sudo dnf install dnf-plugins-core
	sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
	sudo dnf install brave-browser
}
