![Fedora Logo](images/fedora.png) ![Gnome Logo](images/gnome.png)

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

# My Fedora Gnome Install

This script is to automate as much as possible the post installation of my Fedora Gnome system or provide instructions for personalization. It is still a work in progress and as things can be automated they will be moved from this README to the fedoraGnomeSetup.sh script. Obviously you take this repository and modify it to your taste.

1. Clone this repository to your home directory.

```bash
cd ~
git clone git@github.com:sgt7io/fedora-gnome-sgt7.git
cd fedora-gnome-sgt7
```

2. Run the fedoraGnomeSetup.sh script

```bash
$ chmod 700 fedoraGnomeSetup.sh
$ ./fedoraGnomeSetup.sh
```

Install Desktop Desktop Icons,and User Themes Extensions

There are numerous themes and icons on the internet, but I simply use the
easy to install Numix GTK theme and Numix circle icons.

I also use the following wallpaper, which I sourced from [catppuccin-wallpapers](https://github.com/zhichaoh/catppuccin-wallpapers "Fedora Black 4k Wallpaper"):

![Fedora Black 4k Wallpaper](images/fedora-black-4k-preview.png)

Go to Account Settings and set your user image. This will make your system more personal and more beautiful.

Ctrl+Alt+T to open Terminal
Settings => Devices => Keyboard => Add new shortcut
Name it Open Terminal and type gnome-terminal as a command
To set the shortcut, press Ctrl+Alt+T

Xkill shortcut
Settings => Devices => Keyboard => Add new shortcut.
Type xkill in the name and command and set Ctrl+Alt+Esc as a shortcut

Change LibreOffice look

View => Toolbar Layout => Single Toolbar

Tools => Options => View => Style. Select Colibre icons

Enable Tray Icons

https://extensions.gnome.org/extension/1031/topicons/

Enable Nightlight
Settings → Devices → Display → and set Night Light on.

Firefox Settings
Firefox Preferences and activate Restore previous session

Firefox DRM Settings
DRM support select enable

In "Settings" I choose the Dark Theme.

Open Firefox, go to https://extensions.gnome.org/ and install the plugin.
Extensions I install:
User Themes
Blur my Shell
Dash To Dock

### Things one should install manually. Do not just run bash scripts without reviewing them first!

- Homebrew
    - https://www.homebrew.com
- Calibre
    - https://calibre.com

**Things to add:**

- Catppuccin GTK Theme
https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme

sudo dnf install gtk-murrine-engine sassc

Installed Tela Icon Theme
https://github.com/vinceliuice/Tela-icon-theme

Install Catppucin Tilix Theme
https://github.com/catppuccin/tilix

- Install Docker

- Install VirtualBox

- Install Hashicorp Tools
    - Vagrant
    - Terraform
    - Packer

- Install My Favorite Password Manager
