# XCOM 2: Warhammer 40K Overhaul

A total-conversion mod for **XCOM 2: War of the Chosen**. The player commands a Space Marine Chapter
liberating a cluster of star systems from Orks, Tyranids and Chaos, with Eldar raiders as a wildcard.

Mod identifier: `Astartes` (ModBuddy project `Astartes/`). Requires the
[X2WOTCCommunityHighlander](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander).

## Layout

| Path | What |
|---|---|
| `Astartes/` | The mod itself: `Config/`, `Localization/`, `Content/`, `Src/Astartes/Classes/`. |
| `Astartes.XCOM_sln` | ModBuddy solution. Open this in ModBuddy if you prefer the IDE. |
| `.scripts/build.ps1` | Build entry point (uses [X2ModBuildCommon](https://github.com/X2CommunityCore/X2ModBuildCommon), vendored in `.scripts/X2ModBuildCommon/`). |
| `build.cmd` | One-click command-line build: `build.cmd` or `build.cmd debug`. |
| `.vscode/` | VS Code build tasks (Ctrl+Shift+B). |
| `docs/design.md` | The design document. Read this first. |
| `docs/mod-inventory.md` | Inventory of the Workshop mods used as art dependencies and technique references. |

## Building

Prerequisites: XCOM 2 WotC, the *XCOM 2 War of the Chosen SDK* (Steam > Tools), and a Workshop
subscription to the Community Highlander (the build compiles against its source).

```
build.cmd            # default configuration
build.cmd debug      # -debug script compile
```

Paths to the SDK and game are hard-coded in `build.cmd` and `.vscode/settings.json`; adjust if your
Steam library is elsewhere. The build copies the mod into `XCom2-WarOfTheChosen/XComGame/Mods/Astartes`,
where the Alternative Mod Launcher picks it up.

`BuildCache/` is created by the build system and is safe to delete at any time.

## Playtesting with cheats

In AML, enable the `-allowConsole` quick-toggle argument and launch. Press `~` in game. From a fresh campaign:

```
LevelUpBarracks 7        # every soldier fully promoted
GiveResource Supplies 5000
GiveTech <TechName>      # unlock gear
PowerUp                  # tactical: god mode
```

The full list we use, plus the mod's own dev commands, is in `docs/design.md` §15.1.

## Conventions

- Prefer config (`.ini`) and Highlander event hooks over class overrides.
- Third-party art mods are required Workshop dependencies, never bundled assets.
- Localization files are UTF-8 in the repo; the build converts them to UTF-16.
- Keep features modular so phases can ship independently (see `docs/design.md` §13).
