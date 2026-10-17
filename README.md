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

## Tests

```
python -m pytest              # config validator (fast, no game needed)
python -m pytest -m runtime   # runtime harness: parses the game's Launch.log for Astartes_* PASS/FAIL lines
```

Spec-driven classes: edit `tests/data/class_trees.json`, run `python -I tools/gen_class_config.py`, run the
tests, build. Never hand-edit `XComClassData.ini` or the generated block in `XComGame.int`.

In-game dev commands (console):

| Command | Does |
|---|---|
| `Astartes_DevSquad [ranks]` | One fully promoted soldier of every Marine class, best gear |
| `Astartes_ListClasses` | Logs the registered classes and rank counts |
| `Astartes_Geneseed [n]` | Logs (or sets) the Chapter geneseed pool |
| `Astartes_Redress` | Re-rolls every barracks soldier's look through the Marine generator |
| `Astartes_Factions` | Logs which faction owns each continent and whether its mod is loaded |
| `Astartes_AssignFactions` | (Re)deals factions to continents |
| `Astartes_SetContinentFaction <Continent_X> <Faction>` | Pins a continent to Orks / Chaos / Tyranids |

Each logs `PASS`/`FAIL`; `pytest -m runtime` turns those into test results.

## Conventions

- Prefer config (`.ini`) and Highlander event hooks over class overrides.
- Third-party art mods are required Workshop dependencies, never bundled assets.
- Localization files are UTF-8 in the repo; the build converts them to UTF-16.
- Keep features modular so phases can ship independently (see `docs/design.md` §13).
