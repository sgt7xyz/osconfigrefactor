# Windows 11 Setup

Menu-driven PowerShell scripts that automate the post-install setup, debloat, and upkeep of a
Windows 11 Pro workstation.

[![License: PolyForm Small Business 1.0.0](https://img.shields.io/badge/license-PolyForm_Small_Business-blue)](https://polyformproject.org/licenses/small-business/1.0.0)

![Windows logo](images/winlogo.png)

## Overview

This repository turns a fresh Windows 11 install into a developer friendly, privacy conscious
machine. It renames the PC, patches Windows, installs and removes winget packages, installs Chrome,
the Fira Code Nerd Font, Windows Terminal with Oh My Posh and mise, wallpapers, and Git defaults.
An opt-in step removes bloatware and applies privacy and performance tweaks, and another schedules
maintenance tasks that reapply those tweaks after Windows updates. Fork it and edit the list files
to suit your machine.

## Architecture

`win11-setup.ps1` checks for administrator rights, dot-sources `win11-functions.ps1`, and shows a
numbered menu. Each option calls one function. `scripts/win11-maintenance.ps1` is a standalone
copy of the tweak functions that Task Scheduler runs as SYSTEM.

```text
win11-setup.ps1 --> win11-functions.ps1 --> winget, PSWindowsUpdate, registry, services, git
                              |
                              +--> winget_install.txt, winget_uninstall.txt, debloat_list.txt,
                              |    configs/, fonts/, wallpapers/
                              +--> scripts/win11-maintenance.ps1 --> Task Scheduler (weekly, monthly)
```

## Prerequisites

| Requirement                        | Version         |
| :--------------------------------- | :-------------- |
| Windows 11 Pro                     | Current release |
| Windows PowerShell or PowerShell 7 | 5.1 or newer    |
| An administrator account           | Not applicable  |
| Internet access                    | Not applicable  |

## Quick start

1. Allow local scripts to run for your user. Run this once in PowerShell and answer **Y**.

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

1. Clone this repository, or download and extract it.

   ```powershell
   git clone https://github.com/sgt7xyz/windows-setup-sgt7.git
   cd windows-setup-sgt7
   ```

1. Open PowerShell with **Run as administrator**, change to the repository directory, and run the
   menu.

   ```powershell
   .\win11-setup.ps1
   ```

## Configuration

This project reads no environment variables. Behavior is controlled by the files below.

| File or folder                   | Description                                     | Default                         |
| :------------------------------- | :---------------------------------------------- | :------------------------------ |
| `winget_install.txt`             | winget package IDs to install, `#` for comments | Browsers, CLI, editors, DevOps  |
| `winget_uninstall.txt`           | winget package IDs to uninstall                 | Same categories as install      |
| `debloat_list.txt`               | Appx package names to remove, wildcards allowed | Xbox, Widgets, consumer apps    |
| `configs/Terminal/settings.json` | Windows Terminal settings                       | Fira Code Nerd Font, Catppuccin |
| `configs/OhMyPosh/`              | Oh My Posh prompt theme                         | Catppuccin Macchiato            |
| `configs/Git/.gitignore_global`  | Global Git ignore file copied to your profile   | Common OS and editor files      |
| `fonts/FiraCode/`                | Offline copy of the Fira Code Nerd Font         | 20 font files                   |
| `wallpapers/`                    | Wallpapers copied to `Pictures\Wallpapers`      | `01.png` set as the desktop     |

## Usage

Run `.\win11-setup.ps1` as administrator and pick a step by number. Option **13** runs steps 1 to 4
and 6 to 10 in order. It skips steps 5, 11, and 12, which you run on their own.

| Option | Group                    | Step                                                 |
| -----: | :----------------------- | :--------------------------------------------------- |
|      1 | System configuration     | Rename the PC                                        |
|      2 | System configuration     | Install winget                                       |
|      3 | System configuration     | Update and patch Windows                             |
|      4 | Package management       | Install winget packages                              |
|      5 | Package management       | Uninstall winget packages                            |
|      6 | Applications and tools   | Install Google Chrome                                |
|      7 | Applications and tools   | Install fonts                                        |
|      8 | Applications and tools   | Install Windows Terminal, Oh My Posh, and mise setup |
|      9 | Applications and tools   | Install wallpapers                                   |
|     10 | Applications and tools   | Configure Git                                        |
|     11 | Cleanup and optimization | Debloat and optimize Windows (asks first)            |
|     12 | Automation               | Schedule weekly and monthly maintenance tasks        |
|     13 | All                      | Execute all setup steps (asks first)                 |
|      0 | Exit                     | Exit                                                 |

Steps 4, 5, and 11 write logs to the `logs/` folder in the repository. Step 3 writes its update log
to `C:\<ComputerName>_<date>_MSUpdates.log`.

### Debloat and optimize

Step 11 asks for confirmation, then removes the apps in `debloat_list.txt` for every user and
de-provisions them so they do not return for new profiles. It also removes News, Weather, consumer
Teams, the Gaming app, and Copilot, uninstalls OneDrive and blocks it by policy, lowers telemetry,
hides Start and lock screen suggestions, disables Recall and Game DVR, turns on file extensions,
hidden files, long paths, and Developer Mode, disables ten optional services, and picks a power
plan based on whether the machine has a battery.

It never touches Windows Defender, Windows Update, the firewall, WMI, the event log, or the print
spooler.

### Scheduled maintenance

Step 12 copies `scripts/win11-maintenance.ps1` to `C:\windows-setup` and registers two tasks under
`\windows-setup\` in Task Scheduler. Both run as SYSTEM.

* **Weekly**, Sunday at 2:00, reapplies the privacy tweaks, service settings, and context menu
  changes.
* **Monthly**, every fourth Sunday at 3:00, does the same and also reapplies the OneDrive block.

Logs go to `C:\windows-setup\logs`. Remove the tasks in Task Scheduler if you no longer want them.

## Project structure

```text
.
├── win11-setup.ps1          # Entry point and menu
├── win11-functions.ps1      # One function per setup step, plus helpers
├── scripts/
│   └── win11-maintenance.ps1  # Standalone tweaks run by Task Scheduler
├── winget_install.txt       # Packages to install
├── winget_uninstall.txt     # Packages to uninstall
├── debloat_list.txt         # Built-in apps to remove
├── configs/                 # Terminal, Oh My Posh, and Git configs
├── fonts/FiraCode/          # Offline Nerd Font files
├── wallpapers/              # Desktop wallpapers
├── images/                  # README images
├── FUNCTIONALITY.md         # How the code works
└── LICENSE
```

## Security considerations

* Review every script before running it. The menu needs administrator rights and changes HKLM,
  services, scheduled tasks, and installed apps.
* The execution policy change applies only to your user and only allows unsigned local scripts.
* Step 11 lowers telemetry and disables tracking services. It leaves every security service alone.
* Step 12 registers tasks that run as SYSTEM. Keep `C:\windows-setup` writable only by
  administrators, because anyone who can edit the copied script can run code as SYSTEM.
* No credentials are stored. Set your Git name and email by hand after step 10.

## Testing

There are no automated tests. Lint the scripts with PSScriptAnalyzer.

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path . -Recurse
```

Test full runs in a throwaway Windows 11 VM before using them on a real machine.

## Troubleshooting

| Problem                                           | Fix                                                         |
| :------------------------------------------------ | :---------------------------------------------------------- |
| `running scripts is disabled on this system`      | Run the `Set-ExecutionPolicy` command from the quick start. |
| The script says it needs administrator privileges | Reopen PowerShell with **Run as administrator**.            |
| Windows Terminal says it cannot find the font     | Run step 7, then step 8 again.                              |
| The rename does not show up                       | Restart Windows.                                            |
| A package was not installed                       | Check `logs\winget_install.log` for the winget output.      |

## Roadmap

* Install winget itself on machines where it is missing.
* Reapply per user tweaks from the maintenance task for the signed in user, not only SYSTEM.

## License

Released under the [PolyForm Small Business License 1.0.0](LICENSE). It is free for small
businesses, individuals, and nonprofits. Larger organizations need a commercial license from
SGT7 LLC.

## Author

Built by sgt7 LLC.
