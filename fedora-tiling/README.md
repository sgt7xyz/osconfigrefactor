# Fedora Tiling Setup

Menu-driven Bash scripts that automate the post-install setup of a Fedora system running the Sway
tiling window manager.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Fedora logo](images/fedora.png)

## Overview

This repository automates as much as possible of a fresh Fedora install built around Sway, foot,
and rofi. It configures DNF, upgrades the system and firmware, installs packages, codecs, fonts,
VSCode, OBS Studio, Docker, and VirtualBox, and applies firewall and Git defaults. Sway is the
current choice, but that might change. Fork it and adjust the package lists and configs to your
taste.

## Architecture

`fedora-tiling-setup.sh` shows a grouped, numbered menu and calls functions from
`fedora-tiling-functions.sh`. Package lists and dotfiles are read from the repository at run time.

```text
fedora-tiling-setup.sh --> fedora-tiling-functions.sh --> dnf, flatpak, fwupdmgr, firewalld, docker, git
                                     |
                                     +--> package_install.txt, package_remove.txt, configs/, wallpapers/
```

## Prerequisites

| Requirement                          | Version        |
| :----------------------------------- | :------------- |
| Fedora Sway Spin or Fedora with Sway | 41 or newer    |
| Bash                                 | 5.0 or newer   |
| A user with `sudo` rights            | Not applicable |
| Internet access                      | Not applicable |

## Quick start

1. Clone this repository to your home directory.

   ```bash
   cd ~
   git clone git@github.com:sgt7xyz/fedora-tiling-sgt7.git
   cd fedora-tiling-sgt7
   ```

1. Run the setup script from the repository directory.

   ```bash
   chmod 700 fedora-tiling-setup.sh
   ./fedora-tiling-setup.sh
   ```

To test in a VirtualBox VM first, run `./fedora-tiling-vm-prep.sh` inside the VM before the main
script.

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File or folder              | Description                                     | Default                          |
| :-------------------------- | :---------------------------------------------- | :------------------------------- |
| `package_install.txt`       | Packages to install, one per line               | CLI tools, rofi, Neovim          |
| `package_remove.txt`        | Packages to remove, one per line                | `aisleriot`                      |
| `configs/sway/config`       | Sway config copied to `~/.config/sway`          | Catppuccin Macchiato theme       |
| `configs/foot/foot.ini`     | foot terminal config copied to `~/.config/foot` | Catppuccin Macchiato theme       |
| `configs/rofi/`             | rofi launcher config and theme                  | Catppuccin Macchiato theme       |
| `configs/.gitignore_global` | Global Git ignore file copied to `~/`           | Common OS and editor files       |
| `scripts/`                  | Volume helper scripts                           | `volume-up.sh`, `volume-down.sh` |
| `wallpapers/`               | Wallpapers copied to `~/Pictures/wallpapers`    | Eight wallpapers                 |

## Usage

Run `./fedora-tiling-setup.sh` and pick a step by number. Choose **23** to run every step in order.

| Option | Group                | Step                                        |
| -----: | :------------------- | :------------------------------------------ |
|      1 | System preparation   | Backup configs                              |
|      2 | System preparation   | Update DNF for faster downloads             |
|      3 | System preparation   | Upgrade Fedora                              |
|      4 | System preparation   | Update firmware                             |
|      5 | Package management   | Install and remove packages                 |
|      6 | Package management   | Enable Flathub repository                   |
|      7 | Package management   | Install development tools                   |
|      8 | Package management   | Install codecs                              |
|      9 | Environment setup    | Create custom directories                   |
|     10 | Environment setup    | Install Nerd font                           |
|     11 | Environment setup    | Copy wallpapers                             |
|     12 | Environment setup    | Customize tiling settings                   |
|     13 | Environment setup    | Customize vimrc file                        |
|     14 | Applications         | Install VLC, plugins, and restricted extras |
|     15 | Applications         | Install VSCode                              |
|     16 | Applications         | Install OBS Studio                          |
|     17 | Applications         | Configure Git                               |
|     18 | System configuration | Install and enable firewalld                |
|     19 | System configuration | Configure swappiness                        |
|     20 | System configuration | Speed up boot time                          |
|     21 | System configuration | Install Docker                              |
|     22 | System configuration | Install VirtualBox                          |
|     23 | All                  | Execute all steps                           |
|      0 | Exit                 | Exit                                        |

## Project structure

```text
.
├── fedora-tiling-setup.sh       # Entry point and menu
├── fedora-tiling-functions.sh   # One function per setup step
├── fedora-tiling-vm-prep.sh     # Optional VirtualBox guest prep
├── package_install.txt          # Packages to install
├── package_remove.txt           # Packages to remove
├── fixed.txt                    # Owner's scratch list of steps to fix
├── configs/                     # Sway, foot, rofi, and Git configs
├── scripts/                     # volume-up.sh and volume-down.sh
├── wallpapers/                  # Desktop wallpapers
├── images/                      # README images
├── .github/workflows/           # ShellCheck CI
├── FUNCTIONALITY.md             # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Most steps call `sudo`.
* Step 1 backs up `~/.bashrc`, `~/.bash_profile`, and `~/.bash_logout` to `~/.config-backups`.
* Steps 15 and 22 import vendor signing keys and enable `gpgcheck` for their repositories.
* Step 18 makes sure firewalld is enabled and prints the active zone for review.
* Step 21 adds your user to the `docker` group, which is root equivalent on this host.
* No credentials are stored. Set your Git name and email by hand after step 17.

## Testing

There are no automated tests. Lint the scripts with ShellCheck, which also runs in CI on every push.

```bash
shellcheck -x fedora-tiling-setup.sh fedora-tiling-functions.sh fedora-tiling-vm-prep.sh scripts/*.sh
```

Test full runs in a throwaway Fedora VM before using them on a real machine.

## Troubleshooting

| Problem                                       | Fix                                                          |
| :-------------------------------------------- | :----------------------------------------------------------- |
| A step prints `failed with exit code`         | Read the error above it, fix the cause, and rerun that step. |
| `docker` commands fail with permission denied | Reboot after step 21 so the group change takes effect.       |
| VirtualBox USB devices are missing            | Log out and back in after step 22.                           |

## Roadmap

* Add menu steps for Google Chrome, mise, and the existing Brave browser function.
* Add a waybar config to `configs/waybar/`.
* Work through the items in `fixed.txt`.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
