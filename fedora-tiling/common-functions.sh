#!/usr/bin/env bash

# ---------------------------------------------------------------
# File:     common-functions.sh
# Purpose:  Menu engine and setup steps shared by the Debian and Fedora tiling setups
# Project:  sgt7 Linux tiling setup repositories
# Author:   sgt7 LLC
# ---------------------------------------------------------------

# NOTE: This file is kept byte for byte identical in debian-tiling and fedora-tiling. Change both
# copies together. Anything that differs by distribution belongs in the distro functions file.

# Names of steps that failed during the current menu choice, printed after Execute all.
failed_steps=()

# Runs one step in a subshell with errexit on, so a failing command stops that step only and the
# menu keeps running. The subshell also keeps a step's cd from leaking into later steps.
# NOTE: Bash ignores errexit inside `|| ...` contexts, so errexit is paused here instead.
run_step() {
    local status
    set +e
    ( set -e; "$@" )
    status=$?
    set -e
    if (( status != 0 )); then
        echo "Step '$1' failed with exit code $status." >&2
        failed_steps+=("$1")
    fi
}

# Runs every function named in one menu entry, in order.
run_entry() {
    local functions function
    read -r -a functions <<< "$1"
    for function in "${functions[@]}"; do
        run_step "$function"
    done
}

# Prints a menu built from the entries passed in and runs the chosen step. Entries starting with
# "# " are section titles. Every other entry is "function [function...]|Label" and gets the next
# number. The number after the last step runs every step in order, so the numbering, the menu
# text, and Execute all always agree.
run_menu() {
    local title="$1"
    shift
    local entries=("$@")
    local steps=()
    local entry
    for entry in "${entries[@]}"; do
        [[ "$entry" == "# "* ]] && continue
        steps+=("${entry%%|*}")
    done
    local all=$(( ${#steps[@]} + 1 ))
    local choice number
    while true; do
        echo
        echo '==============================================='
        echo "    $title"
        echo '==============================================='
        number=0
        for entry in "${entries[@]}"; do
            if [[ "$entry" == "# "* ]]; then
                echo
                echo "  ${entry#\# }:"
            else
                number=$(( number + 1 ))
                printf '%2d. %s\n' "$number" "${entry#*|}"
            fi
        done
        echo
        printf '%2d. %s\n' "$all" 'Execute all steps'
        printf '%2d. %s\n' 0 'Exit'
        echo
        # End of input, such as Ctrl-D, is treated as Exit.
        read -r -p 'Enter the number of your choice: ' choice || choice=0
        failed_steps=()
        # The 10# prefix reads input such as 08 as decimal instead of failing as octal.
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            echo 'Invalid option. Please try again.'
        elif (( 10#$choice == 0 )); then
            echo 'Exiting.'
            break
        elif (( 10#$choice <= ${#steps[@]} )); then
            run_entry "${steps[10#$choice - 1]}"
        elif (( 10#$choice == all )); then
            for entry in "${steps[@]}"; do
                run_entry "$entry"
            done
            if (( ${#failed_steps[@]} > 0 )); then
                echo "Finished with failed steps: ${failed_steps[*]}" >&2
            else
                echo 'All setup steps completed!'
            fi
        else
            echo 'Invalid option. Please try again.'
        fi
        echo
        read -r -p 'Press Enter to continue...' || true
    done
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

# Copies one config file into place. An existing file that differs is copied to ~/.config-backups
# first, so a hand edited config is never overwritten without a copy.
install_config() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    if [ -f "$target" ] && ! cmp -s "$source" "$target"; then
        local stamp backup
        stamp="$(date +%Y%m%d%H%M%S)"
        backup=~/.config-backups/"${target#"$HOME"/}.$stamp"
        mkdir -p "$(dirname "$backup")"
        cp -p "$target" "$backup"
        echo "Backed up $target to $backup"
    fi
    cp "$source" "$target"
}

# Keeps copies of the stock shell dotfiles before later steps or stow can replace them. Debian uses
# ~/.profile and Fedora uses ~/.bash_profile, so both are tried and missing ones are skipped.
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

# Runs right after the backup, so ~/.ssh is ready before any key is copied in.
# SECURITY: Mode 700 keeps other users out of ~/.ssh. Setting it on every run also fixes a folder
# that was created with looser permissions earlier.
create_ssh_directory() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo 'SSH directory ready at ~/.ssh with permissions 700.'
}

# Creates the folders that the font, wallpaper, and tiling steps copy into.
create_directories() {
    local dirs=(~/.config ~/dotfiles ~/.local/share/themes ~/.local/share/fonts ~/.local/share/icons ~/software ~/scripts ~/Pictures/wallpapers)
    local dir
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || mkdir -p "$dir"
    done
    echo 'Directories created successfully!'
}

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

# The window manager configs set the wallpaper from ~/Pictures/wallpapers.
copy_wallpapers() {
    if [ ! -d ./wallpapers ]; then
        echo 'Error: ./wallpapers directory not found.' >&2
        return 1
    fi
    mkdir -p ~/Pictures/wallpapers
    cp ./wallpapers/* ~/Pictures/wallpapers/
    echo 'Wallpapers copied successfully!'
}

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

# Sets the same Git defaults on every machine. Name and email are personal, so they are left to the
# user.
configure_git() {
    if [ -f configs/.gitignore_global ]; then
        cp configs/.gitignore_global ~/
    else
        echo 'Warning: configs/.gitignore_global not found!' >&2
    fi
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global core.editor vim
    git config --global pull.rebase false
    git config --global core.excludesfile ~/.gitignore_global
    git config --global --list
    echo 'Base configuration for Git completed. Ensure you set your username and email!'
}

# A value of 10 keeps more of the desktop in RAM instead of swapping it out early.
configure_swappiness() {
    echo 'Swappiness before configuration:'
    cat /proc/sys/vm/swappiness
    echo 'vm.swappiness = 10' | sudo tee /etc/sysctl.d/swappiness.conf > /dev/null
    sudo sysctl -f /etc/sysctl.d/swappiness.conf
    echo 'Swappiness after configuration:'
    sysctl vm.swappiness
    echo 'Swappiness configured successfully!'
}
