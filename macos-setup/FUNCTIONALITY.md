# macOS Setup Functionality

This document is a walkthrough of how the code works. See the [README](README.md) for how to run it.

## System overview

The project turns a fresh or clean reinstalled Mac into a hardened developer workstation. It
installs macOS updates, renames the machine, installs the Xcode Command Line Tools, checks System
Integrity Protection, enables the application firewall, installs Homebrew and mise with their tool
lists, configures DNS, and sets up the font, shell prompt, Git, Neovim, and EditorConfig.

Two terms used below:

* *SIP* (System Integrity Protection) is the macOS feature that blocks changes to protected system
  files, even by root.
* *mise* is a tool version manager. It installs language runtimes and command line tools and pins
  their versions.

The scripts are written for zsh, the default macOS shell, not Bash. Everything is driven from an
interactive menu. Each option runs one step, and option 17 runs every step in order. After each
choice the script waits for Enter.

## How the pieces connect

`macos-setup.sh` is the file you run. It finds its own directory, sources `macos-functions.sh`,
and loops on the menu. Every choice is logged to a timestamped `setup_log_*.log` file. Option 11
runs `macos-network.sh` as a separate root process instead of calling a function.

```text
macos-setup.sh (menu loop, writes setup_log_<timestamp>.log)
  ├── sources macos-functions.sh
  │     ├── softwareupdate, scutil, xcode-select, csrutil, socketfilterfw
  │     ├── prompt_for_security_risk ──> curl | sh for Homebrew, mise, Oh My Zsh
  │     ├── brew install        <-- brew_install_list.txt
  │     ├── mise install, use   <-- mise_install_list.txt
  │     ├── curl, unzip         <-- Nerd Fonts release on GitHub
  │     ├── cp, git config      <-- configs/.gitignore_global
  │     └── cp                  <-- configs/nvim/init.lua, configs/.editorconfig
  └── sudo zsh macos-network.sh (option 11)
        └── networksetup, dscacheutil, mDNSResponder
```

Shared state between the two files is limited to `SIP_DISABLED`. `check_sip_status` sets it, and
the exit option reads it to decide whether to print a warning.

## File by file walkthrough

Read the files in this order.

### macos-setup.sh

**Purpose:** Entry point. Prints the grouped menu, logs each choice, and calls the matching
function or the network script.

**Depends on:** `macos-functions.sh` and `macos-network.sh`.

`log_execution` appends a timestamped line to the log file in the current directory. For option 17
it asks once whether remote install scripts may run, then passes that answer to the three functions
that use `curl | sh` so they do not prompt again.

### macos-functions.sh

**Purpose:** Holds one function per menu step plus two helpers, `prompt_for_security_risk` and
`display_sip_warning_if_needed`.

**Depends on:** macOS system tools, `curl`, `unzip`, `git`, Homebrew, mise, and the data files in
the repository.

### macos-network.sh

**Purpose:** A standalone interactive DNS utility. It lists the network services that have an IP
address, shows their current DNS servers, and sets new ones from presets or custom input.

**Depends on:** Root privileges, `networksetup`, `dscacheutil`, and `killall`. Runs on its own with
`sudo zsh macos-network.sh`.

It uses `setopt NO_UNSET` so a misspelled variable stops the script instead of changing DNS on the
wrong interface. A small state machine in `main` moves between interface selection, DNS selection,
and apply, so the user can go back a step.

### brew_install_list.txt and mise_install_list.txt

**Purpose:** Tool lists, one name per line. Homebrew installs network, security, and cloud command
line tools. mise installs cloud, Kubernetes, infrastructure as code, and AI command line tools at
their latest versions.

**Depends on:** Nothing.

### configs/

**Purpose:** `nvim/init.lua` is a Neovim config that fetches and applies the Catppuccin Macchiato
theme with `vim.pack`. `.editorconfig` holds editor defaults for the home directory.
`.gitignore_global` holds global Git ignore patterns.

**Depends on:** Neovim with `vim.pack` support for `init.lua`.

## Function entries

Functions in `macos-functions.sh` take no arguments unless stated.

### update_patch_mac

* **Does:** Installs every available macOS update and restarts if one requires it.
* **Inputs:** None.
* **Outputs:** A patched system.
* **Why it exists:** Later steps should run on current software.
* **Side effects:** Network calls, system updates, and a possible automatic restart.

### rename_mac

* **Does:** Asks for a name and sets the HostName, LocalHostName, and ComputerName to it.
* **Inputs:** The name typed by the user.
* **Outputs:** The three new names printed on screen.
* **Why it exists:** macOS uses each name in a different place: DNS, Bonjour, and Finder.
* **Side effects:** System configuration change through `sudo`.

### install_xcode_clt

* **Does:** Starts the Xcode Command Line Tools installer.
* **Inputs:** None.
* **Outputs:** A macOS install dialog.
* **Why it exists:** Git, compilers, and Homebrew need these tools.
* **Side effects:** Opens a GUI installer and returns before it finishes. The success message
  prints right away.

### check_sip_status

* **Does:** Reads `csrutil status` and sets `SIP_DISABLED`.
* **Inputs:** None.
* **Outputs:** A status line on screen and the shared `SIP_DISABLED` flag.
* **Why it exists:** A disabled SIP weakens the whole system and should be flagged.
* **Side effects:** Sets a global variable.

### enable_firewall

* **Does:** Turns on the application firewall and stealth mode.
* **Inputs:** None.
* **Outputs:** An active firewall that ignores probes such as ping.
* **Why it exists:** The firewall is off by default on macOS.
* **Side effects:** System firewall changes through `sudo`.

### disable_auto_allow

* **Does:** Turns off automatic firewall approval for built-in and downloaded signed software.
* **Inputs:** None.
* **Outputs:** A firewall that asks before letting signed apps accept connections.
* **Why it exists:** Makes every listening app an explicit decision.
* **Side effects:** System firewall changes. Apps will prompt the first time they listen.

### display_sip_warning_if_needed

* **Does:** Prints a boxed warning with recovery instructions if `SIP_DISABLED` is true.
* **Inputs:** `SIP_DISABLED`.
* **Outputs:** A warning on screen.
* **Why it exists:** Called on exit so the warning is the last thing the user sees.
* **Side effects:** None.

### install_homebrew

* **Does:** Runs the official Homebrew installer through `prompt_for_security_risk`, then adds the
  `brew shellenv` line to the zsh profile and loads it.
* **Inputs:** An optional `y` or `n` from option 17.
* **Outputs:** Homebrew installed under `/opt/homebrew`.
* **Why it exists:** Homebrew installs the command line tools in the next step.
* **Side effects:** Network call, runs a remote script, and appends to a hardcoded
  `/Users/steven/.zprofile` path.

### install_homebrew_packages

* **Does:** Installs each formula in `brew_install_list.txt`, then installs the GKE auth plugin if
  `gcloud` is present.
* **Inputs:** `brew_install_list.txt`, read from the current working directory.
* **Outputs:** Installed formulae.
* **Why it exists:** Keeps the tool list in data instead of code.
* **Side effects:** Network calls and file writes. If Homebrew is missing it calls `exit 1`, which
  ends the whole menu script.

### install_mise

* **Does:** Runs the mise installer through `prompt_for_security_risk` if mise is missing, then
  adds its activation line to `~/.zshrc` and sources that file.
* **Inputs:** An optional `y` or `n` from option 17.
* **Outputs:** mise installed under `~/.local/bin`.
* **Why it exists:** mise installs and pins the tools in the next step.
* **Side effects:** Network call, runs a remote script, and appends to `~/.zshrc`.

### install_mise_packages

* **Does:** Installs each tool in `mise_install_list.txt` at `@latest` and sets it as the global
  version.
* **Inputs:** `mise_install_list.txt`, read from the current working directory.
* **Outputs:** Installed tools and an updated global mise config.
* **Why it exists:** Projects can still pin their own versions in `.mise.toml`.
* **Side effects:** Network calls and file writes. Returns 1 if mise is missing.

### configure_key_repeat

* **Does:** Sets the fastest key repeat rate and a short initial delay.
* **Inputs:** None.
* **Outputs:** Changed global user defaults.
* **Why it exists:** Speeds up editing in the terminal.
* **Side effects:** User preference writes. Takes effect after logging out and back in.

### download_install_font

* **Does:** Downloads the DroidSansMono Nerd Font v3.4.0 zip into `./fonttmp`, copies the `.otf`
  files into `~/Library/Fonts`, and removes the temporary folder.
* **Inputs:** A pinned GitHub release URL.
* **Outputs:** Installed user fonts.
* **Why it exists:** Powerlevel10k draws icons with Nerd Font glyphs.
* **Side effects:** Network call and file writes. It returns to the starting directory afterwards.

### install_oh_my_zsh_powerlevel10k

* **Does:** Runs the Oh My Zsh installer through `prompt_for_security_risk`, clones Powerlevel10k,
  backs up `~/.zshrc`, and switches the theme in it to Powerlevel10k.
* **Inputs:** An optional `y` or `n` from option 17.
* **Outputs:** Oh My Zsh, the Powerlevel10k theme, `~/.zshrc.orig`, and `~/.zshrc.bak`.
* **Why it exists:** Gives the shell a fast, informative prompt.
* **Side effects:** Network calls, runs a remote script, and edits `~/.zshrc`.

### configure_git

* **Does:** Copies `configs/.gitignore_global` to the home directory and sets global Git defaults.
* **Inputs:** `configs/.gitignore_global`, relative to the current directory.
* **Outputs:** `~/.gitignore_global` and changes to `~/.gitconfig`.
* **Why it exists:** Gives every new repository the same defaults.
* **Side effects:** User file writes. Name and email are left for the user.

### configure_themes

* **Does:** Copies `configs/nvim/init.lua` to `~/.config/nvim` and `configs/.editorconfig` to the
  home directory, using the script's own directory to find them.
* **Inputs:** `$script_dir` from `macos-setup.sh`.
* **Outputs:** A Neovim config and a home level `.editorconfig`.
* **Why it exists:** Applies the Catppuccin Macchiato theme and shared editor defaults.
* **Side effects:** Overwrites any existing `init.lua` and `~/.editorconfig`.

### prompt_for_security_risk

* **Does:** Shows a remote install command and asks before running it with `eval`. A `y` or `n`
  passed as the second argument skips the question.
* **Inputs:** The command string and an optional pre-approved answer.
* **Outputs:** Returns 0 if the command ran and 1 if it was skipped.
* **Why it exists:** Every `curl | sh` install goes through one consent gate.
* **Side effects:** Runs the given command when approved.

### macos-network.sh functions

* **Does:** `detect_active_interfaces` lists enabled network services that have an IP address.
  `menu_select_interfaces`, `menu_select_dns`, and `menu_custom_dns` collect choices and validate
  numbers and IP addresses. `apply_dns` sets the servers and flushes the DNS cache. `main` ties
  them together with a small state machine.
* **Inputs:** Keyboard input and the output of `networksetup`.
* **Outputs:** New DNS servers on the chosen services, or a reset to DHCP.
* **Why it exists:** Applies Cloudflare, Google, Quad9, or custom DNS in one pass instead of
  through System Settings for each interface.
* **Side effects:** Network configuration changes and a DNS cache flush. Requires root.

## Known limitations or sharp edges

* **Hardcoded home path.** `install_homebrew` writes to `/Users/steven/.zprofile` instead of
  `$HOME/.zprofile`, so it fails or writes to the wrong place for any other user.
* **Apple Silicon only.** The Homebrew shellenv line assumes `/opt/homebrew`. Intel Macs use
  `/usr/local`.
* **Execute All prompt syntax.** Option 17 uses Bash style `read -p ... -n 1 -r`. In zsh, `-p`
  reads from a coprocess, so the approval prompt is likely to fail. The zsh form used elsewhere is
  `read "reply?Prompt "`.
* **Network script not executable.** `macos-network.sh` is stored without the execute bit. Option
  11 then prints an error, and option 17 skips DNS without saying so, unless the README `chmod`
  step was run.
* **Exit inside a sourced function.** `install_homebrew_packages` calls `exit 1`, which ends the
  whole menu instead of returning.
* **Installer does not wait.** `install_xcode_clt` returns before the GUI install finishes.
* **Oh My Zsh starts a new shell.** By default its installer opens a new zsh session at the end,
  and the setup script only continues after you exit that shell.
* **Working directory matters.** The tool lists, `configs/.gitignore_global`, the font temp folder,
  and the log file all use the current directory. Only `configure_themes` uses `$script_dir`.
* **No strict mode in the menu.** Only `macos-network.sh` sets `NO_UNSET`. The menu and functions
  keep going after errors.
* **No linting in CI.** ShellCheck does not support zsh. The README suggests `zsh -n` for a syntax
  check.

## Change log

| Date       | Summary                                                                                  |
| :--------- | :--------------------------------------------------------------------------------------- |
| 2026-11-01 | Added FUNCTIONALITY.md. Renamed scripts to kebab-case and `img/` to `images/`.           |
