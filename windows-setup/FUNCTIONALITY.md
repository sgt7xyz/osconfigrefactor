# Windows 11 Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh Windows 11 Pro install into a developer friendly, privacy conscious
workstation. It installs tools with winget, patches Windows, sets up Windows Terminal with Oh My
Posh and mise, installs fonts and wallpapers, and sets Git defaults. An opt-in step removes
bloatware and applies privacy and performance tweaks. Another step schedules tasks that reapply
those tweaks after Windows updates undo them.

Everything is driven from an interactive numbered menu. Option 13 runs the install steps in order
but skips uninstalling packages (5), debloating (11), and scheduling maintenance (12).

Terms used below:

* *winget* is the Windows Package Manager command line tool.
* *Appx package* is the format of Microsoft Store and built-in apps. *De-provisioning* removes an
  Appx package from the Windows image so new user profiles do not get it.
* *HKCU* and *HKLM* are the per user and machine wide registry hives.
* *Dot-sourcing* (`. file.ps1`) runs a script in the caller's scope, so its functions stay defined.

## How the pieces connect

`win11-setup.ps1` is the file you run. It resolves its own folder, dot-sources
`win11-functions.ps1`, exits if the session is not elevated, and loops on the menu. Most functions
get the repository folder through a `-ScriptDir` parameter so data files are found from any
working directory.

```text
win11-setup.ps1 (menu loop, admin check)
  └── dot-sources win11-functions.ps1
        ├── Install-* functions    <-- winget_install.txt, winget_uninstall.txt, configs/,
        │                              fonts/, wallpapers/
        ├── Invoke-DebloatAndOptimize (option 11)
        │     ├── Remove-Bloatware          <-- debloat_list.txt, calls Remove-OneDrive
        │     ├── Remove-AdditionalBloatware
        │     ├── Optimize-WindowsPrivacyPerformance
        │     ├── Disable-UnneededServices
        │     ├── Optimize-ContextMenu
        │     └── Set-PowerPlan
        ├── Schedule-MaintenanceTask (option 12)
        │     └── copies scripts/win11-maintenance.ps1 to C:\windows-setup, registers 2 tasks
        └── Invoke-All-Install-Tasks (option 13)

Task Scheduler (SYSTEM) ──> C:\windows-setup\win11-maintenance.ps1 -Mode Weekly | Monthly
```

Logs from steps 4, 5, and 11 go to `logs/` in the repository. The maintenance script writes a
timestamped log per run.

## File by file walkthrough

Read the files in this order.

### win11-setup.ps1

**Purpose:** Entry point. Checks for the local Administrators group, prints the grouped menu, and
calls one function per choice.

**Depends on:** `win11-functions.ps1`.

The admin check looks for the well known Administrators SID `S-1-5-32-544` in the current token.
After each choice the script waits for Enter before showing the menu again.

### win11-functions.ps1

**Purpose:** All setup functions, in four sections: installation (options 1 to 10), font helpers,
debloat and optimization helpers, and orchestrators (options 11 to 13).

**Depends on:** winget, the PSWindowsUpdate module from the PowerShell Gallery, Git, the registry,
the Services and Task Scheduler cmdlets, and the data files in the repository.

When the file is loaded it also compiles a small `Win32FontHelper.NativeMethods` type that calls
`AddFontResource` and `SendMessageTimeout`, because copying a font file is not enough for apps to
find it by family name.

### scripts/win11-maintenance.ps1

**Purpose:** Standalone script that Task Scheduler runs as SYSTEM to reapply tweaks.

**Depends on:** Nothing outside Windows. It carries its own copies of
`Optimize-WindowsPrivacyPerformance`, `Disable-UnneededServices`, `Optimize-ContextMenu`, and a
policy only version of `Remove-OneDrive`.

It takes `-Mode Weekly` or `-Mode Monthly` and `-LogDir`. Weekly runs the first three functions.
Monthly adds the OneDrive policy check. It never prompts.

### winget_install.txt, winget_uninstall.txt, and debloat_list.txt

**Purpose:** Data lists, one entry per line, `#` for comments, grouped by category. The winget
lists hold package IDs. The debloat list holds Appx names with wildcards, plus the literal line
`OneDrive`, which is handled by its own function.

**Depends on:** Nothing.

### configs/, fonts/, and wallpapers/

**Purpose:** `configs/Terminal/settings.json` is copied over the Windows Terminal settings.
`configs/OhMyPosh/catppuccin_macchiato.omp.json` is the prompt theme.
`configs/Git/.gitignore_global` is the global Git ignore file. `fonts/FiraCode/` is an offline copy
of the Nerd Font, and `wallpapers/` holds the desktop images.

**Depends on:** Nothing.

## Function entries

### Rename-WindowsPC

* **Does:** Shows the current name, asks for confirmation unless `-AutoConfirm` is set, then
  renames the computer.
* **Inputs:** `-AutoConfirm` switch and the typed name.
* **Outputs:** A new computer name after the next restart.
* **Why it exists:** Gives a new machine a readable network name.
* **Side effects:** Changes the computer name.

### Install-Winget

* **Does:** Returns if `winget` exists, otherwise tries to install App Installer with winget.
* **Inputs:** None.
* **Outputs:** A status message.
* **Why it exists:** Every package step needs winget.
* **Side effects:** On failure it prints an error and returns to the menu.

### Update-Patch-Windows

* **Does:** Installs the NuGet provider and PSWindowsUpdate, registers Microsoft Update, and
  installs all updates without rebooting.
* **Inputs:** None.
* **Outputs:** `C:\<ComputerName>_<date>_MSUpdates.log`.
* **Why it exists:** Patches the system before anything else is installed.
* **Side effects:** Network calls, module installs, and Windows updates. A reboot is still needed.

### Install-WingetPackages

* **Does:** Reads `winget_install.txt`, skips comments, blanks, and packages winget already lists,
  and installs the rest. Success is read from winget's output text.
* **Inputs:** `-ScriptDir`.
* **Outputs:** `logs/winget_install.log` with one line per package.
* **Why it exists:** Keeps the package list in data instead of code.
* **Side effects:** Network calls and app installs. Returns early if winget or the list is missing.

### Uninstall-WingetPackages

* **Does:** Reads `winget_uninstall.txt` and uninstalls each package, logging uninstalled, skipped,
  or failed.
* **Inputs:** `-ScriptDir`.
* **Outputs:** `logs/winget_uninstall.log`.
* **Why it exists:** Removes software you do not want, from a list.
* **Side effects:** App removals. Returns early if winget or the list is missing.

### Install-Chrome

* **Does:** Downloads the Chrome installer to `%TEMP%`, runs it silently, and deletes it.
* **Inputs:** None.
* **Outputs:** Google Chrome installed.
* **Why it exists:** Installs Chrome without the Store or a browser.
* **Side effects:** Network call over HTTPS and an elevated installer run.

### Install-SystemFont and Test-FontInstalled

* **Does:** `Install-SystemFont` copies one font file into `C:\Windows\Fonts`, reads its family
  name, writes the registry entry, and notifies running apps. `Test-FontInstalled` checks the
  registry for a family name.
* **Inputs:** `-FontFilePath` or `-FontFamilyName`.
* **Outputs:** The registered family name, or `$true` and `$false`.
* **Why it exists:** Windows Terminal looks fonts up by family name and fails to start if the font
  is only copied.
* **Side effects:** File copy, HKLM write, and a broadcast message to all windows.

### Install-Fonts

* **Does:** Asks the GitHub API for the latest Nerd Fonts release, downloads `FiraCode.zip`,
  stores the files in `fonts/FiraCode/`, and registers each one with `Install-SystemFont`.
* **Inputs:** `-ScriptDir`.
* **Outputs:** Installed fonts and a refreshed offline copy in the repository.
* **Why it exists:** The prompt and Terminal settings use Fira Code Nerd Font glyphs.
* **Side effects:** Network calls, file writes in the repository and `C:\Windows\Fonts`, and HKLM
  writes. The temporary download folder is always removed.

### Install-OhMyPosh

* **Does:** Installs Windows Terminal and Oh My Posh with winget, updates PSReadLine, makes sure
  the Nerd Font is registered, copies the Catppuccin theme to `~\.oh-my-posh\themes`, writes a mise
  and Oh My Posh block into both PowerShell profiles, and copies the Terminal settings.
* **Inputs:** `-ScriptDir`.
* **Outputs:** Two profile files, a theme file, and Terminal `settings.json`.
* **Why it exists:** Oh My Posh needs PSReadLine 2.1 or newer, and Terminal will not start if its
  configured font is missing, so the order matters.
* **Side effects:** App installs, module install, and file writes. Earlier mise and Oh My Posh lines
  in the profiles are replaced, and the Terminal settings file is overwritten.

### Install-Wallpapers

* **Does:** Copies `wallpapers/` to `Pictures\Wallpapers` and sets `01.png` as the desktop.
* **Inputs:** `-ScriptDir`.
* **Outputs:** Image files and a new desktop background.
* **Why it exists:** Applies the project's look.
* **Side effects:** File writes and a user setting change through `SystemParametersInfo`.

### Install-Git-Config

* **Does:** Copies `configs/Git/.gitignore_global` to the profile folder, sets global Git defaults
  with VS Code as the editor, and prints the config.
* **Inputs:** `-ScriptDir`.
* **Outputs:** `~\.gitignore_global` and changes to `~\.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

### Remove-OneDrive

* **Does:** Stops OneDrive, runs its own uninstaller, sets the `DisableFileSyncNGSC` policy,
  removes the reinstall entry from the Default user hive, deletes its scheduled tasks, and unpins it
  from Explorer.
* **Inputs:** None.
* **Outputs:** OneDrive removed and blocked.
* **Why it exists:** OneDrive is a Win32 app, not Appx, and Windows reinstalls it unless it is
  blocked by policy.
* **Side effects:** App removal, HKLM and Default hive edits, and task removal. Synced files on
  disk are left alone.

### Remove-Bloatware

* **Does:** For each entry in `debloat_list.txt`, removes matching Appx packages for all users and
  de-provisions them, then sets the CloudContent policies that stop consumer app suggestions.
* **Inputs:** `-ScriptDir`.
* **Outputs:** `logs/debloat.log`.
* **Why it exists:** Removes built-in apps so they do not return for new profiles or after feature
  updates.
* **Side effects:** App removal and HKLM policy writes. Calls `Remove-OneDrive` for that entry.

### Remove-AdditionalBloatware

* **Does:** Removes and de-provisions News, Weather, consumer Teams, the Gaming app, and Copilot.
* **Inputs:** None.
* **Outputs:** `%TEMP%\logs\additional_debloat.log`.
* **Why it exists:** Covers apps that may be missing from a customized `debloat_list.txt`.
* **Side effects:** App removal.

### Optimize-WindowsPrivacyPerformance

* **Does:** Sets telemetry to its lowest allowed level, turns off web search, suggestions, lock
  screen ads, Widgets and Chat icons, Game DVR, Recall, Edge reporting, and activity history, and
  turns on file extensions, hidden files, long paths, Developer Mode, and Storage Sense.
* **Inputs:** None.
* **Outputs:** HKCU and HKLM values, and Recall removed if it was enabled.
* **Why it exists:** Applies the privacy and developer defaults in one pass.
* **Side effects:** Registry writes. Safe to run again.

### Disable-UnneededServices

* **Does:** Stops and disables ten optional services, such as `DiagTrack`, `RetailDemo`, `Fax`,
  the Xbox services, and `WerSvc`, skipping any that do not exist.
* **Inputs:** None.
* **Outputs:** Disabled services.
* **Why it exists:** Cuts telemetry and background work. Security and update services are never
  listed.
* **Side effects:** Service changes, reversible in the Services app.

### Optimize-ContextMenu

* **Does:** Blocks the **Share** shell extension, removes OneDrive entries from **Send to**, and
  sets one Explorer value.
* **Inputs:** None.
* **Outputs:** A shorter Explorer context menu.
* **Why it exists:** Removes menu items that are safe to drop.
* **Side effects:** HKCU writes and file deletes in the SendTo folder.

### Set-PowerPlan

* **Does:** Uses Balanced with hibernation on when a battery is found, and High performance with
  hibernation off otherwise.
* **Inputs:** None.
* **Outputs:** An active power plan.
* **Why it exists:** Laptops and desktops need different defaults.
* **Side effects:** Power settings change.

### Invoke-DebloatAndOptimize

* **Does:** Lists what will and will not change, asks for confirmation, then runs the six debloat
  and optimization helpers in order.
* **Inputs:** `-ScriptDir`.
* **Outputs:** All outputs of those helpers.
* **Why it exists:** Keeps the most invasive changes behind one explicit, opt-in choice.
* **Side effects:** Those of the helpers.

### Schedule-MaintenanceTask

* **Does:** Copies `scripts/win11-maintenance.ps1` to `C:\windows-setup`, creates a `logs` folder,
  and registers weekly and monthly tasks under `\windows-setup\` that run it as SYSTEM.
* **Inputs:** None. It finds the source script from the path of the calling script.
* **Outputs:** Two scheduled tasks and a copied script.
* **Why it exists:** Windows updates can turn tweaks and services back on.
* **Side effects:** File copy and task registration with highest privileges.

### Invoke-All-Install-Tasks

* **Does:** Asks for confirmation, then runs options 1 to 4 and 6 to 10, passing `-AutoConfirm` to
  the rename.
* **Inputs:** `-ScriptDir`.
* **Outputs:** All outputs of those steps.
* **Why it exists:** Runs a full install without picking each step.
* **Side effects:** Those of the steps.

## Known limitations or sharp edges

* **winget cannot install itself.** `Install-Winget` runs `winget` to install App Installer, so
  on a machine without winget it fails. Install App Installer from the Microsoft Store first.
* **Errors return to the menu.** Functions return on errors, so in option 13 later steps still run
  after an earlier one fails.
* **Maintenance runs as SYSTEM.** HKCU tweaks in the maintenance script apply to the SYSTEM
  account, not to the signed in user. Only HKLM tweaks and services are kept up for users.
* **Monthly is approximate.** The monthly task runs every fourth Sunday, because Task Scheduler
  has no "first Sunday" weekly trigger in these cmdlets.
* **Mismatched comment.** In `Optimize-ContextMenu`, the "Open with Cloud Storage" comment sits
  above an `AltStartButtonBalloonTip` value that is unrelated to it.
* **No rollback.** Registry and service changes are reversible by hand, but removed apps must be
  reinstalled from the Store or winget.
* **Current user only.** HKCU tweaks apply to the account that ran the menu.

## Change log

| Date       | Summary                                                                           |
| :--------- | :-------------------------------------------------------------------------------- |
| 2026-11-01 | Fixed the Chrome download URL, the Git excludes path, and exits inside functions. |
| 2026-11-01 | Rewrote this file to the project template and renamed scripts to kebab-case.      |
| 2024-11-01 | Added scheduled maintenance tasks with weekly and monthly modes.                  |
| 2024-10-31 | Expanded privacy tweaks to Edge, Cortana, Explorer, and Search.                   |
| 2024-10-30 | Reorganized the functions file and aligned menu and function numbers.             |
| 2024-10-29 | Added the first debloating and optimization implementation.                       |
