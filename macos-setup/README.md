![Apple Logo](img/Apple_logo_black.svg.png)

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png"/></a><br/>This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

# macOS Setup

---

This is my current build process for installing macOS and applications as well as hardening. Currently it is a process of first re-installing macOS and then running the post-install macOS setup script macOSSetup.sh.

This is definitley a work in progress and will be updated as it evolves.

## Relevant sources and links

- [macOS Security and Privacy Guide
  ](https://github.com/drduh/macOS-Security-and-Privacy-Guide)
- [macOS Terminal Shortcuts](https://support.apple.com/guide/terminal/keyboard-shortcuts-trmlshtcts/mac)
- [MacOS Buildout](https://github.com/andrewconnell/osx-install)

## 1. Create a macOS USB installer

Note: There have been reports that M1 Macs have had issues after wiping the Hard Drive. It is highly recommended that you create a USB bootable installer.

Reference: [How to create a bootable installer for macOS](https://support.apple.com/en-us/HT201372)

1. Create a bootable installer for macOS by following the instructions in the aforementioned reference link.

## 2. Re-install macOS

## Apple Silicon Mac

Reference: [Use macOS Recovery on an Apple Silicon Mac](https://support.apple.com/guide/mac-help/macos-recovery-a-mac-apple-silicon-mchl82829c17/mac)

Internet Recovery has been removed. To boot into Recovery mode follow the below procedure.

**Ensure the macOS USB installer is inserted into your Mac.**

1. If powered on shut it down.
2. Power on the Mac, but hold the power button until “Loading startup options” appears.
3. When presented with your Hard Drive (typically Macintosh HD), Install macOS (Version), or Options, select "Install macOS (Version)" and "Continue."
4. Select a user with Administrator access and authenticate and select "Next." Authenticate when prompted.

- Optionally (and preferred), if you are not able to authenticate with a known admin user account or you want to compltely wipe your mac, you can select "Erase Mac..." from the top left menu under Recovery Assistant.

5. From the Recovery menu select Disk Utility.
6. Select the internal disk labeled Macintosh HD. If there's an option title Erase Volume Group, check the box.
7. Select Erase and select "Erase Mac..." when prompted from the dialog.
8. Finally select Erase Mac and Restart.
9. After the Mac reboots select your preferred language on the Language screen.
10. If not automatically activated activate your Mac with your Apple ID. If you do not have an Apple ID one can be created with the following direct link.
    - [Create an Apple ID](https://appleid.apple.com/account)
11. Exit to Recovery.
12. Select Reinstall macOS `Current Version`.
13. Reinstall the OS.

## 3. Execute macOSSetup Script

**Open a terminal**

- On a clean install of macOS, Spotlight is the easiest way to open terminal. Press Command (or Cmd) ⌘ + Space Bar. When presnted with a dialig start to type Terminal and when presented with a match press Enter.

## 4. Manual Software Installation

**The Following Apps I Install manually by package or the App Store. You can install many of them by Homebrew, but it's a personal preference.**

> **Security Best Practices for Manual Installs**
>
> - **Download from official sources only.** Always use the developer's official website or the Mac App Store.
> - **Verify file hashes.** Many developers publish SHA-256 checksums alongside their downloads. After downloading, verify the hash in Terminal:
>   ```bash
>   shasum -a 256 /path/to/downloaded-file
>   ```
>   Compare the output to the hash listed on the developer's download page.
> - **Scan binaries with antimalware software.** Upload installers and binaries to [VirusTotal](https://www.virustotal.com/) before running them. VirusTotal scans files against dozens of antivirus engines and provides a detailed report.
> - **Check code signatures.** Verify that the downloaded application is properly signed by the developer:
>   ```bash
>   codesign -dv --verbose=2 /path/to/Application.app
>   ```

- [Signal](https://signal.org/download/)
- [Chrome](https://www.google.com/chrome/)
- [VSCode](https://code.visualstudio.com/Download)
- [Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466)
- [1Password](https://1password.com/downloads)
- [Floorp](https://floorp.app/download/)
- [VLC Player](https://www.videolan.org/vlc/)
- [Acrobat Reader](https://get.adobe.com/reader/)
- [VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
- [Draw.io](https://www.drawio.com/)
- [Rectangle](https://rectangleapp.com/)
- [Caffeine](https://intelliscapesolutions.com/apps/caffeine)
