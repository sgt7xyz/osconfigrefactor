# Debian Tiling Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a minimal Debian install into a keyboard driven desktop built on the i3 tiling
window manager. It installs Xorg, i3, polybar, rofi, alacritty, picom, and a set of developer
tools, then applies fonts, wallpapers, terminal and Vim settings, a firewall, kernel and boot
tweaks, VSCode, and Git defaults.

Everything is driven from an interactive menu grouped into five sections. Each option runs one
step, so a single step can be rerun on its own. Option 16 runs every step in order and then lists
any that failed. Steps 1 to 14 match fedora-tiling number for number.

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
        ├── cp               <-- wallpapers/, configs/, scripts/volume-*.sh
        ├── cp, git config   <-- configs/.gitignore_global
        └── ufw, sysctl, update-grub, dpkg-reconfigure

configs/i3config ──exec──> picom, feh (wallpaper), polybar/launch.sh
                 (installed to ~/.config/i3/config by the tiling step)
```

`debian-tiling-vm-prep.sh` is separate. Run it first inside a VirtualBox VM so Guest Additions can
build.

## File by file walkthrough

Read the files in this order.

### debian-tiling-setup.sh

**Purpose:** Entry point. Holds the ordered list of menu entries and the menu loop that runs them.

**Depends on:** `debian-tiling-functions.sh`.

It resolves its own directory with `dirname` and `realpath` so the functions file is always found.
The `menu` array is the single place that sets step order, numbers, and labels. Option 3 runs the
install and remove functions together, and option 11 runs both VSCode functions.

The script runs with `set -euo pipefail` and changes into the repository directory, so the data
files are found wherever it is started from. Every function call goes through `run_step`, so a
failing command stops only that step and the menu keeps running.

### debian-tiling-functions.sh

**Purpose:** Holds one function per setup step. It defines functions only and has no top level
code.

**Depends on:** `sudo`, `apt-get`, `curl`, `unzip`, `wget`, `gpg`, `ufw`, `git`, and the data
files in the repository.

### debian-tiling-vm-prep.sh

**Purpose:** Updates the system and installs `dkms` plus kernel headers for the running kernel.
It runs with `set -euo pipefail`.

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
`/tmp/polybar1.log`. It runs in strict mode, so the stop command is allowed to fail when no bar is
running yet.

**Depends on:** `enable-ipc` in the polybar config. Called by `exec_always` in `i3config`.

### scripts/

**Purpose:** Small helpers for daily use.

* `volume-up.sh` and `volume-down.sh` change the default audio sink by 5 percent with `wpctl`,
  capped at 150 percent.
* `system-update.sh` runs `apt-get update` and `apt-get upgrade`.

Each helper runs with `set -euo pipefail`, so it stops at the first failed command.

**Depends on:** `wpctl` from WirePlumber, and `apt-get`.

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
* **Side effects:** Adds the name of a failed step to `failed_steps`. A `cd` or variable change
  inside a step stays in its subshell.

### run_entry

* **Does:** Splits one menu entry into its function names and runs each through `run_step`.
* **Inputs:** A space separated list of function names.
* **Outputs:** The output of each step.
* **Why it exists:** Lets one menu option run several functions, such as install and remove.
* **Side effects:** Those of the steps it runs.

### run_menu

* **Does:** Prints a grouped, numbered menu built from the entries it is given, reads a choice, and
  runs that entry. The number after the last step runs every entry in order and then lists any
  failed steps. `0` or end of input exits, and anything else is rejected.
* **Inputs:** A title, then entries that are either a section title starting with `#` and a space,
  or `function [function...]|Label`.
* **Outputs:** The menu and the output of the chosen steps.
* **Why it exists:** The numbers, the menu text, and Execute all come from one list, so they cannot
  drift apart. The list keeps steps 1 to 14 identical to fedora-tiling.
* **Side effects:** Reads from the terminal. Input such as `08` is read as decimal.

All other functions live in `debian-tiling-functions.sh` and take no arguments.

### backup_configs

* **Does:** Copies `~/.bashrc`, `~/.profile`, and `~/.bash_logout` into `~/.config-backups`.
* **Inputs:** Those three files.
* **Outputs:** A backup directory, with a warning for each file that is missing.
* **Why it exists:** Keeps the stock dotfiles in case `stow` or a later step replaces them.
* **Side effects:** File writes. Safe to rerun, but it overwrites the earlier backups.

### update_debian

* **Does:** Refreshes the apt index and upgrades installed packages.
* **Inputs:** None.
* **Outputs:** Upgraded packages.
* **Why it exists:** Later installs need a current index.
* **Side effects:** Network calls and system package changes through `sudo`.

### apply_package_list

* **Does:** Runs a package command, such as `apt-get install`, once per name in a list file.
* **Inputs:** The list file, then the command to run. Blank lines and `#` comments are skipped.
* **Outputs:** A list of every package that failed, and a non-zero return if any did.
* **Why it exists:** One bad name should not stop the rest, but it must not be lost in the scroll
  either. The list is read on its own file descriptor so `apt-get` cannot consume it from stdin.
* **Side effects:** Whatever the command does.

### install_packages

* **Does:** Installs each package in `package_install.txt` through `apply_package_list`.
* **Inputs:** `package_install.txt`. Failed packages are listed at the end and fail the step.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the package list in data instead of code.
* **Side effects:** Network calls and system package changes through `sudo`.

### remove_packages

* **Does:** Purges each package in `package_remove.txt`, then runs `apt-get autoremove`.
* **Inputs:** `package_remove.txt`. Failed packages are listed at the end and fail the step.
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

* **Does:** Downloads the DroidSansMono Nerd Font v3.4.0 zip, checks its SHA-256, unpacks it in
  `~/fonttmp`, copies the `.otf` files into `~/.local/share/fonts`, rebuilds the font cache, and
  removes the temporary directory.
* **Inputs:** A pinned GitHub release URL and the checksum published with that release.
* **Outputs:** Installed user fonts.
* **Why it exists:** Polybar and the terminal theme use Nerd Font glyphs.
* **Side effects:** Network call and file writes. It works with full paths and never changes the
  working directory.

### configure_console

* **Does:** Runs `dpkg-reconfigure console-setup`.
* **Inputs:** Answers typed into the interactive dialog.
* **Outputs:** A new console font and size.
* **Why it exists:** Makes the text console readable on high resolution screens.
* **Side effects:** System configuration change. Stops for user input.

### copy_wallpapers

* **Does:** Copies every file in `wallpapers/` to `~/Pictures/wallpapers/`.
* **Inputs:** `wallpapers/`.
* **Outputs:** Image files.
* **Why it exists:** `i3config` sets the wallpaper from this folder with feh.
* **Side effects:** File writes.

### install_config

* **Does:** Copies one file into place, creating its folder. If a different file is already there,
  it is first copied to `~/.config-backups` under the same relative path with a timestamp.
* **Inputs:** A source path in the repository and a target path in the home directory.
* **Outputs:** The installed file, plus a backup when one was needed.
* **Why it exists:** Rerunning the tiling step must not silently destroy a hand edited config.
* **Side effects:** File writes.

### customize_tiling

* **Does:** Installs the i3, polybar, rofi, picom, and alacritty configs and the two volume helpers
  through `install_config`, and makes the polybar launcher executable.
* **Inputs:** Files under `configs/` and `scripts/`.
* **Outputs:** Thirteen installed files under `~/.config` and `~/scripts`.
* **Why it exists:** Installs the whole desktop configuration in one step.
* **Side effects:** File writes, with backups of changed files. Alacritty gets both the TOML files
  for 0.13 and newer and the YAML files for older releases. `.Xresources`, `.xsessionrc`, and
  `xorg.conf.new` are tuned for one monitor setup and are not installed.

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

* **Does:** Installs UFW, deletes its stock mDNS and UPnP accept rules, sets incoming to deny and
  outgoing to allow, enables it without a prompt, and prints the status.
* **Inputs:** `/etc/ufw/before.rules` and `/etc/ufw/before6.rules`, each backed up once to
  `.original`.
* **Outputs:** An active stateful firewall. Nothing can connect in, and replies to connections the
  host started are let back in.
* **Why it exists:** Debian ships without an active firewall, and a workstation offers no services.
* **Side effects:** Firewall rule changes. Local network discovery, such as finding printers or
  `.local` names over mDNS, stops working.

### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A sysctl file and the before and after values on screen.
* **Why it exists:** Keeps the desktop in RAM longer before swapping.
* **Side effects:** System file write. Persists across reboots.

### speed_boot_time

* **Does:** Backs up `/etc/default/grub`, sets `GRUB_TIMEOUT` to `2` whatever its old value, and
  runs `update-grub`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** A two second GRUB menu delay.
* **Why it exists:** Speeds up boot while leaving time to pick an older kernel or recovery mode.
* **Side effects:** Boot configuration change. The backup is only made once.

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
* **Inputs:** `configs/.gitignore_global`.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

## Known limitations or sharp edges

* **Failures stop a step, not the run.** In option 16 a failed step prints an error and the next
  step still runs. The failed steps are listed again at the end.
* **X settings are not installed.** `.Xresources`, `.xsessionrc`, and `xorg.conf.new` must be
  copied by hand, because they hold one specific monitor layout.
* **Debian 12 lacks fastfetch.** On Debian 12 the package step lists `fastfetch` as failed, because
  it is only in the Debian 13 archive.
* **Mixed audio tools.** The volume scripts use `wpctl`, but the media key bindings in `i3config`
  use `pactl`.
* **Unused helper.** `scripts/system-update.sh` is not copied anywhere by the setup script.

## Change log

| Date       | Summary                                                                                                    |
| :--------- | :--------------------------------------------------------------------------------------------------------- |
| 2026-11-01 | Built the menu from one ordered list, matched steps 1 to 14 with fedora-tiling, and listed failed steps.   |
| 2026-11-01 | Installed all desktop configs, fixed the menu numbering, package names, typos, and a 2 second GRUB delay.  |
| 2026-11-01 | Locked UFW to deny all inbound, verified the font checksum, and listed failed packages at the end.         |
| 2026-11-01 | Added a ShellCheck workflow with a pinned, checksum verified release and checkout SHA.                     |
| 2026-11-01 | Added strict mode with per step error handling and fixed the font step, alacritty folder, and GRUB backup. |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed all scripts to kebab-case.                                                 |
