# Fedora GNOME Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh Fedora Workstation install into a ready to use GNOME desktop. It speeds up
`dnf`, upgrades the system and firmware, installs and removes packages, adds Flathub and codecs,
applies fonts, wallpapers, and GNOME tweaks, installs VSCode, sets Git defaults, makes sure
firewalld is running, and tunes swappiness and the boot timeout.

Everything is driven from an interactive menu grouped into five sections. Each option runs one step,
so a step can be rerun on its own. Option 22 runs every step in order. After each choice the script
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
        ├── cp, git config          <-- configs/.gitignore_global, configs/nvim/init.lua
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

The script runs with `set -euo pipefail` and changes into the repository directory, so the data
files are found wherever it is started from. Every function call goes through `run_step`, so a
failing command stops only that step and the menu keeps running.

### fedora-gnome-functions.sh

**Purpose:** Holds one function per setup step. It defines functions only and has no top level
code.

**Depends on:** `sudo`, `dnf`, `rpm`, `flatpak`, `fwupdmgr`, `curl`, `unzip`, `fc-cache`,
`gsettings`, `firewall-cmd`, `git`, and the data files in the repository.

### package_install.txt and package_remove.txt

**Purpose:** Package lists, one name per line. The install list covers GNOME Tweaks, the extensions
app, dconf-editor, fastfetch, nmap, Tilix, and Neovim. The remove list holds `tali`.

**Depends on:** Nothing.

### configs/.gitignore_global

**Purpose:** Global Git ignore patterns copied into the home directory by the Git step.

**Depends on:** Nothing.

### configs/nvim/init.lua

**Purpose:** Neovim config copied to `~/.config/nvim` by the Neovim step. It is the same file as
`macos-setup/configs/nvim/init.lua`. It installs the Catppuccin Macchiato theme with `vim.pack`,
then turns on line numbers, a status line, and visible whitespace.

**Depends on:** Neovim 0.12 or newer, and network access on first launch to clone the theme from
GitHub.

### .github/workflows/shellcheck.yml

**Purpose:** Runs ShellCheck on every push and pull request. It downloads ShellCheck v0.11.0,
checks the archive against a pinned SHA-256, and lints every tracked `.sh` file with `-x`. Any
finding fails the job.

**Depends on:** GitHub Actions and `actions/checkout`, pinned to the commit SHA of v7.0.1.

## Function entries

### run_step

* **Does:** Runs one step function in a subshell with errexit on, then prints the exit code if the
  step failed.
* **Inputs:** The function name to run.
* **Outputs:** The step's output, plus an error line on failure.
* **Why it exists:** Under `set -e` alone, any failing command would close the whole menu. Bash
  also ignores errexit inside `||` lists, so the helper pauses errexit in the menu shell instead.
* **Side effects:** None of its own. A `cd` or variable change inside a step stays in its subshell.

All other functions live in `fedora-gnome-functions.sh` and take no arguments.

### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.profile`, `~/.bash_profile`, and `~/.bash_logout` into `~/.config-backups`.
* **Inputs:** Those four files. A file that does not exist is skipped with a message.
* **Outputs:** A backup folder with copies of the files that exist.
* **Why it exists:** Keeps the stock dotfiles before later steps change the home directory.
* **Side effects:** File writes. Safe to rerun, but it overwrites the earlier backups.

### create_ssh_directory

* **Does:** Creates `~/.ssh` if it is missing and sets its permissions to `700`.
* **Inputs:** None.
* **Outputs:** An empty `~/.ssh` folder that only the owner can open. No keys are created or copied.
* **Why it exists:** Gives SSH keys a private place before they are added. The mode is set on every run, so a folder that was left readable by other users is fixed.
* **Side effects:** Creates a directory and changes its permissions.

### update_dnf

* **Does:** Adds `max_parallel_downloads=10` and `fastestmirror=true` to `/etc/dnf/dnf.conf` if
  they are not already there.
* **Inputs:** None.
* **Outputs:** A changed dnf config.
* **Why it exists:** Shortens every later dnf step.
* **Side effects:** System file write. Safe to rerun.

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
  `fwupdmgr` exits with 2 when there is nothing to do, so a non-zero exit there only prints a
  message.

### install_packages

* **Does:** Installs each package in `package_install.txt`, one at a time.
* **Inputs:** `package_install.txt`. A package that fails to install is reported and skipped.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the package list in data instead of code.
* **Side effects:** Network calls and system package changes.

### remove_packages

* **Does:** Removes each package in `package_remove.txt`, then runs `dnf autoremove`.
* **Inputs:** `package_remove.txt`. A package that fails to remove is reported and skipped.
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

### enable_rpmfusion

* **Does:** Installs the RPM Fusion Free release package for the running Fedora version, if it is not already installed.
* **Inputs:** The Fedora version from `rpm -E %fedora`.
* **Outputs:** The RPM Fusion Free repository, with its signing key imported.
* **Why it exists:** Full `ffmpeg` is only packaged by RPM Fusion Free, not by Fedora.
* **Side effects:** Adds a third party repository and imports its signing key through `sudo`.

### install_codecs

* **Does:** Checks that RPM Fusion Free is enabled, then swaps `ffmpeg-free` for the full `ffmpeg` build.
* **Inputs:** None.
* **Outputs:** Full ffmpeg codec support. Returns an error if RPM Fusion Free is missing or `ffmpeg` is not installed afterwards.
* **Why it exists:** `ffmpeg-free` leaves out patent limited formats. `dnf swap` can exit 0 without
  installing `ffmpeg`, so the result is checked directly.
* **Side effects:** System package changes through `sudo`. It does not add a repository, so run step 8 first.

### install_vlc_multimedia_codecs

* **Does:** Installs VLC, `vlc-plugins-extra`, and the GStreamer base, good, and bad free plugin sets.
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

* **Does:** Downloads the latest DroidSansMono Nerd Font zip and its `SHA-256.txt` into `~/fonttmp`,
  checks the zip against that checksum, copies the `.otf` files into `~/.local/share/fonts`, rebuilds
  the font cache, and removes the temporary folder.
* **Inputs:** The GitHub `latest` release URLs for the zip and checksum file. The font version is not pinned.
* **Outputs:** Installed user fonts and a list of the matching font names.
* **Why it exists:** Terminal prompts and themes use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It works with full paths and never changes the
  working directory.

### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers`.
* **Inputs:** `wallpapers/`.
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

### configure_neovim

* **Does:** Creates `~/.config/nvim` and copies `configs/nvim/init.lua` into it. Prints a warning if
  the file is missing.
* **Inputs:** `configs/nvim/init.lua`.
* **Outputs:** `~/.config/nvim/init.lua`.
* **Why it exists:** Gives Neovim the same settings as the macOS setup.
* **Side effects:** Overwrites any existing `~/.config/nvim/init.lua` without a backup.

### install_papirus_icons

* **Does:** Installs the Papirus icon theme and selects it. The GTK theme is not changed.
* **Inputs:** None.
* **Outputs:** Installed packages and changed interface settings.
* **Why it exists:** Applies the project's chosen look.
* **Side effects:** System package changes and user dconf writes.

### install_vscode

* **Does:** Imports the Microsoft signing key, writes `/etc/yum.repos.d/vscode.repo` with
  `gpgcheck=1`, refreshes metadata with `dnf makecache`, and installs the `code` package.
* **Inputs:** None.
* **Outputs:** VSCode installed from Microsoft's repository.
* **Why it exists:** VSCode is not in the Fedora repositories. The key lets dnf verify packages.
* **Side effects:** Network calls, a new repository file, and system package changes.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory if found, sets global Git
  defaults, and prints the resulting config.
* **Inputs:** `configs/.gitignore_global`.
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
* **Side effects:** Boot configuration change. The backup is only made once.

## Known limitations or sharp edges

* **Failures stop a step, not the run.** In option 22 a failed step prints an error and the next
  step still runs. Scroll back to check for `failed with exit code` lines.
* **Unused directory.** `~/.config/tilix/schemes` is created but nothing is copied into it yet.
* **Neovim needs 0.12 or newer.** `configs/nvim/init.lua` calls `vim.pack`, which older packaged
  versions lack. Run `nvim --version` before relying on the config.

## Change log

| Date       | Summary                                                                                                  |
| :--------- | :------------------------------------------------------------------------------------------------------- |
| 2026-11-13 | Replaced Vim with Neovim, which copies the macOS init.lua and sets Git's editor to nvim. |
| 2026-11-08 | Replaced Numix with Papirus icons, because Fedora 45 no longer packages Numix. |
| 2026-11-08 | Added unzip to the package list, which the Nerd Font step needs on a stock install. |
| 2026-11-08 | Font step now fetches the latest Nerd Font release and verifies it against that release's SHA-256.txt. |
| 2026-11-08 | Replaced the missing vlc-extras package with vlc-plugins-extra, so the VLC step installs again. |
| 2026-11-08 | Moved RPM Fusion Free into its own menu option 8, so codecs no longer enable it.                         |
| 2026-11-08 | Enabled RPM Fusion Free before the ffmpeg swap and made the codec step fail when ffmpeg is missing. |
| 2026-11-08 | Aligned the backup step with the other setups: adds `~/.profile` and skips missing files with a note. |
| 2026-11-08 | Added a `.ssh` directory step with `700` permissions to the backup step. |
| 2026-11-01 | Replaced the ShellCheck workflow with a pinned, checksum verified release and checkout SHA.              |
| 2026-11-01 | Added strict mode with per step error handling and fixed the package lists, font step, and dnf settings. |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed scripts to kebab-case.                                                   |
