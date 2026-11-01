# Fedora Tiling Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a Fedora install running the Sway tiling compositor into a ready to use
workstation. It speeds up `dnf`, upgrades the system and firmware, installs packages, Flathub,
codecs, a Nerd Font, wallpapers, and the Sway and foot configs, then installs VSCode, OBS Studio,
Docker, and VirtualBox, and applies Git, firewall, swappiness, and boot settings.

Two terms used below:

* *Sway* is a Wayland tiling compositor that reads `~/.config/sway/config`. The repository name
  says "tiling" because it started as an i3 setup on X11.
* *foot* is the Wayland terminal emulator that the Sway config launches.

Everything is driven from an interactive menu grouped into five sections. Each option runs one step,
and option 23 runs every step in order. After each choice the script waits for Enter.

## How the pieces connect

`fedora-tiling-setup.sh` is the file you run. It finds its own directory, sources
`fedora-tiling-functions.sh` to load one function per step, then loops on the menu.

```text
fedora-tiling-setup.sh (menu loop)
  └── sources fedora-tiling-functions.sh
        ├── dnf, flatpak, fwupdmgr  <-- package_install.txt, package_remove.txt
        ├── curl, unzip, fc-cache   <-- Nerd Fonts release on GitHub
        ├── cp                      <-- wallpapers/, configs/sway/, configs/foot/
        ├── cp, git config          <-- configs/.gitignore_global
        ├── rpm, dnf                <-- Microsoft, Docker, and Oracle repositories
        └── firewall-cmd, sysctl, grub2-mkconfig, usermod
```

`fedora-tiling-vm-prep.sh` is separate. Run it first inside a VirtualBox test VM.

## File by file walkthrough

Read the files in this order.

### fedora-tiling-setup.sh

**Purpose:** Entry point. Prints the grouped menu, reads a choice, and calls the matching functions.

**Depends on:** `fedora-tiling-functions.sh`.

It resolves its own directory with `dirname` and `realpath`. Option 5 runs the install and remove
functions together. The file ends with `TODO(sgt7):` notes for Chrome and mise-en-place steps.

### fedora-tiling-functions.sh

**Purpose:** Holds one function per setup step, plus `install_brave_browsers`, which no menu option
calls yet.

**Depends on:** `sudo`, `dnf`, `dnf-3`, `rpm`, `flatpak`, `fwupdmgr`, `curl`, `wget`, `unzip`,
`fc-cache`, `firewall-cmd`, `git`, and the data files in the repository.

### fedora-tiling-vm-prep.sh

**Purpose:** Updates the system and installs DKMS and kernel development packages.

**Depends on:** `dnf`. Meant only for a VirtualBox test VM.

### package_install.txt and package_remove.txt

**Purpose:** Package lists, one name per line. The install list covers command line tools, Neovim,
rofi for Wayland, display tools, and the GNOME keyring. The remove list holds `aisleriot`.

**Depends on:** Nothing.

### configs/

**Purpose:** Desktop configuration files.

* `sway/config` is the Sway config. It sets keys and outputs, exports the Wayland environment to
  systemd, and starts the GNOME keyring daemon for secrets and SSH keys.
* `foot/foot.ini` is the terminal config.
* `rofi/` holds the launcher config and its Catppuccin Macchiato theme. It is not copied yet.
* `waybar/` is an empty placeholder kept with a `.keep` file.
* `.gitignore_global` holds global Git ignore patterns.

**Depends on:** The packages from `package_install.txt`.

### scripts/

**Purpose:** `volume-up.sh` and `volume-down.sh` change the default audio sink by 5 percent with
`wpctl`, capped at 150 percent.

**Depends on:** `wpctl` from WirePlumber. Nothing copies or binds these scripts yet.

### fixed.txt

**Purpose:** The owner's scratch list of menu steps that still need work: 12, 14, 17, and 21.

**Depends on:** Nothing.

## Function entries

All functions live in `fedora-tiling-functions.sh` and take no arguments.

### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.bash_profile`, and `~/.bash_logout` into `~/.config-backups`.
* **Inputs:** Those three files.
* **Outputs:** A backup directory, with a warning for each file that is missing.
* **Why it exists:** Keeps the stock dotfiles before later steps change the home directory.
* **Side effects:** File writes. Safe to rerun, but it overwrites the earlier backups.

### update_dnf

* **Does:** Backs up `/etc/dnf/dnf.conf` to `dnf.original`, then appends parallel download and
  fastest mirror settings.
* **Inputs:** None.
* **Outputs:** A changed dnf config.
* **Why it exists:** Shortens every later dnf step.
* **Side effects:** System file writes. Each run appends the lines again and replaces the backup.

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

### install_packages and remove_packages

* **Does:** Installs each package in `package_install.txt`, then removes each package in
  `package_remove.txt` and runs `dnf autoremove`. Each warns and skips if its list is missing.
* **Inputs:** The two list files, read from the current working directory.
* **Outputs:** Installed and removed packages.
* **Why it exists:** Keeps the package lists in data instead of code.
* **Side effects:** Network calls and system package changes.

### enable_flathub

* **Does:** Installs Flatpak and adds the Flathub remote if missing.
* **Inputs:** None.
* **Outputs:** A system wide Flatpak remote.
* **Why it exists:** Fedora does not enable the full Flathub remote by default.
* **Side effects:** System package and Flatpak configuration changes.

### install_development_tools

* **Does:** Installs the `development-tools` package group.
* **Inputs:** None.
* **Outputs:** Compilers, `make`, and related tools.
* **Why it exists:** Needed to build software and kernel modules.
* **Side effects:** System package changes.

### install_codecs

* **Does:** Swaps `ffmpeg-free` for the full `ffmpeg` build.
* **Inputs:** None.
* **Outputs:** Full ffmpeg codec support.
* **Why it exists:** `ffmpeg-free` leaves out patent limited formats.
* **Side effects:** System package changes. Full `ffmpeg` normally comes from RPM Fusion, which
  is not enabled, so this step is likely to fail on a stock install.

### create_directories

* **Does:** Creates `~/dotfiles`, `~/.local/share/themes`, `~/.local/share/fonts`,
  `~/.local/share/icons`, `~/software`, `~/scripts`, and `~/Pictures/wallpapers`.
* **Inputs:** None.
* **Outputs:** New directories.
* **Why it exists:** The font and wallpaper steps copy into these paths.
* **Side effects:** Directory creation.

### install_font

* **Does:** Downloads the DroidSansMono Nerd Font v3.4.0 zip into `~/fonttmp`, copies the `.otf`
  files into `~/.local/share/fonts`, rebuilds the font cache, returns to the previous directory,
  and removes the temporary folder.
* **Inputs:** A pinned GitHub release URL.
* **Outputs:** Installed user fonts.
* **Why it exists:** The bar, launcher, and terminal use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It uses `cd -`, so later steps still run from the
  repository directory.

### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers/`, or warns if the folder
  is missing.
* **Inputs:** `wallpapers/`, relative to the current directory.
* **Outputs:** Image files.
* **Why it exists:** Makes the wallpapers available to the Sway config.
* **Side effects:** File writes. Copy errors are hidden.

### customize_tiling

* **Does:** Creates config folders for Sway, foot, alacritty, waybar, and rofi, then copies the
  Sway and foot configs into place.
* **Inputs:** `configs/sway/config` and `configs/foot/foot.ini`.
* **Outputs:** Two installed config files and five folders.
* **Why it exists:** Installs the active desktop configuration.
* **Side effects:** Overwrites any existing Sway and foot configs. The rest of the function is
  commented out i3, polybar, and rofi copy lines kept for reference.

### configure_vimrc

* **Does:** Writes a `~/.vimrc` that silences the bell and turns on syntax, line numbers, and
  mouse support.
* **Inputs:** None.
* **Outputs:** `~/.vimrc`.
* **Why it exists:** Gives Vim usable defaults.
* **Side effects:** Overwrites any existing `~/.vimrc`.

### install_vlc_restricted_extras

* **Does:** Installs VLC, `vlc-extras`, the GStreamer plugin sets including ugly and bad nonfree,
  and `ffmpeg`.
* **Inputs:** None.
* **Outputs:** Installed packages.
* **Why it exists:** Adds a media player and full codec support.
* **Side effects:** System package changes. The ugly, nonfree, and full ffmpeg packages need RPM
  Fusion, and the lines that enable it are commented out.

### install_vscode

* **Does:** Imports the Microsoft signing key, writes `/etc/yum.repos.d/vscode.repo` with
  `gpgcheck=1`, and installs `code`.
* **Inputs:** None.
* **Outputs:** VSCode installed from Microsoft's repository.
* **Why it exists:** VSCode is not in the Fedora repositories.
* **Side effects:** Network calls, a repository file, and package changes. The key import runs
  twice, which is harmless.

### install_obs

* **Does:** Calls `enable_flathub`, installs OBS Studio from Flathub, and creates its config
  folder.
* **Inputs:** None.
* **Outputs:** OBS Studio installed as a Flatpak.
* **Why it exists:** The Flathub build is the one maintained by the OBS project.
* **Side effects:** Network calls and a system wide Flatpak install.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory if found, sets global Git
  defaults, and prints the resulting config.
* **Inputs:** `configs/.gitignore_global`, relative to the current directory.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

### install_firewalld_enable

* **Does:** Installs firewalld and its GUI, enables and starts the service, and prints its state,
  default zone, and rules.
* **Inputs:** None.
* **Outputs:** A running host firewall.
* **Why it exists:** Confirms the firewall is active and shows the rules for review.
* **Side effects:** Package and service state changes.

### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A sysctl file and the before and after values on screen.
* **Why it exists:** Keeps the desktop in RAM longer before swapping.
* **Side effects:** System file write. Persists across reboots.

### speed_up_boot_time

* **Does:** Backs up `/etc/default/grub`, changes `GRUB_TIMEOUT=5` to `2`, and regenerates
  `/boot/grub2/grub.cfg`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** A shorter boot menu delay.
* **Why it exists:** Speeds up boot while leaving time to pick a kernel.
* **Side effects:** Boot configuration change. A second run overwrites the backup.

### install_docker

* **Does:** Removes distro Docker packages, adds Docker's official repository, installs Docker CE
  with Buildx and Compose, starts the service, and adds the user to the `docker` group.
* **Inputs:** `$USER`.
* **Outputs:** A running Docker engine.
* **Why it exists:** Distro packages conflict with Docker CE and lag behind upstream.
* **Side effects:** Package, repository, service, and group changes. Membership in `docker` is
  root equivalent on the host. A reboot is needed for the group to apply.

### install_virtualbox

* **Does:** Installs build tools, kernel headers, and DKMS, imports Oracle's signing key, writes
  `/etc/yum.repos.d/virtualbox.repo`, installs VirtualBox 7.1, and adds the user to `vboxusers`.
* **Inputs:** `$USER`.
* **Outputs:** VirtualBox installed.
* **Why it exists:** VirtualBox needs kernel modules built for the running kernel.
* **Side effects:** Package, repository, and group changes. The first two `dnf install` calls lack
  `-y`, so they stop for confirmation.

### install_brave_browsers

* **Does:** Adds the Brave repository and installs the Brave browser.
* **Inputs:** None.
* **Outputs:** Brave installed.
* **Why it exists:** Planned menu step. It is marked with a `TODO(sgt7):` and not called yet.
* **Side effects:** Repository and package changes. Each `dnf` call prompts for confirmation.

## Known limitations or sharp edges

* **Owner's fix list.** `fixed.txt` flags steps 12, 14, 17, and 21 as needing work.
* **Codecs need RPM Fusion.** Steps 8 and 14 install packages that normally come only from RPM
  Fusion, and nothing enables it.
* **VM prep installs the wrong names.** Each line in `fedora-tiling-vm-prep.sh` reads
  `dnf install -y install <name>`, which also asks for a package called `install`. Fedora has no
  `linux-headers` package. The equivalent is `kernel-headers`.
* **VirtualBox repo details.** The repository uses `http://` for `baseurl`. Package and metadata
  signatures are still checked. The `name` line loses `$releasever` and `$basearch` because they
  are not escaped.
* **Mixed dnf versions.** `install_docker` calls `dnf-3 config-manager`, while
  `install_brave_browsers` uses the dnf5 `addrepo` syntax.
* **List file lacks a trailing newline.** `read` skips the last line of `package_install.txt`, so
  `wget` is never installed.
* **Unused helpers.** The volume scripts, rofi configs, and `install_brave_browsers` are not wired
  into the setup.
* **Appends are not idempotent.** `update_dnf` adds duplicate lines on every run.
* **No strict mode.** No script uses `set -euo pipefail`, so failures do not stop a run.
* **Working directory matters.** Data files are read relative to the current directory.
* **No CI.** This repository has no ShellCheck workflow.

## Change log

| Date       | Summary                                                    |
| :--------- | :--------------------------------------------------------- |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed all scripts to kebab-case. |
