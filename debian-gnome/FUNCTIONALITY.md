# Debian GNOME Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh Debian install with the GNOME desktop into a ready to use workstation. It
updates the system, installs a fixed set of tools, purges the bundled GNOME games, applies desktop
and system tweaks, enables a firewall, installs VSCode, and sets Git defaults.

Everything is driven from an interactive numbered menu. Each menu option runs one step, so a single
step can be rerun on its own. Option 13 runs every step in order.

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
Option 1 calls three functions and option 11 calls two, because those steps must run together.

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

**Purpose:** Run ShellCheck on every push and pull request. `.shellcheckrc` disables SC1091, the
notice that the sourced functions file was not passed as input.

**Depends on:** GitHub Actions and the CICDToolbox ShellCheck pipeline script.

## Function entries

All functions live in `debian-gnome-functions.sh` and take no arguments.

### update_debian

* **Does:** Refreshes the apt package index and upgrades installed packages.
* **Inputs:** None.
* **Outputs:** Upgraded system packages.
* **Why it exists:** Later installs fail or pull stale versions on an out of date index.
* **Side effects:** Network calls and system package changes through `sudo`.

### install_packages

* **Does:** Installs every package named in `package_install.txt`, one at a time.
* **Inputs:** `package_install.txt`, read from the current working directory.
* **Outputs:** Installed packages.
* **Why it exists:** Keeps the tool list in data instead of code.
* **Side effects:** Network calls and system package changes through `sudo`.

### remove_packages

* **Does:** Purges every package in `package_remove.txt`, then runs `apt-get autoremove`.
* **Inputs:** `package_remove.txt`, read from the current working directory.
* **Outputs:** Removed packages and their unused dependencies.
* **Why it exists:** Clears out the GNOME games that ship with the desktop task.
* **Side effects:** System package removal through `sudo`.

### create_directories

* **Does:** Creates `~/.themes`, `~/.icons`, `~/software`, `~/scripts`, and
  `~/Pictures/wallpapers` if they are missing.
* **Inputs:** None.
* **Outputs:** New directories in the home directory.
* **Why it exists:** Later steps copy files into these paths.
* **Side effects:** Directory creation.

### copy_wallpapers

* **Does:** Copies the bundled wallpaper into `~/Pictures/wallpapers`.
* **Inputs:** `wallpapers/Wallpaper-House.com_391811.jpg`, relative to the current directory.
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
* **Side effects:** Rewrites the boot configuration. Running it twice overwrites the backup with
  the already edited file.

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
* **Side effects:** Network calls and system package changes. The final install prompts for
  confirmation because it lacks `-y`.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory and sets global Git defaults
  for branch name, color, editor, pull behavior, and the excludes file.
* **Inputs:** `configs/.gitignore_global`, relative to the current directory.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user to set.

## Known limitations or sharp edges

* **Working directory matters.** The setup script finds its own directory, but the functions read
  `package_install.txt`, `package_remove.txt`, `wallpapers/`, and `configs/` relative to the
  current directory. Run the script from the repository directory.
* **No strict mode.** Neither script uses `set -euo pipefail`, so a failed step does not stop the
  run. Option 13 keeps going after an error.
* **Last line of a list.** `read` skips a final line with no trailing newline. Both list files
  currently lack one, so `wget` is never installed and `tali` is never purged.
* **Trailing spaces in the remove list.** Every line of `package_remove.txt` ends in spaces, which
  `IFS=` keeps, so apt is likely to reject each name as unknown.
* **GRUB edit is narrow.** `speed_boot_time` only matches `GRUB_TIMEOUT=5`. Any other value is left
  alone, and a second run replaces the backup with the edited file.
* **Overwrites without asking.** `configure_vimrc` replaces `~/.vimrc` and `configure_git` replaces
  `~/.gitignore_global`.
* **Prompts mid run.** `prep_for_vscode_install` and `install_vscode` call `apt-get install`
  without `-y`, so option 13 stops for confirmation.
* **CI fetches a remote script.** The ShellCheck workflow pipes a script from GitHub into Bash at
  run time, so the check depends on that external file.
* **Manual steps remain.** The README lists GNOME extensions and shortcuts that are still done by
  hand.

## Change log

| Date       | Summary                                                                  |
| :--------- | :----------------------------------------------------------------------- |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed scripts and `wallpapers/` to kebab-case. |
