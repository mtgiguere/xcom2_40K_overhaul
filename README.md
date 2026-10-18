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

See **Helpful testing console commands** at the end of this file.

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

## Credits and bundled libraries

- **XModBase** by xylthixlm (ability toolkit), bundled as designed: `Astartes/Src/XModBase_Core_3_0_0`,
  `XModBase_Interfaces`, `LW_Tuple`, and the `XMB*` helper classes in `Astartes/Src/Astartes/Classes`.
  Copies taken from the Workshop mods The Hive and Guardsmen_WotC; to be replaced by the XModBase Redux core.
- **X2ModBuildCommon** by the X2 Community Core team (build system), vendored in `.scripts/`.
- Art and enemy factions come from the Workshop mods listed in `docs/mod-inventory.md` as required dependencies.

- **Jedi Class Revised** (workshop 2031929512): the jump-arc visualization pattern (precomputed ballistic path + leap/flight/landing animations) that `X2Action_Astartes_JumpPack` is modelled on. Our implementation is independent code, but the jump *animations and ignition sound* are loaded from that mod's content when it is enabled (vanilla soldier climb/fall animations carry root motion and cannot be used). Jedi Class Revised must be enabled in the launcher for animated jumps; without it the Marine flies the arc unanimated. Its Jedi class is kept out of our promotion deck.

## Dressing the Marines

Generated Marines copy their armour parts from a character-pool soldier named in `MarineLookTemplates` (`Config/XComGame.ini`). Make one in the Character Pool wearing the Tacticus parts you want as the standard look (tintable pieces, standard pouches and seals, no power fist, no jump pack), save him, and list his full name. Several names give a random pick. Tints and the camo pattern still come from the Chapter livery; the Librarian hood is still applied on promotion. With no template found, the shipped `MarineLookParts` line is used; with neither, parts are picked at random from the packs.

To ship a look: `Astartes_ExportLook Arthur Ward` on the Avenger prints a `+MarineLookParts=(...)` line; paste it under `[Astartes.X2DownloadableContentInfo_Astartes]` in `Config/XComGame.ini`.

## Conventions

- Prefer config (`.ini`) and Highlander event hooks over class overrides.
- Third-party art mods are required Workshop dependencies, never bundled assets.
- Localization files are UTF-8 in the repo; the build converts them to UTF-16.
- Keep features modular so phases can ship independently (see `docs/design.md` §13).

## Helpful testing console commands

Setup: in AML tick the `-allowConsole` quick-toggle argument, launch, and press `~` (or `\`) in game.
Dev commands from this mod print their result on screen; vanilla cheats mostly print nothing and just happen.
Soldier names go in quotes when they contain a space: `"Marcus Tyr"`.

### Getting to the Avenger fast
| Where | Command | Does |
|---|---|---|
| Campaign setup | untick *Tutorial* and *Lost and Abandoned* | Skips the scripted opening; Gatecrasher becomes a normal mission |
| In Gatecrasher | `KillAllAIs` | Kills every enemy (bodies may stand there; take any action to end the mission) |

### Building a test squad (Avenger)
| Command | Does |
|---|---|
| `Astartes_DevSquad` | One fully promoted soldier of every Marine class, best gear, nicknamed after their class |
| `Astartes_DevSquad 3` | Same, but promoted only 3 ranks |
| `Astartes_Redress` | Re-rolls every soldier's look through the Marine generator (Tacticus armour, gender policy) |
| `Astartes_AP 100` | Every soldier gets 100 unspent ability points (and the XCOM pool), so every promotion choice can be bought for testing |
| `GiveFacility RecoveryCenter 3` | Builds the Training Center in room 3 (try 4, 5... if that room is taken); required before extra abilities can be bought with ability points |
| `Astartes_SquadSize 6` | Squad cap 4, 5 or 6 by granting the GTS squad-size unlocks; takes effect at the next squad select (6 = every class at once) |
| `Astartes_AppointCommander` | Appoints the first rank-7 Marine (or `Astartes_AppointCommander Hudson` by name) as Chapter Master; he gains his class's relic ability (Assault: Death Incarnate) |
| `Astartes_AppointChiefLibrarian` | Appoints the first rank-7 Librarian (or by name) as Chief Librarian, a separate unique; he gains Warp Mastery. Librarians cannot be Chapter Master |
| `Astartes_ExportLook Arthur Ward` | Prints a pool soldier's armour parts as a config line for `MarineLookParts` |
| `LevelUpBarracks 7` | Promotes every existing soldier 7 ranks |
| `MakeSoldierAClass "First Last" Astartes_Librarian` | Forces a soldier into a class |
| `MakeAllSoldiersReady` | Clears wounds, fatigue and shaken status |
| `HealAllSoldiers` | Heals everyone |
| `SetSoldierWill 1 "First Last"` | Sets Will (to test Know No Fear: no panic should follow) |
| `SetSoldierStat eStat_Mobility 30 "First Last"` | Sets any stat; useful stats: `eStat_HP`, `eStat_Offense`, `eStat_Mobility`, `eStat_Will` |

### Resources, research and gear (Avenger)
| Command | Does |
|---|---|
| `GiveResource Supplies 5000` | Also `AlienAlloy`, `EleriumDust`, `Intel`, `AbilityPoint` |
| `GiveTech <TechName>` | Completes a research, e.g. `GiveTech PlatedArmor`, `GiveTech MagnetizedWeapons` |
| `AddItem <Template> <Qty>` | Adds items, e.g. `AddItem Sword_CV_Primary 2` |
| `GiveFacility <FacilityName>` | Builds a facility instantly |
| `SetForceLevel 10` | Sets the campaign force level (what enemy tiers spawn) |
| `Astartes_Geneseed` / `Astartes_Geneseed 20` | Shows or sets the Chapter geneseed pool |

### Factions and continents (Avenger)
| Command | Does |
|---|---|
| `Astartes_Factions` | Which faction owns each continent, and whether its mod is loaded |
| `Astartes_SetContinentFaction Continent_NorthAmerica Orks` | Pins a continent; factions are `Orks`, `Chaos`, `Tyranids` |
| `Astartes_AssignFactions` | Re-deals all six continents at random |
| `Astartes_PartPacks` | Lists loaded body-part packs; confirms the Marine armour pack is active |
| `Astartes_ListClasses` | Confirms the five Marine classes are registered |
| `Astartes_Variants` | Reports each cloned unit variant as created (with HP) or skipped |

### Chapter and livery (Avenger)
| Command | Does |
|---|---|
| `Astartes_Chapter Country_BloodAngels` | Sets the campaign's Chapter (flag, names, colours) and redresses the barracks |
| `Astartes_Livery 35 35` | Applies armour tints (primary, secondary palette indices) to everyone, for tuning |
| `Astartes_Livery 35 35 Pattern_Name` | Same, plus an armour pattern |

Chapter countries come from the flag mods: `Country_Ultramarines`, `Country_BloodAngels`, `Country_DarkAngels`,
`Country_ImperialFists`, `Country_Salamanders`, `Country_SpaceWolves`, `Country_BlackTemplars`, `Country_RavenGuard`,
`Country_WhiteScars`, `Country_IronHands`, `Country_CrimsonFists`... (any `Country_*` the flag mods define).

Continent names: `Continent_NorthAmerica`, `Continent_SouthAmerica`, `Continent_Europe`, `Continent_Africa`,
`Continent_Asia`, `Continent_Oceania`. Only missions generated *after* a change use the new faction.

### In a mission
| Command | Does |
|---|---|
| `PowerUp` | God mode and unlimited action points for your squad: run across the map in one turn. Run again to turn off |
| `ToggleFOW` | Lifts the fog of war so you can see every pod |
| `TakeNoDamage` | Your units cannot be hurt (lighter than PowerUp) |
| `KillAllAIs` | Kills all enemies; take an action afterwards to trigger mission end |
| `GiveAbility <AbilityName>` | Grants the selected unit an ability for this mission |
| `GiveItem <Template>` | Gives the selected unit an item |
| `DropUnit <Template> <TeamNumber>` | Spawns a unit at the cursor; teams: `0` XCOM, `1` alien, `3` Lost. e.g. `DropUnit OrkNobM1 1`, `DropUnit Astartes_GreaterDaemon 1` |
| `AICallReinforcements` | Calls an enemy reinforcement wave (tests the reinforcement rewrite) |
| `TeleportUnitIDToCursor <id>` | Moves a unit to the cursor |
| `Astartes_ForcePerils Possession` | The next psychic power any Librarian casts suffers Perils with that outcome (`WarpSurge`, `Backlash`, `WarpShock`, `MentalPurge`, `Possession`); no argument = normal rolls again |

### Reading results
The log is `Documents\My Games\XCOM2 War of the Chosen\XComGame\Logs\Launch.log`. Lines from this mod are tagged
`Astartes`; pod rewrites look like `PodRewrite pod <name> on <continent> -> <faction> FL<n> [before] => [after]`.
`python -m pytest -m runtime` turns the dev-command PASS/FAIL lines into test results.
