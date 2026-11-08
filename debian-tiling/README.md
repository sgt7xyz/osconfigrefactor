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

`debian-tiling-setup.sh` builds a grouped, numbered menu from one ordered list of steps and calls
functions from `common-functions.sh` and `debian-tiling-functions.sh`. Package lists and dotfiles
are read from the repository at run time.

```text
debian-tiling-setup.sh --> common-functions.sh + debian-tiling-functions.sh --> apt, curl, ufw, git
                                                           |
                                                           +--> package_install.txt, package_remove.txt, configs/, scripts/, wallpapers/
```

## Prerequisites

| Requirement                       | Version                |
| :-------------------------------- | :--------------------- |
| Debian minimal or netinst install | 13 (trixie) or newer   |
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

Run the setup script and pick a step by number. Choose **16** to run every step in order. When
it finishes, any steps that failed are listed together. Steps 1 to 14 are the same in
fedora-tiling, so the same number means the same step on both systems.

| Option | Group                | Step                                             |
| -----: | :------------------- | :----------------------------------------------- |
|      1 | System preparation   | Back up configs and create .ssh directory        |
|      2 | System preparation   | Update and upgrade the system                    |
|      3 | System preparation   | Install and remove packages                      |
|      4 | Environment setup    | Create custom directories                        |
|      5 | Environment setup    | Install Nerd font                                |
|      6 | Environment setup    | Copy wallpapers                                  |
|      7 | Environment setup    | Install i3, polybar, rofi, and alacritty configs |
|      8 | Environment setup    | Customize vimrc file                             |
|      9 | Environment setup    | Configure Git                                    |
|     10 | Applications         | Install VLC, plugins, and codecs                 |
|     11 | Applications         | Install VSCode                                   |
|     12 | System configuration | Enable the firewall (deny all inbound)           |
|     13 | System configuration | Configure swappiness                             |
|     14 | System configuration | Speed up boot time                               |
|     15 | Debian extras        | Configure console font and size                  |
|     16 | All                  | Execute all steps                                |
|      0 | Exit                 | Exit                                             |

## Project structure

```text
.
├── debian-tiling-setup.sh       # Entry point and menu
├── common-functions.sh          # Menu engine and steps shared with fedora-tiling
├── debian-tiling-functions.sh   # Debian specific setup steps
├── debian-tiling-vm-prep.sh     # Optional VirtualBox guest prep
├── package_install.txt          # Packages to install
├── package_remove.txt           # Packages to purge
├── configs/                     # i3, polybar, rofi, alacritty, picom, and X configs
├── scripts/                     # volume-up.sh, volume-down.sh, system-update.sh
├── wallpapers/                  # Desktop wallpapers
├── images/                      # README images
├── .github/workflows/           # ShellCheck CI
├── FUNCTIONALITY.md             # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Most steps call `sudo`.
* Step 1 backs up `~/.bashrc`, `~/.profile`, and `~/.bash_logout` to `~/.config-backups` and creates `~/.ssh` with `700` permissions.
* Step 5 checks the Nerd Font download against its published SHA-256 before installing it.
* Step 11 adds the Microsoft signing key so apt verifies VSCode packages.
* Step 12 enables UFW so it denies every inbound connection the host did not start, including the
  mDNS and UPnP discovery traffic stock UFW allows. Replies to outbound traffic still get in.
* No credentials are stored. Set your Git name and email by hand after step 9.

## Testing

There are no automated tests. Lint the scripts with ShellCheck, which also runs in CI on every push.

```bash
shellcheck -x debian-tiling-setup.sh common-functions.sh debian-tiling-functions.sh debian-tiling-vm-prep.sh scripts/*.sh
```

Test full runs in a throwaway Debian VM before using them on a real machine.

## Troubleshooting

| Problem                                         | Fix                                                          |
| :---------------------------------------------- | :----------------------------------------------------------- |
| A step prints `failed with exit code`           | Read the error above it, fix the cause, and rerun that step. |
| Step 9 cannot find `configs/.gitignore_global`  | Add a `.gitignore_global` file to `configs/`.                |

## Roadmap

* Move more of the manual steps into the script.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
