# Debian GNOME Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh Debian install with the GNOME desktop into a ready to use workstation. It
updates the system, installs a fixed set of tools, purges the bundled GNOME games, applies desktop
and system tweaks, enables a firewall, installs VSCode, and sets Git defaults.

Everything is driven from an interactive numbered menu. Each menu option runs one step, so a single
step can be rerun on its own. Option 18 runs every step in order.

## How the pieces connect

`debian-gnome-setup.sh` is the only file you run. It finds its own directory, sources
`debian-gnome-functions.sh` to load one Bash function per setup step, then loops on a menu and calls
the matching function for each choice.

The functions talk to the system through `apt-get`, `gsettings`, `ufw`, `sysctl`, `update-grub`,
and `git`. Data comes from files in the repository:

* `package_install.txt` and `package_remove.txt` hold package names, one per line.
* `wallpapers/` holds the desktop wallpaper.
* `configs/.gitignore_global` is the global Git ignore file.

```text
debian-gnome-setup.sh (menu loop)
  └── sources debian-gnome-functions.sh
        ├── apt-get        <-- package_install.txt, package_remove.txt
        ├── cp, gsettings  <-- wallpapers/
        ├── cp, git config <-- configs/.gitignore_global
        └── ufw, sysctl, update-grub
```

## File by file walkthrough

Read the files in this order.

### debian-gnome-setup.sh

**Purpose:** Entry point. Prints the menu, reads a choice, and calls the functions for that step.

**Depends on:** `debian-gnome-functions.sh`.

It resolves its directory with `dirname` and `realpath`, so the functions file is found even when
the script is started from elsewhere. The `case` block maps each number to one or more functions.
Option 1 calls two functions, option 2 calls three, and option 16 calls two, because those steps must run together.

The script runs with `set -euo pipefail` and changes into the repository directory, so the data
files are found wherever it is started from. Every function call goes through `run_step`, so a
failing command stops only that step and the menu keeps running.

### debian-gnome-functions.sh

**Purpose:** Holds one function per setup step. It has no top level code and only defines
functions.

**Depends on:** `sudo`, `apt-get`, `gsettings`, `ufw`, `wget`, `gpg`, `git`, and the data files
listed above.

### package_install.txt and package_remove.txt

**Purpose:** Plain text package lists, one name per line, so the lists change without code edits.

**Depends on:** Nothing.

### configs/.gitignore_global

**Purpose:** Global Git ignore patterns copied into the home directory by the Git step.

**Depends on:** Nothing.

### .github/workflows/shellcheck.yml and .shellcheckrc

**Purpose:** Runs ShellCheck on every push and pull request. It downloads ShellCheck v0.11.0,
checks the archive against a pinned SHA-256, and lints every tracked `.sh` file with `-x`. Any
finding fails the job.

**Depends on:** GitHub Actions and `actions/checkout`, pinned to the commit SHA of v7.0.1.

`.shellcheckrc` disables SC1091, the notice that the sourced functions file was not passed as
input.

## Function entries

### run_step

* **Does:** Runs one step function in a subshell with errexit on, then prints the exit code if the
  step failed.
* **Inputs:** The function name to run.
* **Outputs:** The step's output, plus an error line on failure.
* **Why it exists:** Under `set -e` alone, any failing command would close the whole menu. Bash
  also ignores errexit inside `||` lists, so the helper pauses errexit in the menu shell instead.
* **Side effects:** None of its own. A `cd` or variable change inside a step stays in its subshell.

All other functions live in `debian-gnome-functions.sh` and take no arguments.

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

### update_debian

* **Does:** Refreshes the apt package index and upgrades installed packages.
* **Inputs:** None.
* **Outputs:** Upgraded system packages.
* **Why it exists:** Later installs fail or pull stale versions on an out of date index.
* **Side effects:** Network calls and system package changes through `sudo`.

### install_packages

* **Does:** Installs every package named in `package_install.txt`, one at a time.
* **Inputs:** `package_install.txt`. A package that fails to install is reported and skipped.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the tool list in data instead of code.
* **Side effects:** Network calls and system package changes through `sudo`.

### remove_packages

* **Does:** Purges every package in `package_remove.txt`, then runs `apt-get autoremove`.
* **Inputs:** `package_remove.txt`. A package that fails to purge is reported and skipped.
* **Outputs:** Removed packages and their unused dependencies.
* **Why it exists:** Clears out the GNOME games that ship with the desktop task.
* **Side effects:** System package removal through `sudo`.

### update_firmware

* **Does:** Refreshes the fwupd firmware metadata, lists available updates, and applies them.
* **Inputs:** None.
* **Outputs:** Firmware updates for supported devices. Prints a message when there is nothing to apply.
* **Why it exists:** Firmware updates are a separate channel from apt and are often missed.
* **Side effects:** Network calls and firmware changes through `sudo`. Some updates need a reboot.
  A failed refresh stops the step. A failed `get-updates` or `update` is treated as nothing to do.

### enable_flathub

* **Does:** Installs `flatpak` with apt, then adds the Flathub remote.
* **Inputs:** None.
* **Outputs:** A Flathub remote for `flatpak install`.
* **Why it exists:** Debian does not ship Flatpak or the Flathub remote, unlike Fedora.
* **Side effects:** Package installs and a remote entry in the system Flatpak configuration.

### install_development_tools

* **Does:** Installs `build-essential`, which provides the compiler and `make`.
* **Inputs:** None.
* **Outputs:** Build tools on the PATH.
* **Why it exists:** Some tools and packages need a compiler. This is the Debian counterpart of
  Fedora's development tools group.
* **Side effects:** Package installs through `sudo`.

### create_directories

* **Does:** Creates `~/.themes`, `~/.icons`, `~/software`, `~/scripts`, and
  `~/Pictures/wallpapers` if they are missing.
* **Inputs:** None.
* **Outputs:** New directories in the home directory.
* **Why it exists:** Later steps copy files into these paths.
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

* **Does:** Copies the bundled wallpaper into `~/Pictures/wallpapers`.
* **Inputs:** `wallpapers/Wallpaper-House.com_391811.jpg`.
* **Outputs:** One image file.
* **Why it exists:** `customize_gnome` points GNOME at this copied file.
* **Side effects:** File write. Depends on `create_directories` having run.

### customize_gnome

* **Does:** Sets the light and dark wallpaper keys and adds minimize and maximize buttons.
* **Inputs:** The wallpaper copied by `copy_wallpapers`.
* **Outputs:** Changed GNOME settings for the current user.
* **Why it exists:** GNOME picks the wallpaper key from the active theme, so both must be set.
* **Side effects:** Writes to the user dconf database.

### configure_vimrc

* **Does:** Writes a three line `~/.vimrc` that turns on syntax highlighting, line numbers, and
  mouse support.
* **Inputs:** None.
* **Outputs:** `~/.vimrc`.
* **Why it exists:** Gives Vim usable defaults.
* **Side effects:** Overwrites any existing `~/.vimrc`.

### install_vlc_restricted_extras

* **Does:** Installs VLC, two VLC plugins, and extra codec packages.
* **Inputs:** None.
* **Outputs:** Installed packages.
* **Why it exists:** Debian does not play some common media formats out of the box.
* **Side effects:** Network calls and system package changes through `sudo`.

### install_ufw_enable

* **Does:** Installs UFW, enables it, and prints its status and known application profiles.
* **Inputs:** None.
* **Outputs:** An active host firewall.
* **Why it exists:** Debian ships without an active firewall. UFW denies inbound traffic by default.
* **Side effects:** Changes firewall rules. Inbound services you rely on must be allowed by hand.

### configure_swappiness

* **Does:** Writes `vm.swappiness = 10` to `/etc/sysctl.d/swappiness.conf` and applies it.
* **Inputs:** None.
* **Outputs:** A new sysctl file and the before and after values on screen.
* **Why it exists:** A lower value keeps the desktop in RAM instead of swapping early.
* **Side effects:** System file write through `sudo`. Persists across reboots.

### speed_boot_time

* **Does:** Backs up `/etc/default/grub` to `grub.original`, sets `GRUB_TIMEOUT` from 5 to 0, and
  runs `update-grub`.
* **Inputs:** `/etc/default/grub`.
* **Outputs:** A faster boot with no GRUB menu delay.
* **Why it exists:** Removes the five second wait on single boot machines.
* **Side effects:** Rewrites the boot configuration. The backup is only made once, so it always
  holds the original file.

### install_numix_theme

* **Does:** Installs the Numix GTK theme and Numix Circle icons, then selects them.
* **Inputs:** None.
* **Outputs:** Installed packages and changed GNOME interface settings.
* **Why it exists:** Applies the project's chosen look.
* **Side effects:** System package changes and user dconf writes.

### prep_for_vscode_install

* **Does:** Downloads the Microsoft signing key, installs it under `/etc/apt/keyrings`, and adds
  the VSCode apt repository.
* **Inputs:** None.
* **Outputs:** A keyring file and `/etc/apt/sources.list.d/vscode.list`.
* **Why it exists:** VSCode is not in the Debian archive. The key lets apt verify its packages.
* **Side effects:** Network call, system file writes, and a temporary key file in the current
  directory that is deleted afterwards.

### install_vscode

* **Does:** Refreshes apt and installs the `code` package.
* **Inputs:** The repository added by `prep_for_vscode_install`.
* **Outputs:** VSCode installed.
* **Why it exists:** Second half of the VSCode step. It only works after the repository is added.
* **Side effects:** Network calls and system package changes.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory and sets global Git defaults
  for branch name, color, editor, pull behavior, and the excludes file.
* **Inputs:** `configs/.gitignore_global`.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user to set.

## Known limitations or sharp edges

* **Failures stop a step, not the run.** In option 18 a failed step prints an error and the next
  step still runs. Scroll back to check for `failed with exit code` lines.
* **List lines are taken literally.** Package lists have no comment syntax, and a line with
  trailing spaces is passed to apt with the spaces.
* **GRUB edit is narrow.** `speed_boot_time` only matches `GRUB_TIMEOUT=5`. Any other value is left
  alone.
* **Overwrites without asking.** `configure_vimrc` replaces `~/.vimrc` and `configure_git` replaces
  `~/.gitignore_global`.
* **Manual steps remain.** The README lists GNOME extensions and shortcuts that are still done by
  hand.

## Change log

| Date       | Summary                                                                                                   |
| :--------- | :-------------------------------------------------------------------------------------------------------- |
| 2026-11-08 | Added firmware updates through fwupd, Flathub, and a development tools step to match Fedora. |
| 2026-11-08 | Added the Nerd Font step with a checksum check, and added unzip to the package list. |
| 2026-11-08 | Added a backup step and a `.ssh` directory step with `700` permissions to the Debian GNOME setup. |
| 2026-11-01 | Replaced the ShellCheck workflow with a pinned, checksum verified release and checkout SHA.               |
| 2026-11-01 | Added strict mode with per step error handling and fixed the package lists, GRUB backup, and apt prompts. |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed scripts and `wallpapers/` to kebab-case.                                  |
