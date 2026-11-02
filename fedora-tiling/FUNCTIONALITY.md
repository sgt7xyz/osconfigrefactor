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
and option 22 runs every step in order and then lists any that failed. Steps 1 to 14 match
debian-tiling number for number. After each choice the script waits for Enter.

## How the pieces connect

`fedora-tiling-setup.sh` is the file you run. It finds its own directory, sources
`fedora-tiling-functions.sh` to load one function per step, then loops on the menu.

```text
fedora-tiling-setup.sh (menu loop)
  ├── sources common-functions.sh   (menu engine and shared steps)
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

**Purpose:** Entry point. Holds the ordered list of menu entries and the menu loop that runs them.

**Depends on:** `common-functions.sh`, then `fedora-tiling-functions.sh`.

It resolves its own directory with `dirname` and `realpath`. The `menu` array is the single place
that sets step order, numbers, and labels. Option 3 runs the install and remove functions
together. The file ends with `TODO(sgt7):` notes for Chrome and mise-en-place steps.

The script runs with `set -euo pipefail` and changes into the repository directory, so the data
files are found wherever it is started from. Every function call goes through `run_step`, so a
failing command stops only that step and the menu keeps running.

### common-functions.sh

**Purpose:** The menu engine (`run_step`, `run_entry`, `run_menu`) and every step that works the
same on Debian and Fedora: backups, directories, the font, wallpapers, Vim, Git, swappiness, and
the `apply_package_list` and `install_config` helpers. It defines functions only.

**Depends on:** `curl`, `unzip`, `sha256sum`, `fc-cache`, `git`, and `sudo`.

This file is kept byte for byte identical with the copy in debian-tiling. Change both together, and
check them from the folder that holds both repositories with
`diff debian-tiling/common-functions.sh fedora-tiling/common-functions.sh`.

### fedora-tiling-functions.sh

**Purpose:** Holds one function per setup step, plus helpers such as `enable_rpmfusion` and
`install_codecs` that other steps call.

**Depends on:** `sudo`, `dnf`, `rpm`, `flatpak`, `fwupdmgr`, `curl`, `wget`, `unzip`,
`fc-cache`, `firewall-cmd`, `git`, and the data files in the repository.

### fedora-tiling-vm-prep.sh

**Purpose:** Upgrades the system and installs `dkms`, `kernel-headers`, and `kernel-devel`. It
runs with `set -euo pipefail`.

**Depends on:** `dnf`. Meant only for a VirtualBox test VM.

### package_install.txt and package_remove.txt

**Purpose:** Package lists, one name per line. The install list covers command line tools, Neovim,
rofi for Wayland, display tools, the GNOME keyring, and the packages behind the default Sway
wallpaper. The remove list holds `aisleriot`.

**Depends on:** Nothing.

### configs/

**Purpose:** Desktop configuration files.

* `sway/config` is the Sway config. It sets keys and outputs, exports the Wayland environment to
  systemd, and starts the GNOME keyring daemon for secrets and SSH keys. The laptop panel `eDP-1`
  turns off only while the lid is closed.
* `foot/foot.ini` is the terminal config.
* `rofi/` holds the launcher config and its Catppuccin Macchiato theme, set to open `foot`.
* `waybar/` is an empty placeholder kept with a `.keep` file.
* `.gitignore_global` holds global Git ignore patterns.

**Depends on:** The packages from `package_install.txt`.

### scripts/

**Purpose:** `volume-up.sh` and `volume-down.sh` change the default audio sink by 5 percent with
`wpctl`, capped at 150 percent. Both run with `set -euo pipefail`.

**Depends on:** `wpctl` from WirePlumber. The tiling step copies them to `~/scripts`, but no key
binding calls them yet.

### fixed.txt

**Purpose:** The owner's scratch list of menu steps that still need work: 12, 14, 17, and 21.

**Depends on:** Nothing.

### .github/workflows/shellcheck.yml

**Purpose:** Runs ShellCheck on every push and pull request. It downloads ShellCheck v0.11.0,
checks the archive against a pinned SHA-256, and lints every tracked `.sh` file with `-x`. Any
finding fails the job.

**Depends on:** GitHub Actions and `actions/checkout`, pinned to the commit SHA of v7.0.1.

## Function entries

Step functions take no arguments. They are listed in menu order, after the helpers they use.

### Shared functions in common-functions.sh

These entries describe `common-functions.sh`, which is identical in both tiling repositories.

#### run_step

* **Does:** Runs one step function in a subshell with errexit on, then prints the exit code if the
  step failed.
* **Inputs:** The function name to run.
* **Outputs:** The step's output, plus an error line on failure.
* **Why it exists:** Under `set -e` alone, any failing command would close the whole menu. Bash
  also ignores errexit inside `||` lists, so the helper pauses errexit in the menu shell instead.
* **Side effects:** Adds the name of a failed step to `failed_steps`. A `cd` or variable change
  inside a step stays in its subshell.

#### run_entry

* **Does:** Splits one menu entry into its function names and runs each through `run_step`.
* **Inputs:** A space separated list of function names.
* **Outputs:** The output of each step.
* **Why it exists:** Lets one menu option run several functions, such as install and remove.
* **Side effects:** Those of the steps it runs.

#### run_menu

* **Does:** Prints a grouped, numbered menu built from the entries it is given, reads a choice, and
  runs that entry. The number after the last step runs every entry in order and then lists any
  failed steps. `0` or end of input exits, and anything else is rejected.
* **Inputs:** A title, then entries that are either a section title starting with `#` and a space,
  or `function [function...]|Label`.
* **Outputs:** The menu and the output of the chosen steps.
* **Why it exists:** The numbers, the menu text, and Execute all come from one list, so they cannot
  drift apart. Each repository's list keeps steps 1 to 14 the same as the other's.
* **Side effects:** Reads from the terminal. Input such as `08` is read as decimal.

#### apply_package_list

* **Does:** Runs a package command, such as `apt-get install` or
  `dnf install`, once per name in a list file.
* **Inputs:** The list file, then the command to run. Blank lines and `#` comments are skipped.
* **Outputs:** A list of every package that failed, and a non-zero return if any did.
* **Why it exists:** One bad name should not stop the rest, but it must not be lost in the scroll
  either. The list is read on its own file descriptor so the package tool cannot consume
  it from stdin.
* **Side effects:** Whatever the command does.

#### install_config

* **Does:** Copies one file into place, creating its folder. If a different file is already there,
  it is first copied to `~/.config-backups` under the same relative path with a timestamp.
* **Inputs:** A source path in the repository and a target path in the home directory.
* **Outputs:** The installed file, plus a backup when one was needed.
* **Why it exists:** Rerunning the tiling step must not silently destroy a hand edited config.
* **Side effects:** File writes.

#### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.profile`, `~/.bash_profile`, and `~/.bash_logout` into
  `~/.config-backups`.
* **Inputs:** Those files. Debian normally has `~/.profile` and Fedora `~/.bash_profile`.
* **Outputs:** A backup directory, with a note for each file that is missing.
* **Why it exists:** Keeps the stock dotfiles in case `stow` or a later step replaces them.
* **Side effects:** File writes. Safe to rerun, but it overwrites the earlier backups.

#### create_directories

* **Does:** Creates `~/.config`, `~/dotfiles`, `~/.local/share/themes`, `~/.local/share/fonts`,
  `~/.local/share/icons`, `~/software`, `~/scripts`, and `~/Pictures/wallpapers`.
* **Inputs:** None.
* **Outputs:** New directories.
* **Why it exists:** The font, wallpaper, and tiling steps copy into these paths.
* **Side effects:** Directory creation.

#### install_font

* **Does:** Downloads the DroidSansMono Nerd Font v3.4.0 zip into `~/fonttmp`, checks its
  SHA-256, copies the `.otf` files into `~/.local/share/fonts`, rebuilds the font cache, and removes
  the temporary folder.
* **Inputs:** A pinned GitHub release URL and the checksum published with that release.
* **Outputs:** Installed user fonts.
* **Why it exists:** The bar, launcher, and terminal use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It works with full paths and never changes the
  working directory.

#### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers/`, or fails the step if
  the folder is missing.
* **Inputs:** `wallpapers/`.
* **Outputs:** Image files.
* **Why it exists:** The window manager config sets the wallpaper from this folder.
* **Side effects:** File writes.

#### configure_vimrc

* **Does:** Writes a `~/.vimrc` that silences the bell and turns on syntax, line numbers, and
  mouse support.
* **Inputs:** None.
* **Outputs:** `~/.vimrc`.
* **Why it exists:** Gives Vim usable defaults.
* **Side effects:** Overwrites any existing `~/.vimrc`.

#### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory if found, sets global Git
  defaults, and prints the resulting config.
* **Inputs:** `configs/.gitignore_global`.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

#### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A sysctl file and the before and after values on screen.
* **Why it exists:** Keeps the desktop in RAM longer before swapping.
* **Side effects:** System file write. Persists across reboots.

### Fedora functions in fedora-tiling-functions.sh

#### configure_dnf

* **Does:** Backs up `/etc/dnf/dnf.conf` to `dnf.original` once, then adds the parallel download
  and fastest mirror settings if they are not already there.
* **Inputs:** None.
* **Outputs:** A changed dnf config.
* **Why it exists:** Shortens every later dnf step. `update_system` runs it first.
* **Side effects:** System file writes. Safe to rerun.

#### update_system

* **Does:** Runs `configure_dnf`, then `dnf upgrade`.
* **Inputs:** None.
* **Outputs:** A faster dnf config and upgraded packages.
* **Why it exists:** Later installs need a current system.
* **Side effects:** System file writes, network calls, and system package changes.

#### install_packages and remove_packages

* **Does:** Installs each package in `package_install.txt`, then removes each package in
  `package_remove.txt` and runs `dnf autoremove`, both through `apply_package_list`.
* **Inputs:** The two list files. A missing list or a failed package fails the step.
* **Outputs:** Installed and removed packages.
* **Why it exists:** Keeps the package lists in data instead of code.
* **Side effects:** Network calls and system package changes.

#### customize_tiling

* **Does:** Installs the Sway, foot, and rofi configs, the rofi theme, and the two volume helpers
  through `install_config`.
* **Inputs:** `configs/sway/`, `configs/foot/`, `configs/rofi/`, and `scripts/`.
* **Outputs:** Six installed files.
* **Why it exists:** Installs the active desktop configuration.
* **Side effects:** File writes, with backups of changed files. There is no waybar config yet, so
  Sway keeps the bar from Fedora's own `/usr/share/sway/config.d` files.

#### enable_rpmfusion

* **Does:** Installs the RPM Fusion free and nonfree release packages for the running Fedora
  version, skipping any that are already installed.
* **Inputs:** The Fedora version from `rpm -E %fedora`.
* **Outputs:** Two enabled repositories with their signing keys and `gpgcheck` on.
* **Why it exists:** Full `ffmpeg` and the restricted GStreamer plugins are only in RPM Fusion.
  It is called by the codec and VLC steps rather than having its own menu option.
* **Side effects:** Network calls and new repository files under `/etc/yum.repos.d`.

#### install_codecs

* **Does:** Enables RPM Fusion, then swaps `ffmpeg-free` for the full `ffmpeg` build.
* **Inputs:** None.
* **Outputs:** Full ffmpeg codec support.
* **Why it exists:** `ffmpeg-free` leaves out patent limited formats. It has no menu option of its
  own, because `install_vlc` calls it.
* **Side effects:** System package changes. Safe to rerun.

#### install_vlc

* **Does:** Runs `install_codecs`, then installs VLC with the RPM Fusion `vlc-plugins-freeworld`
  codecs and the GStreamer plugin sets, including ugly, bad freeworld, and libav.
* **Inputs:** None.
* **Outputs:** Installed packages.
* **Why it exists:** Adds a media player and full codec support.
* **Side effects:** System package changes and RPM Fusion repositories.

#### install_vscode

* **Does:** Imports the Microsoft signing key, writes `/etc/yum.repos.d/vscode.repo` with
  `gpgcheck=1`, refreshes metadata with `dnf makecache`, and installs `code`.
* **Inputs:** None.
* **Outputs:** VSCode installed from Microsoft's repository.
* **Why it exists:** VSCode is not in the Fedora repositories.
* **Side effects:** Network calls, a repository file, and package changes.

#### configure_firewall

* **Does:** Installs firewalld and its GUI, starts it, strips every service and port from the
  `public` zone except `dhcpv6-client`, makes `public` the default zone, and prints the result.
* **Inputs:** None.
* **Outputs:** A running stateful firewall. Nothing can connect in, and replies to connections the
  host started are let back in.
* **Why it exists:** Fedora desktops can default to the `FedoraWorkstation` zone, which accepts
  every port from 1025 to 65535, and even `public` allows `ssh` and `mdns`. A workstation that
  offers no services needs neither.
* **Side effects:** Firewall configuration changes. Local network discovery over mDNS stops
  working. A NetworkManager connection with its own zone set keeps that zone.

#### configure_boot_time

* **Does:** Backs up `/etc/default/grub`, sets `GRUB_TIMEOUT` to `2` whatever its old value, and
  regenerates `/boot/grub2/grub.cfg`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** A shorter boot menu delay.
* **Why it exists:** Speeds up boot while leaving time to pick a kernel.
* **Side effects:** Boot configuration change. The backup is only made once.

#### update_firmware

* **Does:** Forces a refresh of LVFS firmware metadata, lists updates, and applies them.
* **Inputs:** None.
* **Outputs:** Updated device firmware where supported.
* **Why it exists:** A stale metadata cache hides available firmware updates.
* **Side effects:** Network calls and firmware writes. May ask for confirmation or a reboot.
  `fwupdmgr` exits with 2 when there is nothing to do, so a non-zero exit there only prints a
  message.

#### enable_flathub

* **Does:** Installs Flatpak and adds the Flathub remote if missing.
* **Inputs:** None.
* **Outputs:** A system wide Flatpak remote.
* **Why it exists:** Fedora does not enable the full Flathub remote by default.
* **Side effects:** System package and Flatpak configuration changes.

#### install_development_tools

* **Does:** Installs the `development-tools` package group.
* **Inputs:** None.
* **Outputs:** Compilers, `make`, and related tools.
* **Why it exists:** Needed to build software and kernel modules.
* **Side effects:** System package changes.

#### install_obs

* **Does:** Calls `enable_flathub`, installs OBS Studio from Flathub, and creates its config
  folder.
* **Inputs:** None.
* **Outputs:** OBS Studio installed as a Flatpak.
* **Why it exists:** The Flathub build is the one maintained by the OBS project.
* **Side effects:** Network calls and a system wide Flatpak install.

#### install_docker

* **Does:** Removes any distro Docker packages, adds Docker's official repository with the dnf5
  `config-manager addrepo` command, installs Docker CE
  with Buildx and Compose, starts the service, and adds the user to the `docker` group.
* **Inputs:** `$USER`.
* **Outputs:** A running Docker engine.
* **Why it exists:** Distro packages conflict with Docker CE and lag behind upstream.
* **Side effects:** Package, repository, service, and group changes. Membership in `docker` is
  root equivalent on the host. A reboot is needed for the group to apply.

#### install_virtualbox

* **Does:** Calls `install_development_tools`, installs kernel headers and DKMS, imports Oracle's
  signing key, writes `/etc/yum.repos.d/virtualbox.repo` with an HTTPS `baseurl`, installs
  VirtualBox 7.2, and adds the user to `vboxusers`.
* **Inputs:** `$USER`.
* **Outputs:** VirtualBox installed.
* **Why it exists:** VirtualBox needs kernel modules built for the running kernel.
* **Side effects:** Package, repository, and group changes.

#### install_brave

* **Does:** Adds the Brave repository and installs the Brave browser.
* **Inputs:** None.
* **Outputs:** Brave installed.
* **Why it exists:** Brave is not in the Fedora repositories. The repository file turns on
  `gpgcheck` with Brave's signing key.
* **Side effects:** Repository and package changes. `--overwrite` makes a rerun safe.

## Known limitations or sharp edges

* **Owner's fix list.** `fixed.txt` flags steps 12, 14, 17, and 21 as needing work. Those numbers
  are from the old menu. They are now steps 7 (tiling), 10 (VLC), 9 (Git), and 19 (Docker).
* **Failures stop a step, not the run.** In option 22 a failed step prints an error and the next
  step still runs. The failed steps are listed again at the end.
* **dnf5 only.** `install_docker` and `install_brave` use the dnf5 `addrepo` syntax, which
  matches the Fedora 41 or newer requirement in the README.
* **Unused helpers.** No key binding calls the volume scripts.

## Change log

| Date       | Summary                                                                                                               |
| :--------- | :-------------------------------------------------------------------------------------------------------------------- |
| 2026-11-02 | Moved the VirtualBox install from 7.1 to 7.2 (7.2.22 is the current release).                                         |
| 2026-11-01 | Renamed steps to match debian-tiling, such as configure_firewall and configure_boot_time, and ordered them by menu.   |
| 2026-11-01 | Moved the menu engine and shared steps into common-functions.sh, identical in both tiling repos.                      |
| 2026-11-01 | Built the menu from one ordered list, matched steps 1 to 14 with debian-tiling, merged codecs into VLC, added Brave.  |
| 2026-11-01 | Set GRUB to 2 seconds from any old value and added the packages the default Sway wallpaper needs.                     |
| 2026-11-01 | Enabled RPM Fusion for codecs and VLC, fixed package names, installed rofi, and fixed the laptop panel.               |
| 2026-11-01 | Locked firewalld to deny all inbound, verified the font checksum, and listed failed packages at the end.              |
| 2026-11-01 | Added a ShellCheck workflow with a pinned, checksum verified release and checkout SHA.                                |
| 2026-11-01 | Added strict mode with per step error handling and fixed the VM prep, Docker repo, VirtualBox repo, and dnf settings. |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed all scripts to kebab-case.                                                            |
