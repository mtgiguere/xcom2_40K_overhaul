# Building on LWOTC (decided 2026-10-19)

Working title for the combined experience: **Long War of the Imperium (LWOTI)** (user, 2026-10-19).

Long War of the Chosen (workshop 2683996590) becomes a required dependency: its strategy layer is the loop of
design.md 7.8, re-skinned. This page maps LWOTC's systems onto ours and lists every collision found by reading its
config and source (static audit, 2026-10-19). Nothing here is verified in game yet; the first spike is a test run.

## LWOTC system → our meaning

| LWOTC | Ours |
|---|---|
| Region contact by scanning | Building a base on a planet (scan time = construction time) |
| Haven (outpost) and its rebels (`Rebel`, `FacelessRebel`) | The base and its Imperial Guard garrison; a Faceless rebel is a Chaos cultist / genestealer hybrid hiding in the garrison (design 9.4) |
| Haven defence: rebels fight as `RebelSoldierProxy` / `M2` / `M3` | Guardsmen, Veterans, Kasrkin defending the base |
| Haven advisor | Base commander (e.g. the Commissar) |
| Rebel jobs (supplies, intel, recruits) | Garrison duties; recruits matter most (design 7.8) |
| Chosen and their regions | Faction overlords and their systems; the overlord strengthens his territory over time |
| Liberation | A base on every planet of a faction's continent plus its stronghold(s) destroyed |
| LWOTC soldier classes (`LWS_*`) | **The Imperial Guard classes** (see below) |
| LWOTC officer pack | The Imperial Officer line (design 4.7b) |
| Alien activities / infiltration | Faction activity on each world; infiltration stays |

### The Guard classes come almost free

The design makes every ordinary recruit a Guardsman; only high Combat Intelligence opens the Marine (men) or Sister
(women) path. LWOTC's eight human classes are already a Guard regiment's roles, so they become the Guard classes with
new names, gear and looks rather than new trees:

| LWOTC class | Guard role |
|---|---|
| `LWS_Ranger` | Guardsman (rifleman) |
| `LWS_Assault` | Storm trooper / shotgun breacher |
| `LWS_Sharpshooter` | Marksman (long-las) |
| `LWS_Gunner` | Heavy weapons team (heavy stubber, autocannon) |
| `LWS_Grenadier` | Grenadier |
| `LWS_Specialist` | Medic / vox operator |
| `LWS_Technical` | Flamer trooper |
| `LWS_Shinobi` | Out of the recruit deck (user: line Guardsmen do not fight in melee; that is the Ogryns' job, a later class) |
| `LWS_RebelSoldier` | Kept: LWOTC's rebel-turned-soldier |

**Built 2026-10-19:** `Astartes_GuardClasses` renames these eight at load (names, summaries, Guard rank titles: Conscript to
Lieutenant); XCOM's rifles wear the lasgun, LWOTC's laser rifle the hot-shot (`Reskins`). Sister classes: Battle Sister,
Retributor, Seraphim, Hospitaller, reached by a gifted woman's ascension (she takes the veil: Sister plate, +HP, +will).

Rookie routing at first promotion: Combat Intelligence (vanilla `ComInt`) at or above a threshold and male → a Marine
class; female → a Sister of Battle class (to be designed); everyone else → an `LWS_*` Guard class.

## Collisions to resolve (static audit)

1. **Recruit deck.** Our `remove_from_deck` must stop removing nothing of LWOTC's and instead own the routing above;
   today a rookie can roll a Marine class directly. Marine classes leave the random deck.
2. **Soldier base stats.** We set `[Soldier X2CharacterTemplate]` to Marine stats (HP 8, Will 55); LWOTC sets HP 4,
   Will 30, two utility slots. Under 7.8 the base soldier is a human Guardsman: drop our override and give Marines their
   physiology through the class (stat progression + Astartes Physiology).
3. **Rookie loadout.** Both mods remove the vanilla `RookieSoldier` loadout and add their own, so two entries exist with
   one name. Drop ours; rookies carry LWOTC's kit (lasgun look later).
4. **Recruit appearance.** Our hook dresses every generated `Soldier` as a Marine in the Chapter's livery. It must only
   dress units that become Marines (at the promotion), and dress Guard recruits as Cadians.
5. **Haven rebels.** `Rebel`, `FacelessRebel`, `RebelSoldierProxy*` are LWOTC templates spawned from strategy units,
   not encounter pods: our `AllyReplacements` never sees them. Dress those templates themselves (generator + look) as
   Guardsmen.
6. **Faction heroes.** LWOTC rebalances the Reaper / Skirmisher / Templar (LW_FactionBalance). Our `Astartes_NoHeroes`
   still rewires the rewards; check LWOTC's own hero grants (faction rescue missions) in the spike.
7. **Pods.** LWOTC's pod manager and encounter lists change pod sizes and contents; our continent rewrite runs after
   them on the same hooks and should still win. Verify the log's `PodRewrite` lines.
8. **The Lost.** LWOTC has its own Lost variants (`X2Character_TheLost_LW`); our incursion rule matches by the
   `TheLost` encounter prefix, which LWOTC keeps. Verify.
9. **Mission timers and infiltration.** Not a collision, a design input: objective-only victory (7.8) must work with
   LWOTC's timed missions.
10. **Load order.** Our config must load after LWOTC's where both set the same keys (`RequiredMods` / run order).

## Spike results (2026-10-19) and fixes

Played one mission: rookies started with assault rifles (LWOTC's loadout won), a Skirmisher was on the crew (the start state's
faction soldier) and wore Deathclaw parts, eight Marines (our classes in the deck), LWOTC classes present (expected), the
Narthecium was a plain gremlin. Fixed the same day: Marine classes out of the deck and `Astartes_Ascension` (collision 1),
no `[Soldier]` stat override (2), no rookie loadout override (3), recruits no longer dressed as Marines; ascended aspirants are
(4), the starting faction hero stripped (6), the Narthecium wears the Servoskull mod's skull, Deathclaw / Skorge parts marked
specialized so random recruits never wear them. Same evening: the basic armour is flak armour again (Marines' +2 HP / +1 armour moved into the ascended physique); a Blood
Angels strike force (Captain plus Assault, Devastator, Apothecary) joins at campaign start; haven rebels are dressed as Guardsmen.
Opening mission: LWOTC's Troop Maneuvers is replaced by its retaliation (`Terror_LW`). The starting haven's rebels, dressed
as Guardsmen, are on the map under attack and the strike force relieves them. Set by `XComMissionSources.ini` and enforced in
`SetStartMission` at campaign start (start site excludes every other start family, so LWOTC's hybrid-difficulty rebuild keeps it).
Change it with `StartMissionFamily` in `XComGame.ini` (`Defend_LW` is the haven defence alternative).

Previously open: haven rebels dressed as Guardsmen (5); `KevlarArmor` is still named Power Armour.

## First spike (user)

Enable LWOTC with the current Astartes profile, start a campaign, play one mission and one strategy month. Look for:
crashes at launch, the recruit screen (what classes rookies roll into), a mission's pods (`PodRewrite` lines), and the
haven screen. The log lines tagged `Astartes:` and any redscreens tell us where to start.
