# UT Millenium

A quick-play front end for **Unreal Tournament (1999, GOTY)**, built for players
who want a match *now*. It needs your own copy of the game: it ships no Epic
Games files and never changes your Steam install.

- A small portrait main menu (the original Tournament ladder artwork) with the
  UT menu music.
- **EASY / MEDIUM / HARD**: a random allowed game mode, a random map, and bots
  from random factions, each with its own random difficulty
  (Easy: Novice to Experienced, Medium: Skilled to Masterful, Hard: Inhuman and Godlike).
- One match in borderless fullscreen, then straight back to the menu.
- **ESC** pauses the match and shows the menu ("MATCH IN PROGRESS").
- Stats: winning streak, highest streak, K/D, wins, losses, kills, captures.
- **Casual Move Speed** (on by default: everybody moves 10% slower, dodges stay
  original) and **Max Bots** (fill the map to its maximum).
- Settings: brightness, FOV, frame-rate cap, mouse, volumes, key bindings,
  character, game modes, per-mode map lists, mutators, auto taunt.
- Mutators: **Chainsaw Zombies**, **Impact Hammer Zombies**, **One Man Army**.
- **ADD MAPS**: pick a folder of downloaded maps (zips too) and they join the pool.
- **Play Intro / Play Outro**: the original city intro and the
  Tournament-winner ending with your character.

## Install (players)

1. Right-click the downloaded zip, open Properties and tick **Unblock**. Then unzip it anywhere.
2. Run `UT Millenium Launcher` and confirm your Unreal Tournament folder (found automatically for Steam).
3. The launcher downloads the free OldUnreal 469e patch (101 MB, checksum
   verified) and builds a private `Game` folder next to itself.

`UT Millenium Launcher.cmd /setup` redoes the setup (for example after moving UT).

The launcher is a plain `.cmd` script rather than an exe. Windows 11 Smart
App Control blocks unsigned exes outright, while the OldUnreal game files are
digitally signed.

## Layout

| Folder | What |
|---|---|
| `UTMillenium/Classes` | UnrealScript source of the mod package |
| `UTMillenium/UTMillenium.int` | Mutator registrations |
| `Launcher/` | Windows launcher (`UT Millenium Launcher.cmd`); its PowerShell helpers (`ps/`) ship as `UT Millenium Data/Mod/*.txt` |
| `Tools/` | Build helper for compiling the package with the Linux UCC |

## Building

**Mod package (`UTMillenium.u`)**: put the `UTMillenium` folder in a 469e
install next to `System`, add `EditPackages=UTMillenium` to the
`[Editor.EditorEngine]` section, and run `ucc make`. On Linux,
`Tools/ucc_make_linux.py` runs the 469e `ucc-bin` and answers its v436
compatibility prompts. UT Millenium targets 469e only.

**Release folder**: `UT Millenium Launcher.cmd` plus a `UT Millenium Data` folder
with `README.txt` and `Mod/` (`UTMillenium.u`, `UTMillenium.int`, and the
`Launcher/ps/*.ps1` files renamed to `.txt`).

## Credits

- Idea and mod design: **Marcin Tomala**
- Mod programming: Claude (Anthropic)
- Unreal Tournament: Epic Games and Digital Extremes
- OldUnreal 469 patch: AnthraX, Higor, Buggie, Dots, Smirftsch and contributors

Unreal and Unreal Tournament are trademarks of Epic Games, Inc.
UT Millenium is a free fan project and isn't made or endorsed by Epic Games.
