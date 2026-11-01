# Debian Tiling Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a minimal Debian install into a keyboard driven desktop built on the i3 tiling
window manager. It installs Xorg, i3, polybar, rofi, alacritty, picom, and a set of developer
tools, then applies fonts, wallpapers, terminal and Vim settings, a firewall, kernel and boot
tweaks, VSCode, and Git defaults.

Everything is driven from an interactive numbered menu. Each option runs one step, so a single step
can be rerun on its own. Option 15 runs every step in order. There is no option 14.

Two terms used below:

* *i3* is the tiling window manager. It reads `~/.config/i3/config`.
* *polybar* is the status bar that i3 starts through `~/.config/polybar/launch.sh`.

## How the pieces connect

`debian-tiling-setup.sh` is the file you run. It finds its own directory, sources
`debian-tiling-functions.sh` to load one function per step, then loops on a menu.

The functions read data from the repository and write into the home directory or system paths:

```text
debian-tiling-setup.sh (menu loop)
  └── sources debian-tiling-functions.sh
        ├── apt-get          <-- package_install.txt, package_remove.txt
        ├── curl, unzip      <-- Nerd Fonts release on GitHub
        ├── cp               <-- wallpapers/, configs/alacritty/, scripts/volume-*.sh
        ├── cp, git config   <-- configs/.gitignore_global
        └── ufw, sysctl, update-grub, dpkg-reconfigure

configs/i3config ──exec──> picom, feh (wallpaper), polybar/launch.sh
                 (copied to ~/.config by hand today, see Known limitations)
```

`debian-tiling-vm-prep.sh` is separate. Run it first inside a VirtualBox VM so Guest Additions can
build.

## File by file walkthrough

Read the files in this order.

### debian-tiling-setup.sh

**Purpose:** Entry point. Prints the menu, reads a choice, and calls the functions for that step.

**Depends on:** `debian-tiling-functions.sh`.

It resolves its own directory with `dirname` and `realpath` so the functions file is always found.
Option 1 runs four functions together and option 12 runs two.

### debian-tiling-functions.sh

**Purpose:** Holds one function per setup step. It defines functions only and has no top level
code.

**Depends on:** `sudo`, `apt-get`, `curl`, `unzip`, `wget`, `gpg`, `ufw`, `git`, and the data
files in the repository.

### debian-tiling-vm-prep.sh

**Purpose:** Updates the system and installs `dkms` plus kernel headers for the running kernel.

**Depends on:** `apt-get`. Meant only for a VirtualBox test VM.

### package_install.txt and package_remove.txt

**Purpose:** Package lists, one name per line. The install list covers Xorg, i3 and its tools,
Python build dependencies, and command line utilities. The remove list holds `aisleriot`.

**Depends on:** Nothing.

### configs/

**Purpose:** Desktop configuration files.

* `i3config` is the i3 config. It sets gaps, starts picom and feh, and runs the polybar launcher.
* `polybar/config.ini` and `polybar/launch.sh` define and restart the status bar.
* `rofi/` holds the launcher config and its Catppuccin Macchiato theme.
* `alacritty/` holds the terminal config and theme in both the old YAML and the current TOML
  format.
* `picom.conf`, `.Xresources`, `.xsessionrc`, and `xorg.conf.new` hold compositor and X settings.
* `.bash_aliases` holds shell aliases. `.gitignore_global` holds global Git ignore patterns.

**Depends on:** The packages from `package_install.txt`.

### configs/polybar/launch.sh

**Purpose:** Stops running bars over IPC, then starts `bar1` and appends its output to
`/tmp/polybar1.log`.

**Depends on:** `enable-ipc` in the polybar config. Called by `exec_always` in `i3config`.

### scripts/

**Purpose:** Small helpers for daily use.

* `volume-up.sh` and `volume-down.sh` change the default audio sink by 5 percent with `wpctl`,
  capped at 150 percent.
* `system-update.sh` runs `apt-get update` and `apt-get upgrade`.

**Depends on:** `wpctl` from WirePlumber, and `apt-get`.

## Function entries

All functions live in `debian-tiling-functions.sh` and take no arguments.

### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.profile`, and `~/.bash_logout` into `~/.config-backups`.
* **Inputs:** Those three files.
* **Outputs:** A backup directory.
* **Why it exists:** Keeps the stock dotfiles in case `stow` or a later step replaces them.
* **Side effects:** File writes. A second run reports that the directory exists and overwrites the
  earlier backups.

### update_debian

* **Does:** Refreshes the apt index and upgrades installed packages.
* **Inputs:** None.
* **Outputs:** Upgraded packages.
* **Why it exists:** Later installs need a current index.
* **Side effects:** Network calls and system package changes through `sudo`.

### install_packages

* **Does:** Installs each package in `package_install.txt`, one at a time.
* **Inputs:** `package_install.txt`, read from the current working directory.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the package list in data instead of code.
* **Side effects:** Network calls and system package changes through `sudo`.

### remove_packages

* **Does:** Purges each package in `package_remove.txt`, then runs `apt-get autoremove`.
* **Inputs:** `package_remove.txt`, read from the current working directory.
* **Outputs:** Removed packages.
* **Why it exists:** Removes software that is not wanted on the desktop.
* **Side effects:** System package removal through `sudo`.

### create_directories

* **Does:** Creates `~/.config`, `~/dotfiles`, `~/.local/share/themes`, `~/.local/share/fonts`,
  `~/.local/share/icons`, `~/software`, `~/scripts`, and `~/Pictures/wallpapers`.
* **Inputs:** None.
* **Outputs:** New directories.
* **Why it exists:** The font, wallpaper, and tiling steps copy into these paths.
* **Side effects:** Directory creation.

### install_font

* **Does:** Downloads the DroidSansMono Nerd Font v3.2.1 zip, unpacks it in `~/fonttmp`, copies
  the `.otf` files into `~/.local/share/fonts`, and removes the temporary directory.
* **Inputs:** A pinned GitHub release URL.
* **Outputs:** Installed user fonts.
* **Why it exists:** Polybar and the terminal theme use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It changes the working directory and leaves the
  shell in the home directory, not the repository.

### configure_console

* **Does:** Runs `dpkg-reconfigure console-setup`.
* **Inputs:** Answers typed into the interactive dialog.
* **Outputs:** A new console font and size.
* **Why it exists:** Makes the text console readable on high resolution screens.
* **Side effects:** System configuration change. Stops for user input.

### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers/`.
* **Inputs:** `wallpapers/`, relative to the current directory.
* **Outputs:** Image files.
* **Why it exists:** `i3config` sets the wallpaper from this folder with feh.
* **Side effects:** File writes.

### customize_tiling

* **Does:** Copies `configs/alacritty/alacritty.yml` to `~/.config/alacritty/` and the two volume
  scripts to `~/scripts/`.
* **Inputs:** Files under `configs/` and `scripts/`.
* **Outputs:** Three copied files.
* **Why it exists:** Installs the terminal config and the volume helpers.
* **Side effects:** File writes. The copies for i3, polybar, rofi, picom, and X settings are
  commented out in the function, so those configs are not installed.

### configure_vimrc

* **Does:** Writes a `~/.vimrc` that silences the bell and turns on syntax, line numbers, and
  mouse support.
* **Inputs:** None.
* **Outputs:** `~/.vimrc`.
* **Why it exists:** Gives Vim usable defaults.
* **Side effects:** Overwrites any existing `~/.vimrc`.

### install_vlc_restricted_extras

* **Does:** Installs VLC, two plugins, and extra codec packages.
* **Inputs:** None.
* **Outputs:** Installed packages.
* **Why it exists:** Debian does not play some common formats out of the box.
* **Side effects:** Network calls and system package changes.

### install_ufw_enable

* **Does:** Installs and enables UFW, then prints its status and application profiles.
* **Inputs:** None.
* **Outputs:** An active host firewall that denies inbound traffic by default.
* **Why it exists:** Debian ships without an active firewall.
* **Side effects:** Firewall rule changes.

### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A sysctl file and the before and after values on screen.
* **Why it exists:** Keeps the desktop in RAM longer before swapping.
* **Side effects:** System file write. Persists across reboots.

### speed_boot_time

* **Does:** Backs up `/etc/default/grub`, changes `GRUB_TIMEOUT=5` to `0`, and runs `update-grub`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** No GRUB menu delay at boot.
* **Why it exists:** Removes the boot wait on single boot machines.
* **Side effects:** Boot configuration change. A second run overwrites the backup with the edited
  file.

### prep_for_vscode_install

* **Does:** Installs `wget` and `gpg`, adds the Microsoft signing key under `/etc/apt/keyrings`,
  and adds the VSCode apt repository.
* **Inputs:** None.
* **Outputs:** A keyring file and `/etc/apt/sources.list.d/vscode.list`.
* **Why it exists:** VSCode is not in the Debian archive. The key lets apt verify its packages.
* **Side effects:** Network call and system file writes.

### install_vscode

* **Does:** Refreshes apt and installs the `code` package.
* **Inputs:** The repository added by `prep_for_vscode_install`.
* **Outputs:** VSCode installed.
* **Why it exists:** Second half of the VSCode step.
* **Side effects:** Network calls and system package changes.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory and sets global Git defaults.
* **Inputs:** `configs/.gitignore_global`, relative to the current directory.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

## Known limitations or sharp edges

* **Execute all loses the repo directory.** `install_font` runs `cd` and ends in the home
  directory. In option 15, every later step that reads `./wallpapers`, `configs/`, or `scripts/`
  then fails. Run steps 5 to 13 one at a time from the repository directory, or rerun the script.
* **Alacritty folder is not created.** `customize_tiling` copies into `~/.config/alacritty`, but
  the line that creates it is commented out, so the copy fails on a fresh install.
* **Most configs are not installed.** i3, polybar, rofi, picom, and X configs must be copied or
  stowed by hand. The function still contains the commented out copy lines.
* **Old Alacritty format.** The function copies `alacritty.yml`. Alacritty 0.13 and newer reads only
  `alacritty.toml`, which is also in `configs/alacritty/`.
* **Mixed audio tools.** The volume scripts use `wpctl`, but the media key bindings in `i3config`
  use `pactl`.
* **Unused helper.** `scripts/system-update.sh` is not copied anywhere by the setup script.
* **No strict mode.** No script uses `set -euo pipefail`, so failures do not stop a run.
* **Working directory matters.** Data files are read relative to the current directory.
* **Last line of a list.** `read` skips a final line with no trailing newline.
* **No CI.** Unlike debian-gnome, this repository has no ShellCheck workflow.

## Change log

| Date       | Summary                                                    |
| :--------- | :--------------------------------------------------------- |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed all scripts to kebab-case. |
