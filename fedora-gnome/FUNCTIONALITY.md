# Fedora GNOME Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh Fedora Workstation install into a ready to use GNOME desktop. It speeds up
`dnf`, upgrades the system and firmware, installs and removes packages, adds Flathub and codecs,
applies fonts, wallpapers, and GNOME tweaks, installs VSCode, sets Git defaults, makes sure
firewalld is running, and tunes swappiness and the boot timeout.

Everything is driven from an interactive menu grouped into five sections. Each option runs one step,
so a step can be rerun on its own. Option 21 runs every step in order. After each choice the script
waits for Enter before showing the menu again.

## How the pieces connect

`fedora-gnome-setup.sh` is the file you run. It finds its own directory, sources
`fedora-gnome-functions.sh` to load one function per step, then loops on the menu.

```text
fedora-gnome-setup.sh (menu loop)
  └── sources fedora-gnome-functions.sh
        ├── dnf, flatpak, fwupdmgr  <-- package_install.txt, package_remove.txt
        ├── curl, unzip, fc-cache   <-- Nerd Fonts release on GitHub
        ├── cp, gsettings           <-- wallpapers/
        ├── cp, git config          <-- configs/.gitignore_global
        ├── rpm, dnf                <-- Microsoft VSCode repository
        └── firewall-cmd, sysctl, grub2-mkconfig
```

## File by file walkthrough

Read the files in this order.

### fedora-gnome-setup.sh

**Purpose:** Entry point. Prints the grouped menu, reads a choice, and calls the matching functions.

**Depends on:** `fedora-gnome-functions.sh`.

It resolves its own directory with `dirname` and `realpath` so the functions file is always found.
Option 5 runs the install and remove functions together. Every other option maps to one function.

### fedora-gnome-functions.sh

**Purpose:** Holds one function per setup step. It defines functions only and has no top level
code.

**Depends on:** `sudo`, `dnf`, `rpm`, `flatpak`, `fwupdmgr`, `curl`, `unzip`, `fc-cache`,
`gsettings`, `firewall-cmd`, `git`, and the data files in the repository.

### package_install.txt and package_remove.txt

**Purpose:** Package lists, one name per line. The install list covers GNOME Tweaks, the extensions
app, dconf-editor, fastfetch, nmap, Tilix, and Vim. The remove list holds `tali`.

**Depends on:** Nothing.

### configs/.gitignore_global

**Purpose:** Global Git ignore patterns copied into the home directory by the Git step.

**Depends on:** Nothing.

### .github/workflows/shellcheck.yml

**Purpose:** Runs ShellCheck on every push and pull request.

**Depends on:** GitHub Actions and the CICDToolbox ShellCheck pipeline script.

## Function entries

All functions live in `fedora-gnome-functions.sh` and take no arguments.

### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.bash_profile`, and `~/.bash_logout` into `~/.config-backups`.
* **Inputs:** Those three files.
* **Outputs:** A backup directory.
* **Why it exists:** Keeps the stock dotfiles before later steps change the home directory.
* **Side effects:** File writes. A second run prints a `File exists` error from `mkdir` and then
  overwrites the earlier backups.

### update_dnf

* **Does:** Appends `max_parallel_downloads=10` and `fastestmirror=true` to `/etc/dnf/dnf.conf`.
* **Inputs:** None.
* **Outputs:** A changed dnf config.
* **Why it exists:** Shortens every later dnf step.
* **Side effects:** System file write. Each run appends the lines again.

### upgrade_fedora

* **Does:** Runs `dnf upgrade`.
* **Inputs:** None.
* **Outputs:** Upgraded packages.
* **Why it exists:** Later installs need a current system.
* **Side effects:** Network calls and system package changes.

### update_firmware

* **Does:** Forces a refresh of LVFS firmware metadata, lists updates, and applies them.
* **Inputs:** None.
* **Outputs:** Updated device firmware where supported.
* **Why it exists:** A stale metadata cache hides available firmware updates.
* **Side effects:** Network calls and firmware writes. May ask for confirmation or a reboot.

### install_packages

* **Does:** Installs each package in `package_install.txt`, one at a time.
* **Inputs:** `package_install.txt`, read from the current working directory.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the package list in data instead of code.
* **Side effects:** Network calls and system package changes.

### remove_packages

* **Does:** Removes each package in `package_remove.txt`, then runs `dnf autoremove`.
* **Inputs:** `package_remove.txt`, read from the current working directory.
* **Outputs:** Removed packages.
* **Why it exists:** Clears out unwanted default software.
* **Side effects:** System package removal.

### enable_flathub

* **Does:** Adds the Flathub remote to Flatpak if it is not already there.
* **Inputs:** None.
* **Outputs:** A new system wide Flatpak remote.
* **Why it exists:** Fedora does not enable the full Flathub remote by default.
* **Side effects:** System Flatpak configuration change.

### install_development_tools

* **Does:** Installs the `development-tools` package group.
* **Inputs:** None.
* **Outputs:** Compilers, `make`, and related tools.
* **Why it exists:** Needed to build software from source.
* **Side effects:** System package changes.

### install_codecs

* **Does:** Swaps `ffmpeg-free` for the full `ffmpeg` build.
* **Inputs:** None.
* **Outputs:** Full ffmpeg codec support.
* **Why it exists:** `ffmpeg-free` leaves out patent limited formats.
* **Side effects:** System package changes. The full `ffmpeg` package normally comes from RPM
  Fusion, which this script does not enable, so this step is likely to fail on a stock install.

### install_vlc_multimedia_codecs

* **Does:** Installs VLC, `vlc-extras`, and the GStreamer base, good, and bad free plugin sets.
* **Inputs:** None.
* **Outputs:** Installed packages.
* **Why it exists:** Adds a media player and the codecs available from the default repositories.
* **Side effects:** System package changes.

### create_directories

* **Does:** Creates `~/.themes`, `~/software`, `~/code`, `~/scripts`, `~/.local/share/fonts`,
  `~/.local/share/icons`, `~/Pictures/wallpapers`, and `~/.config/tilix/schemes`.
* **Inputs:** None.
* **Outputs:** New directories.
* **Why it exists:** The font and wallpaper steps copy into these paths.
* **Side effects:** Directory creation.

### install_font

* **Does:** Downloads the DroidSansMono Nerd Font v3.4.0 zip into `~/fonttmp`, copies the `.otf`
  files into `~/.local/share/fonts`, rebuilds the font cache, and removes the temporary folder.
* **Inputs:** A pinned GitHub release URL.
* **Outputs:** Installed user fonts and a list of the matching font names.
* **Why it exists:** Terminal prompts and themes use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It changes the working directory and leaves the
  shell in the home directory, not the repository.

### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers`.
* **Inputs:** `wallpapers/`, relative to the current directory.
* **Outputs:** Image files.
* **Why it exists:** `customize_gnome` points GNOME at one of these copies.
* **Side effects:** File writes.

### customize_gnome

* **Does:** Sets the light and dark wallpaper keys to `fedora-black-4k.png` and adds minimize and
  maximize buttons.
* **Inputs:** The wallpaper copied by `copy_wallpapers`.
* **Outputs:** Changed GNOME settings for the current user.
* **Why it exists:** GNOME picks the wallpaper key from the active theme, so both must be set.
* **Side effects:** Writes to the user dconf database.

### configure_vimrc

* **Does:** Writes a three line `~/.vimrc` with syntax, line numbers, and mouse support.
* **Inputs:** None.
* **Outputs:** `~/.vimrc`.
* **Why it exists:** Gives Vim usable defaults.
* **Side effects:** Overwrites any existing `~/.vimrc`.

### install_numix_theme

* **Does:** Installs the Numix GTK theme and Numix Circle icons, then selects them.
* **Inputs:** None.
* **Outputs:** Installed packages and changed interface settings.
* **Why it exists:** Applies the project's chosen look.
* **Side effects:** System package changes and user dconf writes.

### install_vscode

* **Does:** Imports the Microsoft signing key, writes `/etc/yum.repos.d/vscode.repo` with
  `gpgcheck=1`, and installs the `code` package.
* **Inputs:** None.
* **Outputs:** VSCode installed from Microsoft's repository.
* **Why it exists:** VSCode is not in the Fedora repositories. The key lets dnf verify packages.
* **Side effects:** Network calls, a new repository file, and system package changes.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory if found, sets global Git
  defaults, and prints the resulting config.
* **Inputs:** `configs/.gitignore_global`, relative to the current directory.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. If the ignore file is missing it only warns, and Git still
  points `core.excludesfile` at the missing copy.

### install_firewalld_enable

* **Does:** Installs firewalld if missing, enables and starts it, and prints its state, default
  zone, and rules.
* **Inputs:** None.
* **Outputs:** A running host firewall.
* **Why it exists:** Confirms the firewall is active and shows the rules for review.
* **Side effects:** Service state changes.

### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A sysctl file and the before and after values on screen.
* **Why it exists:** Keeps the desktop in RAM longer before swapping.
* **Side effects:** System file write. Persists across reboots.

### speed_boot_time

* **Does:** Backs up `/etc/default/grub`, changes `GRUB_TIMEOUT=5` to `2`, and regenerates
  `/boot/grub2/grub.cfg`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** A shorter boot menu delay.
* **Why it exists:** Speeds up boot while still leaving time to pick a kernel.
* **Side effects:** Boot configuration change. A second run overwrites the backup with the edited
  file.

## Known limitations or sharp edges

* **Execute all loses the repo directory.** `install_font` runs `cd` and ends in the home
  directory. In option 21, `copy_wallpapers` and `configure_git` then cannot find `wallpapers/` or
  `configs/`.
* **List files lack a trailing newline.** `read` skips the last line, so `vim` is never installed
  and `tali` is never removed. Line 4 of `package_install.txt` also ends with a space.
* **Codecs need RPM Fusion.** `install_codecs` swaps to the full `ffmpeg`, which normally comes
  from RPM Fusion. Nothing in the script enables it.
* **Appends are not idempotent.** `update_dnf` adds duplicate lines on every run.
* **Unused directory.** `~/.config/tilix/schemes` is created but nothing is copied into it yet.
* **No strict mode.** No script uses `set -euo pipefail`, so failures do not stop a run.
* **Working directory matters.** Data files are read relative to the current directory.
* **CI fetches a remote script.** The ShellCheck workflow pipes a script from GitHub into Bash.

## Change log

| Date       | Summary                                                                 |
| :--------- | :---------------------------------------------------------------------- |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed scripts to kebab-case.                  |
