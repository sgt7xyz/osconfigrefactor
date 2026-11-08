# Fedora GNOME Setup

Menu-driven Bash scripts that automate the post-install setup of a Fedora Workstation running
GNOME.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Fedora logo](images/fedora.png) ![GNOME logo](images/gnome.png)

## Overview

This repository automates as much as possible of a fresh Fedora GNOME install: faster DNF,
upgrades, firmware, Flathub, codecs, fonts, desktop tweaks, VSCode, firewalld, and Git defaults.
Steps that cannot be scripted yet are listed under [Manual steps](#manual-steps). Fork it and
adjust the package lists and settings to your taste.

## Architecture

`fedora-gnome-setup.sh` shows a grouped, numbered menu and calls functions from
`fedora-gnome-functions.sh`. Package lists are plain text files read at run time.

```text
fedora-gnome-setup.sh --> fedora-gnome-functions.sh --> dnf, flatpak, fwupdmgr, gsettings, firewalld, git
                                    |
                                    +--> package_install.txt, package_remove.txt, wallpapers/, configs/
```

## Prerequisites

| Requirement                | Version        |
| :------------------------- | :------------- |
| Fedora Workstation (GNOME) | 41 or newer    |
| Bash                       | 5.0 or newer   |
| A user with `sudo` rights  | Not applicable |
| Internet access            | Not applicable |

## Quick start

1. Clone this repository to your home directory.

   ```bash
   cd ~
   git clone git@github.com:sgt7xyz/fedora-gnome-sgt7.git
   cd fedora-gnome-sgt7
   ```

1. Run the setup script from the repository directory.

   ```bash
   chmod 700 fedora-gnome-setup.sh
   ./fedora-gnome-setup.sh
   ```

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File                        | Description                                  | Default                        |
| :-------------------------- | :------------------------------------------- | :----------------------------- |
| `package_install.txt`       | Packages to install, one per line            | GNOME Tweaks, Tilix, Vim, nmap |
| `package_remove.txt`        | Packages to remove, one per line             | `tali`                         |
| `wallpapers/`               | Wallpapers copied to `~/Pictures/wallpapers` | Eleven wallpapers              |
| `configs/.gitignore_global` | Global Git ignore file copied to `~/`        | Common OS and editor files     |

## Usage

Run `./fedora-gnome-setup.sh` and pick a step by number. Choose **21** to run every step in order.

| Option | Group                | Step                              |
| -----: | :------------------- | :-------------------------------- |
|      1 | System preparation   | Backup configs and .ssh folder    |
|      2 | System preparation   | Update DNF for faster downloads   |
|      3 | System preparation   | Upgrade Fedora                    |
|      4 | System preparation   | Update firmware                   |
|      5 | Package management   | Install and remove packages       |
|      6 | Package management   | Enable Flathub repository         |
|      7 | Package management   | Install development tools         |
|      8 | Package management   | Install codecs                    |
|      9 | Package management   | Install VLC and multimedia codecs |
|     10 | Environment setup    | Create custom directories         |
|     11 | Environment setup    | Install fonts                     |
|     12 | Environment setup    | Copy wallpapers                   |
|     13 | Environment setup    | Customize GNOME settings          |
|     14 | Environment setup    | Configure Vim                     |
|     15 | Environment setup    | Install Numix theme and icons     |
|     16 | Applications         | Install VSCode                    |
|     17 | Applications         | Configure Git                     |
|     18 | System configuration | Install and enable firewalld      |
|     19 | System configuration | Configure swappiness              |
|     20 | System configuration | Speed up boot time                |
|     21 | All                  | Execute all steps                 |
|      0 | Exit                 | Exit                              |

### Manual steps

After the script finishes:

* Install the **Desktop Icons** and **User Themes** extensions.
* Choose the dark theme in **Settings**.
* Set your user image under **Account Settings**.
* Add a terminal shortcut. Open **Settings**, then **Devices**, then **Keyboard**, then **Add new
  shortcut**. Name it `Open Terminal`, set the command to `gnome-terminal`, and press Ctrl+Alt+T.
* Add an xkill shortcut the same way. Use `xkill` as the name and command, and press
  Ctrl+Alt+Esc.
* Change the LibreOffice look. Select **View**, then **Toolbar Layout**, then **Single Toolbar**.
  Then select **Tools**, then **Options**, then **View**, then **Style**, and choose **Colibre**.
* Enable tray icons with the [TopIcons GNOME extension](https://extensions.gnome.org/extension/1031/topicons/).
* Turn on Night Light under **Settings**, then **Devices**, then **Display**.
* In Firefox preferences, enable **Restore previous session** and enable DRM support.
* From Firefox, open [GNOME Extensions](https://extensions.gnome.org/) and install **User
  Themes**, **Blur my Shell**, and **Dash to Dock**.

Install these by hand, and do not run install scripts without reviewing them first:

* [Homebrew](https://brew.sh)
* [Calibre](https://calibre-ebook.com)

The theme is the easy to install Numix GTK theme with Numix Circle icons. The wallpaper comes from
[catppuccin-wallpapers](https://github.com/zhichaoh/catppuccin-wallpapers).

![Fedora black 4k wallpaper preview](images/fedora-black-4k-preview.png)

## Project structure

```text
.
├── fedora-gnome-setup.sh       # Entry point and menu
├── fedora-gnome-functions.sh   # One function per setup step
├── package_install.txt         # Packages to install
├── package_remove.txt          # Packages to remove
├── configs/                    # Dotfiles copied into the home directory
├── wallpapers/                 # Desktop wallpapers
├── images/                     # README images
├── .github/workflows/          # ShellCheck CI
├── FUNCTIONALITY.md            # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Most steps call `sudo`.
* Step 1 backs up `~/.bashrc`, `~/.profile`, `~/.bash_profile`, and `~/.bash_logout` to `~/.config-backups` and creates `~/.ssh` with `700` permissions.
* Step 8 enables RPM Fusion Free, a third party repository, so full ffmpeg can be installed.
* Step 16 imports the Microsoft signing key and enables `gpgcheck` for the VSCode repository.
* Step 18 makes sure firewalld is enabled and prints the active zone for review.
* No credentials are stored. Set your Git name and email by hand after step 17.

## Testing

There are no automated tests. Lint the scripts with ShellCheck, which also runs in CI on every push.

```bash
shellcheck -x fedora-gnome-setup.sh fedora-gnome-functions.sh
```

Test full runs in a throwaway Fedora VM before using them on a real machine.

## Troubleshooting

| Problem                                 | Fix                                                          |
| :-------------------------------------- | :----------------------------------------------------------- |
| A step prints `failed with exit code`   | Read the error above it, fix the cause, and rerun that step. |
| Wallpaper does not change after step 13 | Log out and back in. GNOME does not always refresh it.       |

## Roadmap

* Install the [Catppuccin GTK theme](https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme),
  which needs `gtk-murrine-engine` and `sassc`.
* Install the [Tela icon theme](https://github.com/vinceliuice/Tela-icon-theme).
* Install the [Catppuccin Tilix theme](https://github.com/catppuccin/tilix).
* Install Docker and VirtualBox.
* Install the HashiCorp tools: Vagrant, Terraform, and Packer.
* Install a password manager.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
