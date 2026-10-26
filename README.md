# NixOS config

The flake-based NixOS configuration of my computers. A classmate recommended NixOS, and the declarative approach suits me because I work on three machines and want them as identical as possible. I'm still experimenting and testing, so far happily.

The detailed guide ([GUIDE.md](GUIDE.md)), the working rules ([RULES.md](RULES.md)) and open items ([TODO.md](TODO.md)) are in Czech.

## What it sets up

- **Base for every machine** (`modules/core`): flakes, `nh` with weekly cleanup of old generations, unfree packages, Prague time zone with English system language and Czech formats and keyboard, user `toust` with zsh (syntax highlighting, autosuggestions, powerlevel10k, Meslo Nerd Font), Tailscale with shields up and no routes, exit node or SSH.
- **Desktop:** KDE Plasma 6 with SDDM, PipeWire, NetworkManager, printing.
- **Apps:** Firefox, Kate, Signal, Spotify, Discord.
- **Development:** git, Node.js 22, `psql`; Android SDK, `adb` and Java 21 for Capacitor apps.
- **AI tools:** Cursor (from nixos-unstable), Google Antigravity, `wl-clipboard`, and `nix-ld` with `~/.local/bin` on PATH so the natively installed Claude Code runs.
- **Gaming:** Steam with Proton-GE, GameMode, Heroic, CurseForge.
- **Nextcloud client:** a module option `nextcloud.folders` creates the synced folders and desktop links (`Projects`, `School`) and a shared sync-exclude list.
- **School:** Oxygen XML Editor.
- **Own packages** in `pkgs/` for CurseForge and Oxygen XML Editor, which are not in nixpkgs.
- **Host `desktop`:** systemd-boot, NVIDIA RTX 3080 Ti (open driver), a fwupd fix for a SteelSeries headset.

## Requirements

- NixOS with flakes (nixpkgs `nixos-26.05`, plus `nixos-unstable` for selected packages)
- SSH access to the private flake input `work` (`TousTarm/nixos-work`); without it the flake does not evaluate.
- The repo cloned to `~/NixOS`: the shell aliases and `nh` point to `/home/toust/NixOS`, and the user name `toust` is hardcoded.

## Usage

First switch on a new machine (the aliases do not exist yet):

```bash
git clone <repo-url> ~/NixOS
sudo nixos-rebuild switch --flake ~/NixOS#desktop
```

After that, from the shell:

| Command | What it does |
| --- | --- |
| `rebuild` | build and switch |
| `rebuild-boot` | build, switch after the next reboot |
| `rebuild-test` | build and switch until reboot, works with uncommitted changes |
| `update` | update `flake.lock` and switch |
| `generations` | list system generations |
| `nixdiff` | package changes between the last two generations |
| `nixcfg` | `cd ~/NixOS` |

`rebuild`, `rebuild-boot` and `update` refuse to run when `~/NixOS` has uncommitted changes, so every machine is built only from committed config. New files must be added with `git add` before a flake can see them.

A new machine gets its own folder in `hosts/` with its `hardware-configuration.nix` and an entry in `flake.nix` (see "Nový počítač" in GUIDE.md). Only `desktop` is defined so far.

## Tests

There are no tests. `nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath` checks that the configuration evaluates.

## Structure

```
flake.nix                 inputs (nixpkgs, nixpkgs-unstable, private `work`) and hosts (mkHost)
hosts/desktop/            hardware and host-specific settings, module selection
modules/core/             base imported by every host
modules/*.nix             optional modules (plasma, apps, dev, android, ai, gaming, nextcloud, personal, school)
pkgs/                     own packages (CurseForge, Oxygen XML Editor)
GUIDE.md, RULES.md, TODO.md
CLAUDE.md                 loads RULES.md for Claude Code
```

Built with the help of AI coding tools.
