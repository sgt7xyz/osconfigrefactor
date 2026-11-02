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

`fedora-tiling-setup.sh` builds a grouped, numbered menu from one ordered list of steps and calls
functions from `fedora-tiling-functions.sh`. Package lists and dotfiles are read from the repository
at run time.

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

Run the setup script and pick a step by number. Choose **22** to run every step in order. When
it finishes, any steps that failed are listed together. Steps 1 to 14 are the same in
debian-tiling, so the same number means the same step on both systems.

| Option | Group                | Step                                   |
| -----: | :------------------- | :------------------------------------- |
|      1 | System preparation   | Back up shell dotfiles                 |
|      2 | System preparation   | Update and upgrade the system          |
|      3 | System preparation   | Install and remove packages            |
|      4 | Environment setup    | Create custom directories              |
|      5 | Environment setup    | Install Nerd font                      |
|      6 | Environment setup    | Copy wallpapers                        |
|      7 | Environment setup    | Install Sway, foot, and rofi configs   |
|      8 | Environment setup    | Customize vimrc file                   |
|      9 | Environment setup    | Configure Git                          |
|     10 | Applications         | Install VLC, plugins, and codecs       |
|     11 | Applications         | Install VSCode                         |
|     12 | System configuration | Enable the firewall (deny all inbound) |
|     13 | System configuration | Configure swappiness                   |
|     14 | System configuration | Speed up boot time                     |
|     15 | Fedora extras        | Update firmware                        |
|     16 | Fedora extras        | Enable Flathub repository              |
|     17 | Fedora extras        | Install development tools              |
|     18 | Fedora extras        | Install OBS Studio                     |
|     19 | Fedora extras        | Install Docker                         |
|     20 | Fedora extras        | Install VirtualBox                     |
|     21 | Fedora extras        | Install Brave browser                  |
|     22 | All                  | Execute all steps                      |
|      0 | Exit                 | Exit                                   |

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
* Step 5 checks the Nerd Font download against its published SHA-256 before installing it.
* Step 10 enables RPM Fusion, whose release packages install its signing keys.
* Steps 11 and 20 import vendor signing keys and enable `gpgcheck` for their repositories.
* Step 12 makes a stripped `public` zone the firewalld default, so it rejects every inbound
  connection the host did not start. Replies to outbound traffic still get in.
* Step 19 adds your user to the `docker` group, which is root equivalent on this host.
* No credentials are stored. Set your Git name and email by hand after step 9.

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
| `docker` commands fail with permission denied | Reboot after step 19 so the group change takes effect.       |
| VirtualBox USB devices are missing            | Log out and back in after step 20.                           |

## Roadmap

* Add menu steps for Google Chrome and mise.
* Add a waybar config to `configs/waybar/`.
* Work through the items in `fixed.txt`.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
