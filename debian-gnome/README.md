![Debian Logo](images/debian.png) ![Gnome Logo](images/gnome.png)

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

# My Debian Gnome Install

This script is to automate as much as possible the post installation of my Debian system or provide instructions for personalization. It is still a work in progress and as things can be automated they will be moved from this README to the debianGnomeSetup.sh script. Obviously you take this repository and modify it to your taste.

1. Clone this repository to your home directory.

```bash
cd ~
git clone git@github.com:sgt7io/my-debian-gnome.git
cd my-debian-gnome
```

2. Select additional repositories and switch to fastest update server.

- Open "Software and Updates" => Debian Software Tab
  - Select additional repositores under the "Downloadable from the Internet" section.
  - Under "Download from" and select the best server for your locale.

3. Run the debianGnomeSetup.sh script

```bash
$ chmod 700 debianGnomeSetup.sh
$ ./debianGnomeSetup.sh
```

Install Desktop Desktop Icons,and User Themes Extensions

There are numerous themes and icons on the internet, but I simply use the
easy to install Numix GTK theme and Numix circle icons.

I also use the following wallpaper, which I sourced from [Wallpaper House](https://wallpaper-house.com/wallpaper-id-391811.php "Wallpaper House")

![Feather Wallpaper](images/wallpaperpreview.png)

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

Before execurting all the steps I personall switch to X.org as Wayland does not work as well in my opinion, but your experience may vary.
Prior to logging in select System X11 Default at login screen.
You can can verify from the terminal once you log in.
ps -e | grep X
