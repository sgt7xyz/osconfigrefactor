# macOS Setup

Menu-driven zsh scripts that patch, harden, and set up a freshly installed Mac for development.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Apple logo](images/apple-logo.png)

## Overview

This is my build process for reinstalling macOS, hardening it, and installing my applications.
The process is to reinstall macOS first and then run the post-install script `macos-setup.sh`. It
is a work in progress and will be updated as it evolves.

Relevant sources:

* [macOS Security and Privacy Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide)
* [macOS Terminal keyboard shortcuts](https://support.apple.com/guide/terminal/keyboard-shortcuts-trmlshtcts/mac)
* [macOS buildout by Andrew Connell](https://github.com/andrewconnell/osx-install)

## Architecture

`macos-setup.sh` shows a grouped, numbered menu, logs each step it runs, and calls functions from
`macos-functions.sh`. DNS setup is a separate interactive tool, `macos-network.sh`, run as root.

```text
macos-setup.sh --> macos-functions.sh --> softwareupdate, socketfilterfw, brew, mise, git
      |                    |
      |                    +--> brew_install_list.txt, mise_install_list.txt, configs/
      +--> sudo zsh macos-network.sh --> networksetup
```

## Prerequisites

| Requirement              | Version          |
| :----------------------- | :--------------- |
| macOS on Apple Silicon   | Current release  |
| zsh                      | Ships with macOS |
| An administrator account | Not applicable   |
| Internet access          | Not applicable   |

## Quick start

1. Optionally do a clean reinstall first. See [Clean reinstall of macOS](#clean-reinstall-of-macos).
1. Open Terminal. On a clean install, press Command and Space to open Spotlight, type `Terminal`,
   and press Enter.
1. Clone this repository and run the setup script from the repository directory. If Git is not
   installed yet, macOS offers to install the Command Line Tools first.

   ```bash
   cd ~
   git clone git@github.com:sgt7xyz/macos-setup-sgt7.git
   cd macos-setup-sgt7
   chmod 700 macos-setup.sh macos-network.sh
   ./macos-setup.sh
   ```

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File                        | Description                                | Default                       |
| :-------------------------- | :----------------------------------------- | :---------------------------- |
| `brew_install_list.txt`     | Homebrew formulae to install, one per line | CLI, network, and cloud tools |
| `mise_install_list.txt`     | Tools to install with mise at `@latest`    | Cloud, Kubernetes, IaC tools  |
| `configs/nvim/init.lua`     | Neovim config copied to `~/.config/nvim`   | Catppuccin theme              |
| `configs/.editorconfig`     | EditorConfig copied to `~/.editorconfig`   | sgt7 LLC defaults             |
| `configs/.gitignore_global` | Global Git ignore file copied to `~/`      | Common OS and editor files    |

## Usage

Run `./macos-setup.sh` and pick a step by number. Choose **17** to run every step in order. Each
step is logged to `setup_log_<timestamp>.log` in the current directory.

| Option | Group              | Step                                                    |
| -----: | :----------------- | :------------------------------------------------------ |
|      1 | System preparation | Update and patch your Mac                               |
|      2 | System preparation | Rename your Mac                                         |
|      3 | System preparation | Install Xcode Command Line Tools                        |
|      4 | Security           | Check System Integrity Protection (SIP) status          |
|      5 | Security           | Enable firewall                                         |
|      6 | Security           | Disable auto-allow for built-in and downloaded software |
|      7 | Package management | Install Homebrew                                        |
|      8 | Package management | Install Homebrew packages                               |
|      9 | Package management | Install mise                                            |
|     10 | Package management | Install mise packages                                   |
|     11 | Network            | Configure DNS with `macos-network.sh`                   |
|     12 | Environment setup  | Configure faster key repeat                             |
|     13 | Environment setup  | Download and install Droid SansM Nerd Font              |
|     14 | Environment setup  | Install Oh My Zsh and Powerlevel10k                     |
|     15 | Environment setup  | Configure Git                                           |
|     16 | Environment setup  | Configure application themes (Catppuccin Macchiato)     |
|     17 | All                | Execute all                                             |
|      0 | Exit               | Exit                                                    |

You can also run the DNS tool on its own.

```bash
sudo zsh macos-network.sh
```

### Clean reinstall of macOS

There have been reports of M1 Macs having issues after wiping the drive, so a bootable USB
installer is highly recommended. Create one by following
[How to create a bootable installer for macOS](https://support.apple.com/en-us/HT201372).

Internet Recovery has been removed on Apple Silicon. See
[Use macOS Recovery on an Apple Silicon Mac](https://support.apple.com/guide/mac-help/macos-recovery-a-mac-apple-silicon-mchl82829c17/mac)
for background. With the USB installer inserted:

1. If the Mac is powered on, shut it down.
1. Power on the Mac and hold the power button until **Loading startup options** appears.
1. Select **Install macOS (Version)**, then **Continue**.
1. Select a user with administrator access, select **Next**, and authenticate when prompted. If
   you cannot authenticate, or you want to wipe the Mac completely, select **Erase Mac** from the
   **Recovery Assistant** menu instead.
1. From the Recovery menu, select **Disk Utility**.
1. Select the internal disk labeled **Macintosh HD**. If there is an **Erase Volume Group**
   option, check it.
1. Select **Erase**, then **Erase Mac** when prompted.
1. Select **Erase Mac and Restart**.
1. After the reboot, choose your language.
1. If the Mac is not activated automatically, activate it with your Apple ID. You can
   [create an Apple ID](https://appleid.apple.com/account) if you do not have one.
1. Exit to Recovery.
1. Select **Reinstall macOS** for the current version and reinstall.

### Manual software installation

I install these apps by package or from the App Store. Many can be installed with Homebrew, but
that is a personal preference.

* [Signal](https://signal.org/download/)
* [Chrome](https://www.google.com/chrome/)
* [VSCode](https://code.visualstudio.com/Download)
* [Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466)
* [1Password](https://1password.com/downloads)
* [Floorp](https://floorp.app/download/)
* [VLC Player](https://www.videolan.org/vlc/)
* [Acrobat Reader](https://get.adobe.com/reader/)
* [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
* [Draw.io](https://www.drawio.com/)
* [Rectangle](https://rectangleapp.com/)
* [Caffeine](https://intelliscapesolutions.com/apps/caffeine)

## Project structure

```text
.
├── macos-setup.sh            # Entry point and menu
├── macos-functions.sh        # One function per setup step
├── macos-network.sh          # Interactive DNS configuration tool
├── brew_install_list.txt     # Homebrew formulae
├── mise_install_list.txt     # mise tools
├── configs/                  # Neovim, EditorConfig, and Git configs
├── images/                   # README images
├── FUNCTIONALITY.md          # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Several steps call `sudo`.
* Steps 7, 9, and 14 run remote install scripts with `curl | sh`. The script shows the exact
  command and asks before running it.
* Step 5 turns on the application firewall and stealth mode. Step 6 stops signed apps from being
  allowed through automatically.
* Step 4 checks SIP, and the script warns on exit if SIP is disabled.
* When installing apps by hand, follow these practices:
  * Download only from the developer's official site or the Mac App Store.
  * Verify the SHA-256 hash against the one the developer publishes, with
    `shasum -a 256 /path/to/downloaded-file`.
  * Scan installers with [VirusTotal](https://www.virustotal.com/) before running them.
  * Check the code signature with `codesign -dv --verbose=2 /path/to/Application.app`.
* No credentials are stored. Set your Git name and email by hand after step 15.

## Testing

There are no automated tests. ShellCheck does not support zsh, so check syntax with zsh itself.

```bash
zsh -n macos-setup.sh macos-functions.sh macos-network.sh
```

## Troubleshooting

| Problem                                           | Fix                                           |
| :------------------------------------------------ | :-------------------------------------------- |
| Step 11 says the network script is not executable | Run `chmod 700 macos-network.sh`.             |
| `brew_install_list.txt` is not found              | Run the script from the repository directory. |
| Key repeat change does not apply                  | Log out and back in after step 12.            |

## Roadmap

* No planned items yet. The build process is updated as it evolves.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
