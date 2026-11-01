# Debian Tiling Setup

Menu-driven Bash scripts that automate the post-install setup of a Debian system running the i3
tiling window manager.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Debian logo](images/debian.png) ![i3 logo](images/i3.png)

## Overview

This repository automates as much as possible of a fresh Debian install built around i3, polybar,
rofi, and alacritty. It installs packages, fonts, wallpapers, a firewall, VSCode, and Git
defaults. It is a work in progress, and steps move from this README into the script as they get
automated. Fork it and adjust the package lists and configs to your taste.

## Architecture

`debian-tiling-setup.sh` shows a numbered menu and calls functions from
`debian-tiling-functions.sh`. Package lists and dotfiles are read from the repository at run time.

```text
debian-tiling-setup.sh --> debian-tiling-functions.sh --> apt, curl, ufw, git
                                     |
                                     +--> package_install.txt, package_remove.txt, configs/, scripts/, wallpapers/
```

## Prerequisites

| Requirement                       | Version                |
| :-------------------------------- | :--------------------- |
| Debian minimal or netinst install | 12 (bookworm) or newer |
| Bash                              | 5.0 or newer           |
| A user with `sudo` rights         | Not applicable         |
| Internet access                   | Not applicable         |

## Quick start

1. Clone this repository to your home directory.

   ```bash
   cd ~
   git clone git@github.com:sgt7xyz/debian-tiling-sgt7.git
   cd debian-tiling-sgt7
   ```

1. Select additional repositories and switch to the fastest update server.

   * Open **Software and Updates**, then the **Debian Software** tab.
   * Select the additional repositories under **Downloadable from the Internet**.
   * Under **Download from**, select the best server for your locale.

1. Run the setup script from the repository directory.

   ```bash
   chmod 700 debian-tiling-setup.sh
   ./debian-tiling-setup.sh
   ```

To test in a VirtualBox VM first, run `./debian-tiling-vm-prep.sh` inside the VM before the main
script.

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File or folder        | Description                                        | Default                      |
| :-------------------- | :------------------------------------------------- | :--------------------------- |
| `package_install.txt` | Packages to install, one per line                  | Xorg, i3, polybar, dev tools |
| `package_remove.txt`  | Packages to purge, one per line                    | `aisleriot`                  |
| `configs/`            | i3, polybar, rofi, alacritty, picom, and X configs | Catppuccin Macchiato theme   |
| `scripts/`            | Helper scripts copied to `~/scripts`               | Volume and update helpers    |
| `wallpapers/`         | Wallpapers copied to `~/Pictures/wallpapers`       | Nine wallpapers              |

## Usage

Run `./debian-tiling-setup.sh` and pick a step by number. Choose **15** to run every step in order.

| Option | Step                                                 |
| -----: | :--------------------------------------------------- |
|      1 | Backup configs, update, install, and remove packages |
|      2 | Create custom directories in your home directory     |
|      3 | Install fonts                                        |
|      4 | Configure console terminal settings                  |
|      5 | Copy wallpapers to `~/Pictures/wallpapers`           |
|      6 | Customize tiling settings                            |
|      7 | Customize vimrc file settings                        |
|      8 | Install VLC, plugins, and restricted extras          |
|      9 | Install UFW and enable it                            |
|     10 | Configure swappiness                                 |
|     11 | Speed up boot time                                   |
|     12 | Prep and install VSCode                              |
|     13 | Configure Git                                        |
|     15 | Execute all                                          |
|      0 | Exit                                                 |

## Project structure

```text
.
├── debian-tiling-setup.sh       # Entry point and menu
├── debian-tiling-functions.sh   # One function per setup step
├── debian-tiling-vm-prep.sh     # Optional VirtualBox guest prep
├── package_install.txt          # Packages to install
├── package_remove.txt           # Packages to purge
├── configs/                     # i3, polybar, rofi, alacritty, picom, and X configs
├── scripts/                     # volume-up.sh, volume-down.sh, system-update.sh
├── wallpapers/                  # Desktop wallpapers
├── images/                      # README images
├── FUNCTIONALITY.md             # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Most steps call `sudo`.
* Step 1 backs up `~/.bashrc`, `~/.profile`, and `~/.bash_logout` to `~/.config-backups`.
* Step 9 enables UFW, which denies inbound connections by default.
* Step 12 adds the Microsoft signing key so apt verifies VSCode packages.
* No credentials are stored. Set your Git name and email by hand after step 13.

## Testing

There are no automated tests. Lint the scripts with ShellCheck.

```bash
shellcheck -x debian-tiling-setup.sh debian-tiling-functions.sh debian-tiling-vm-prep.sh scripts/*.sh
```

Test full runs in a throwaway Debian VM before using them on a real machine.

## Troubleshooting

| Problem                                         | Fix                                                          |
| :---------------------------------------------- | :----------------------------------------------------------- |
| A step prints `failed with exit code`           | Read the error above it, fix the cause, and rerun that step. |
| Step 13 cannot find `configs/.gitignore_global` | Add a `.gitignore_global` file to `configs/`.                |

## Roadmap

* Turn the commented out config copies in step 6 back on.
* Move more of the manual steps into the script.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
