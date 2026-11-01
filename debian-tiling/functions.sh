#!/usr/bin/env bash

# 1 
backup_configs() {
  mkdir ~/.config-backups
  cp ~/.bashrc ~/.config-backups
  cp ~/.profile ~/.config-backups
  cp ~/.bash_logout ~/.config-backups
}

update_debian() {
    sudo apt-get -y update
    sudo apt-get -y upgrade
    echo 'System updated successfully!'
}

install_packages() {
    while IFS= read -r package; do
        sudo apt-get -y install "$package"
    done < package_install.txt
    echo 'Packages installed successfully!'
}

remove_packages() {
    while IFS= read -r package; do
        sudo apt-get -y purge "$package"
    done < package_remove.txt
    sudo apt-get -y autoremove
    echo 'Packages removed successfully!'
}

# 2
create_directories() {
    local dirs=(~/.config ~/dotfiles ~/.local/share/themes ~/.local/share/fonts ~/.local/share/icons ~/software ~/scripts ~/Pictures/wallpapers)
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

# 3
install_font() {
    font_dir=(~/fonttmp)
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/DroidSansMono.zip"
    mkdir -p $font_dir
    echo 'Downloading and Installing Fonts...'
    cd $font_dir
    curl -L $font_url -o "DroidSansMonoNerdFont.zip"
    echo "Unzipping the font..."
    unzip "DroidSansMonoNerdFont.zip" -d "."
    cp *.otf ~/.local/share/fonts/
    echo "Cleaning up..."
    cd ..
    rm -rf $font_dir
    echo 'Fonts installed successfully. Ensure you select the font in your terminal etc.'
}

# 4
configure_console() {
    sudo dpkg-reconfigure console-setup
}

# 5
copy_wallpapers() {
    cp ./wallpapers/* ~/Pictures/wallpapers/
    echo 'Wallpaper copied successfully!'
}

# 6
customize_tiling() {
    #local dirs=(~/.config/i3/themes ~/.config/alacritty  ~/.config/polybar  ~/.config/rofi) 
    #for dir in "${dirs[@]}"; do
    #   [ -d "$dir" ] || mkdir -p "$dir"
    #done
    #echo 'Tiling Specific Directories created successfully!'
    
    #cp configs/picom.conf ~/.config/picom.conf
    #cp configs/i3config ~/.config/i3/config
    cp configs/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
    #cp configs/alacritty/catppuccin-macchiato.yml ~/.config/alacritty/catppuccin-macchiato.yml
    #cp configs/polybar/config.ini ~/.config/polybar/config.ini
    #cp configs/polybar/launch.sh ~/.config/polybar/launch.sh
    #cp configs/rofi/config.rasi ~/.config/rofi/config.rasi
    #cp configs/rofi/catppuccin-macchiato.rasi ~/.config/rofi/catppuccin-macchiato.rasi
    cp scripts/down_volume.sh ~/scripts/down_volume.sh
    cp scripts/up_volume.sh ~/scripts/up_volume.sh
    
    #echo "" > ~/.Xresources
    #echo "" >> ~/.Xresources
    #echo "" >> ~/.Xresources
    echo 'tiling setup successfully!'
    # Set up scaling for 4k monitor if you manually start your X session with startx. If you use a display manager change it to .xprofile.
    #echo 'xrandr --output HDMI-A-0 --primary --mode 3840x2160 --fb 9000x5760 --rotate normal --scale .8x.8 --panning 5760x3240+0+0' > ~/.xinitrc
}

# 7
configure_vimrc() {
    echo "set noerrorbells" > ~/.vimrc
    echo "set visualbell" >> ~/.vimrc
    echo "set t_vb=" >> ~/.vimrc
    echo "syntax on" >> ~/.vimrc
    echo "set number" >> ~/.vimrc
    echo "set mouse=r" >> ~/.vimrc
    echo 'Vim customized successfully!'
}

# 8
install_vlc_restricted_extras() {
    sudo apt-get -y install vlc vlc-plugin-samba vlc-plugin-video-splitter
    sudo apt-get -y install libavcodec-extra gstreamer1.0-libav gstreamer1.0-plugins-ugly gstreamer1.0-vaapi
    echo 'VLC installed and successfully!'
}

# 9
install_ufw_enable() {
    sudo apt-get -y install ufw
    sudo ufw enable
    sudo ufw status verbose
    sudo ufw app list
    echo 'UFW installed and successfully!'
}

# 10
configure_swappiness() {
    echo 'swappiness before configuration:'
    sudo cat /proc/sys/vm/swappiness
    sudo /bin/su -c "echo 'vm.swappiness = 10' > /etc/sysctl.d/swappiness.conf"
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'swappiness after configuration:'
    sudo sysctl -a | grep vm.swappiness
}

# 11
speed_boot_time() {
    sudo cp /etc/default/grub /etc/default/grub.original
    sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
    sudo update-grub
    sudo grep GRUB_TIMEOUT /etc/default/grub
    echo 'Boot time speed configured successfully!'
}

# 12
prep_for_vscode_install() {
    sudo apt-get -y install wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    echo 'VSScode configured for installation successfully!'
}

install_vscode() {
    sudo apt-get -y install apt-transport-https
    sudo apt-get update
    sudo apt-get -y install code
    echo 'VSScode installed successfully!'
}

# 13
configure_git() {
    cp configs/.gitignore_global ~/
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor vim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
}
