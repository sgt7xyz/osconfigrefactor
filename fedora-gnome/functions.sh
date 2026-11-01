#!/usr/bin/env bash

#1 Backup configs.
backup_configs() {
  mkdir ~/.config-backups
  cp ~/.bashrc ~/.config-backups
  cp ~/.bash_profile ~/.config-backups
  cp ~/.bash_logout ~/.config-backups
}

#2  Update DNF for faster downloads.
update_dnf() {
   echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
   echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
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
}

#5 Install and Remove Packages (Will be prompted for root/admin password.)
install_packages() {
    while IFS= read -r package; do
        sudo dnf -y install "$package"
    done < package_install.txt
    echo 'Packages installed successfully!'
}

remove_packages() {
    while IFS= read -r package; do
        sudo dnf -y remove "$package"
    done < package_remove.txt
    sudo dnf -y autoremove
    echo 'Packages removed successfully!'
}

#6 Enable Flathub repository.
enable_flathub() {
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo 'Flathub repository enabled successfully!'
}

#7 Install development tools.
install_development_tools(){
    sudo dnf -y group install development-tools
}

#8 Install codecs.
install_codecs() {
    sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
    echo 'Codecs installed successfully!'
}

#9 Install VLC and multimedia codecs. 
install_vlc_multimedia_codecs() {
    # Install VLC and related packages
    sudo dnf -y install vlc vlc-extras
    
    # Install available multimedia codecs from default repositories
    sudo dnf -y install gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras
    
    echo 'VLC and available multimedia codecs installed successfully!'
    echo 'Note: Some additional codecs may require RPM Fusion repositories for full multimedia support.'
}

#10 Create custom directories in your home directory.
create_directories() {
    local dirs=(~/.themes ~/software ~/code ~/scripts ~/.local/share/fonts ~/.local/share/icons ~/Pictures/wallpapers ~/.config/tilix/schemes)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

#11 Install fonts.
install_font() {
    font_dir=(~/fonttmp)
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DroidSansMono.zip"
    mkdir -p $font_dir
    echo 'Downloading and Installing Fonts...'
    cd $font_dir
    curl -L $font_url -o "DroidSansMonoNerdFont.zip"
    echo "Unzipping the font..."
    unzip "DroidSansMonoNerdFont.zip" -d "."
    cp *.otf ~/.local/share/fonts/
    echo "Refreshing font cache..."
    fc-cache -f -v
    echo "Cleaning up..."
    cd ..
    rm -rf $font_dir
    fc-list | grep -i DroidSansMNerdFont
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

#12 Copy wallpapers to your ~/Pictures/wallpapers directory.
copy_wallpapers() {
    cp wallpapers/* ~/Pictures/wallpapers
    echo 'Wallpaper copied successfully!'
    echo 'Sometimes you need to log out and login because of a feature in Gnome that does not update the wallpaper immediately.'
}

#13 Customize Gnome settings.
customize_gnome() {
    local wallpaper_path="$HOME/Pictures/wallpapers/fedora-black-4k.png"
    gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_path"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_path"
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
    echo 'Gnome customized successfully!'
}

#14 Configure Vim. 
configure_vimrc() {
    echo "syntax on" > ~/.vimrc
    echo "set number" >> ~/.vimrc
    echo "set mouse=r" >> ~/.vimrc
    echo 'Vim customized successfully!'
}

#15 Install Numix theme and icons.
install_numix_theme() {
    # Install Numix theme and icons from repositories
    sudo dnf -y install numix-gtk-theme numix-icon-theme-circle
    gsettings set org.gnome.desktop.interface gtk-theme Numix
    gsettings set org.gnome.desktop.interface icon-theme Numix-Circle
    echo 'Numix theme installed and configured successfully!'
}

#16 Prep and install VSCode.
install_vscode() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    echo 'VSCode repository configured successfully!'
    
    sudo dnf -y check-update
    sudo dnf -y install code
    echo 'VSCode installed successfully!'
}

#17 Configure Git.
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
    
    # Enable and start firewalld service
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
    
    # Show status and current zones
    sudo firewall-cmd --state
    sudo firewall-cmd --get-default-zone
    sudo firewall-cmd --list-all
    
    echo 'firewalld installed and enabled successfully!'
}

#19 Configure swappiness.
configure_swappiness() {
    echo 'swappiness before configuration:'
    sudo cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'swappiness after configuration:'
    sudo sysctl -a | grep vm.swappiness
}

#20 Speed up boot time.
speed_boot_time() {
    sudo cp -p /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}



