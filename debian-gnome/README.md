# Debian GNOME Setup

Menu-driven Bash scripts that automate the post-install setup of a Debian desktop running GNOME.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Debian logo](images/debian.png) ![GNOME logo](images/gnome.png)

## Overview

This repository automates as much as possible of a fresh Debian GNOME install: package updates,
desktop tweaks, a firewall, VSCode, and Git defaults. Steps that cannot be scripted yet are listed
under [Manual steps](#manual-steps) and move into the script as they get automated. Fork it and
adjust the package lists and settings to your taste.

## Architecture

`debian-gnome-setup.sh` shows a numbered menu and calls functions from
`debian-gnome-functions.sh`. Package lists are plain text files read at run time.

```text
debian-gnome-setup.sh --> debian-gnome-functions.sh --> apt, gsettings, ufw, git
                                    |
                                    +--> package_install.txt, package_remove.txt, wallpapers/, configs/
```

## Prerequisites

| Requirement                   | Version                |
| :---------------------------- | :--------------------- |
| Debian with the GNOME desktop | 12 (bookworm) or newer |
| Bash                          | 5.0 or newer           |
| A user with `sudo` rights     | Not applicable         |
| Internet access               | Not applicable         |

## Quick start

1. Clone this repository to your home directory.

   ```bash
   cd ~
   git clone git@github.com:sgt7xyz/debian-gnome-sgt7.git
   cd debian-gnome-sgt7
   ```

1. Select additional repositories and switch to the fastest update server.

   * Open **Software and Updates**, then the **Debian Software** tab.
   * Select the additional repositories under **Downloadable from the Internet**.
   * Under **Download from**, select the best server for your locale.

1. Run the setup script from the repository directory.

   ```bash
   chmod 700 debian-gnome-setup.sh
   ./debian-gnome-setup.sh
   ```

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File                        | Description                                 | Default                    |
| :-------------------------- | :------------------------------------------ | :------------------------- |
| `package_install.txt`       | Packages to install, one per line           | CLI tools, Tilix, Vim      |
| `package_remove.txt`        | Packages to purge, one per line             | Bundled GNOME games        |
| `wallpapers/`               | Wallpaper copied to `~/Pictures/wallpapers` | Feather wallpaper          |
| `configs/.gitignore_global` | Global Git ignore file copied to `~/`       | Common OS and editor files |

## Usage

Run `./debian-gnome-setup.sh` and pick a step by number. Choose **13** to run every step in order.

| Option | Step                                             |
| -----: | :----------------------------------------------- |
|      1 | Update, install, and remove packages             |
|      2 | Create custom directories in your home directory |
|      3 | Copy wallpapers to `~/Pictures/wallpapers`       |
|      4 | Customize GNOME settings                         |
|      5 | Customize vimrc file settings                    |
|      6 | Install VLC, plugins, and restricted extras      |
|      7 | Install UFW and enable it                        |
|      8 | Configure swappiness                             |
|      9 | Speed up boot time                               |
|     10 | Install Numix theme and icons                    |
|     11 | Prep and install VSCode                          |
|     12 | Configure Git                                    |
|     13 | Execute all                                      |
|      0 | Exit                                             |

### Manual steps

Before running the steps, I switch to X.org because Wayland does not work as well for me. Your
experience may vary. At the login screen, select **System X11 Default**, then confirm from a
terminal after logging in.

```bash
ps -e | grep X
```

After the script finishes:

* Install the **Desktop Icons** and **User Themes** extensions.
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

The theme is the easy to install Numix GTK theme with Numix Circle icons. The wallpaper comes from
[Wallpaper House](https://wallpaper-house.com/wallpaper-id-391811.php).

![Feather wallpaper preview](images/wallpaperpreview.png)

## Project structure

```text
.
├── debian-gnome-setup.sh       # Entry point and menu
├── debian-gnome-functions.sh   # One function per setup step
├── package_install.txt         # Packages to install
├── package_remove.txt          # Packages to purge
├── configs/                    # Dotfiles copied into the home directory
├── wallpapers/                 # Desktop wallpaper
├── images/                     # README images
├── .github/workflows/          # ShellCheck CI
├── FUNCTIONALITY.md            # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. Most steps call `sudo`.
* Step 7 enables UFW, which denies inbound connections by default.
* Step 11 adds the Microsoft signing key so apt verifies VSCode packages.
* No credentials are stored. Set your Git name and email by hand after step 12.

## Testing

There are no automated tests. Lint the scripts with ShellCheck, which also runs in CI on every push.

```bash
shellcheck -x debian-gnome-setup.sh debian-gnome-functions.sh
```

Test full runs in a throwaway Debian VM before using them on a real machine.

## Troubleshooting

| Problem                                | Fix                                                          |
| :------------------------------------- | :----------------------------------------------------------- |
| A step prints `failed with exit code`  | Read the error above it, fix the cause, and rerun that step. |
| Wallpaper does not change after step 4 | Log out and back in. GNOME does not always refresh it.       |

## Roadmap

* Move more of the manual steps into the script.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
