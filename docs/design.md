# XCOM 2: Warhammer 40K Overhaul — Design Plan

> **Purpose of this file:** a complete record of the design brainstorm for a Warhammer 40K overhaul of XCOM 2: War of the Chosen. It's written so that a future Claude session (e.g. Claude Code) can read it cold and understand the vision, the decisions already made, what's still open, and roughly how to build it.
>
> **Status:** design phase; project skeleton (`Astartes` mod, X2ModBuildCommon build) compiles as of 2026-10-17. See `docs/mod-inventory.md` for what the subscribed Workshop mods already cover.
> **Working title:** TBD

---

## 1. Vision in one paragraph

The player commands a Space Marine Chapter fighting to liberate a cluster of star systems from three enemy factions — **Orks, Tyranids, and Chaos** — while the **Eldar** appear unpredictably as a hostile wildcard. Victory comes from clearing systems and killing each faction's overlord. There is no hard "you lose on day X" timer; instead, unchecked factions grow steadily stronger until missions become effectively unwinnable and the Chapter dies fighting. The tone is grim, costly, and Space Hulk–flavored: every Marine is precious, losses are permanent, and the Chapter's future depends on recovering its dead.

## 2. Core design pillars

1. **Every Marine matters.** Marines are rare and hard to replace. Permadeath should hurt.
2. **The enemies are genuinely dangerous.** Do NOT inflate enemies to justify Marines being strong — in 40K lore, Genestealers, Chaos Marines, Ork Nobz, etc. already kill Marines. Space Hulk (Terminators vs Genestealers) is the tonal reference.
3. **Pressure, not deadlines.** Difficulty escalates; the player loses by being overwhelmed, not by a calendar.
4. **Guile is a valid strategy.** Enemy factions fight each other; the player can exploit that.
5. **Reuse, don't rebuild.** Map 40K concepts onto existing XCOM 2 systems wherever possible. Lean on existing Workshop art mods (as required dependencies, with author permission) rather than bundling or recreating assets.

## 3. Platform & dependencies

| Item | Role | Notes |
|---|---|---|
| XCOM 2: War of the Chosen (WotC) | Base game | Chosen, Resistance factions, The Lost, soldier bonds, Will/traits, covert actions are all used heavily. |
| X2WOTCCommunityHighlander | Framework | Extra hooks/events so this mod can modify core systems and coexist with others. |
| Shen's Last Gift DLC | SPARK framework | Dreadnoughts are built on SPARK units. Hard dependency for the Dreadnought feature. |
| Alien Hunters DLC | **Required** (decided 2026-10-17) | The Alien Ruler framework is the Eldar overlord mechanic (§6.5). Also: Berserker Queen → Carnifex variant. Needs the Alien Hunters Community Highlander (Workshop 2534737016). |
| Existing Dreadnought skin mod (for SPARK) | Art | User already uses one. List as **required Workshop item**, don't bundle. |
| Existing Space Marine armor reskin mods | Art | Player soldier appearance. |
| Existing Chaos Space Marine armor reskin mods | Art | Can be applied to **enemy** humanoid units (see §6.3). |
| "Advent to Imperium [WOTC]" (Workshop) | Reference / possible contact | Reskins ADVENT as Imperial enemies. Its author mentions collaborating with a modder named **Iron** on an **Ork mod** and an early **Tau** version. Worth checking the Ork mod and contacting them about permissions/techniques. |

**Base game decision (2026-10-17): vanilla WotC + Community Highlander, NOT on top of Long War of the Chosen.** We are making our own "Long War of the Imperium". LWOTC is the *reference* for mechanics we port (its source is on GitHub, X2CommunityCore/X2LWOTC):
- Haven advisor / outpost (`UIOutpostManagement`, `XComGameState_LWOutpost`) -> Imperial Officer stationed in a region (§4.7b).
- Regional strength + liberation chain -> system strongholds and faction threat (§7.2, §7.3).
- Alien activities (`XComGameState_LWAlienActivity`) -> faction activities per continent (Waaagh! musters, hive incursions, rituals).
- Infiltration (time-vs-strength trade before a mission) -> **recommended replacement: Drop-Pod Planning** (pending the user's call, 2026-10-17). On mission appearance the player picks the insertion: immediate orbital drop = full squad now, higher alert level; delayed Thunderhawk insertion = smaller strike team, lower alert, start concealed. Same decision space as infiltration, lore-correct, reuses alert-level and squad-size levers instead of a new timer system. Phase 4.
- Bigger pods / more enemies per mission -> pacing target, within the §7.3 performance limit.
- Squad Barracks / squad cohesion (also in the subscribed SquadBasedRoster) -> battle-brother squads.
- Officer class and Commissariat already reference LW officers.

**Tooling:** XCOM 2 WotC SDK (ModBuddy + Unreal Editor), UnrealScript (`.uc`), config files (`.ini`), localization files (`.int`).

---

## 4. Player faction: Space Marines (Marines only, for now)

Decision (revised 2026-10-17): **Marines + Adepta Sororitas roster.** Two recruit pools offered side by side (config ratio, default 50/50): Space Marine *Scouts* (gender forced male via the Highlander appearance hook; MCM toggle "Allow female Space Marines" removes the force) and Sororitas *Novices* (female). Each pool promotes from its own class deck. Sisters are the **renewable** half (recruited via the Ecclesiarchy/Inquisition with supplies and standing); Marines are the **rare** half (geneseed-gated). Sisters have no psykers: their fifth line is **faith** (Acts of Faith keyed off Will, anti-psyker resistance). Sister classes mirror Marine classes: Battle Sister / Seraphim / Retributor / Hospitaller / Repentia-or-Celestian Sacresant. Art: WH40k_SisterOfBattle_Armor (22 female parts, one look) - a larger Sororitas set is wanted. (Imperial Guard as soldiers was set aside; the Guard is an allied faction, §7.6.)

### 4.1 Rank progression
Maps onto XCOM's rookie → class promotion → ranks.

- **Scout** (= Rookie) → promoted to a class →
- **Battle-brother / Marine** (class ranks) →
- **Veteran** (top ranks)

### 4.2 Classes

| 40K class | Closest XCOM 2 analogue | Role |
|---|---|---|
| Tactical | (new, flexible) | All-rounder, adaptable loadouts |
| Assault | Ranger | Jump packs, melee, mobility |
| Devastator | Grenadier | Heavy weapons, suppression, holding chokepoints |
| Apothecary | Specialist (medic side) | Healing, stabilizing, **geneseed recovery** (critical, see §4.6) |
| Psyker / Librarian | Psi Operative (own track) | Psychic powers; separate training path |

### 4.3 Psyker rank ladder (Librarius)
Use these as the psyker track's rank names:
1. Lexicanium
2. Codicier
3. Epistolary
4. Librarian
5. **Chief Librarian** — unique (see §4.4)

Multiple Librarians can exist; only one Chief Librarian.

### 4.4 Unique heroes (relic-tier)
Three unique positions, **only one of each at a time**, each with very powerful "relic-level" abilities. The **only** way to get one is to promote a top-tier Marine into the role.

| Unique | Eligible from | Notes |
|---|---|---|
| **Chapter Master** | Top-tier Veteran (any combat class) | Leader. Candidate for big abilities like orbital strike. |
| **Chief Librarian** | Top-rank Librarian (psyker track only) | Head of the Librarius. |
| **Master of Sanctity / Reclusiarch** | Top-tier Veteran of **any** class with high **Will** | Head Chaplain. |

**Chaplains in lore:** any battle-brother can become a Chaplain; they're chosen for faith and spiritual strength, not combat role. Apothecaries are a separate path and don't usually become Chaplains. **Game rule:** Chaplain eligibility is gated by the **Will** stat (and optionally by experiences, e.g. surviving a mission where most of the squad fell).

**Pattern across the board:**
- Chaplains (many) → Master of Sanctity (one)
- Librarians (many) → Chief Librarian (one)
- Veterans → Chapter Master (one)

Regular Chaplains and Librarians are normal roles with solid abilities; only the uniques get relic-tier powers.

**Replacement:** if a unique dies, a replacement can be promoted, but it should be slow/expensive so the loss stings.

**Synergy idea:** Apothecary (body) + Chaplain (soul) in the same squad → bonus.

**Chaplaincy ladder (decided 2026-10-18).** Like the Chapter Master and Chief Librarian, Chaplaincy is a *status* layered on a
combat class, not a class of its own, and the Reclusiam has its own ladder with the unique at the top:

| Step | Who | What he gets | How many |
|---|---|---|---|
| **Chaplain** | Any rank-4+ Marine of a combat class (not Apothecary, not Librarian) with Will at or above a threshold | Chaplain kit granted on appointment: *Litanies of Hate* (adjacent brothers +crit vs Chaos and daemons), *Rosarius* (personal shield), *Spiritual Liege* (Will aura; Guard and Sisters in range cannot panic). Black armour and skull helm (Space Marine 2 Chaplain Armor pack) applied like the Librarian hood. | Several |
| **Reclusiarch** | A rank-7 Chaplain | Adds *Exhortation* (a brother regains an action, cooldown) and *Purge the Unclean* (cleanse Chaos corruption, 8). | A few |
| **Master of Sanctity** | One Reclusiarch | Relic ability (candidate: *Litany of the Devout*: the whole squad cannot be stunned, disoriented or mind-controlled this turn and melee cannot miss; once per mission). Separate unique; never the same Marine as the Chapter Master or Chief Librarian. | One |

Appointment, one-at-a-time enforcement and loss tracking reuse `Astartes_ChapterMaster`'s pattern (`Astartes_AppointChaplain`, `Astartes_AppointMasterOfSanctity`). Chaplains keep their class tree; the kit is extra. Implementation after Chaos corruption (8) exists, since the Reclusiarch's purge needs it.


**Chapter Master relic ability depends on his origin class (decided 2026-10-17).** The Chapter Master (the player's "Force Commander") is appointed from a rank-7 Marine of any combat class, and the relic-tier ability he gains is the one for the class he came from. Only one Chapter Master exists at a time, so a campaign can only ever see one of these builds: a reason to play the mod again with a different Captain.

| Origin class | Relic ability | Shape |
|---|---|---|
| Assault | **Death Incarnate**: for the rest of the turn every melee kill refunds the action and resets the jump pack, with no per-turn cap (Whirlwind + Hit and Run, uncapped). Serial slaughter while the kills keep coming. | Free action, once per mission |
| Tactical | **Rites of Battle**: every Marine in sight regains all actions and gains +20 aim this turn. The squad acts twice. | Free action, once per mission |
| Devastator | **Orbital Bombardment**: mark an area; a Thunderhawk strike lands at the start of the next enemy turn (large AoE, destroys cover, friendly fire possible). | Once per mission |
| Apothecary | **The Emperor's Mercy**: every Marine in sight is healed to full and bleeding-out brothers stand up; geneseed from every fallen brother on the field is recovered automatically at mission end. | Once per mission + passive |
| Librarian | *Not eligible.* Librarians never hold the Chapter Master's seat. **Warp Mastery** (powers cast this turn roll no Perils; all psychic cooldowns cleared) is the **Chief Librarian's** relic, a separate unique appointed from a rank-7 Librarian (`Astartes_AppointChiefLibrarian`). Decided 2026-10-18. | Free action, once per mission |

**Implemented 2026-10-17 (evening):** `Astartes_ChapterMaster` (appointment rules, capstone as an unlocked class-agnostic ability, `ChapterMasterRef` on the Chapter state), dev command `Astartes_AppointCommander`, and the Assault capstone **Death Incarnate**. Other capstones pending. Rules: appointed from the Avenger (strategy action later; dev command now), rank 7 only, granted through the rank-up/appointment listener (same pattern as `Astartes_ClassLook`). If he dies, the next appointment costs geneseed and a waiting period so the loss stings (Replacement, above). Implementation order: after the five class trees are rounded out; Death Incarnate first since Whirlwind and Hit and Run already exist.

### 4.5 Terminators (expanded 2026-10-17)
- **A status, not a class.** A top-rank Marine of any combat class is *inducted into the First Company*; the class and tree are kept.
- **Hard cap**: `MaxFirstCompany` config, default **10**, enforced on the induction screen.
- **Gating mechanism:** induction sets a unit flag; the Highlander `CanAddItemToInventory` hook checks it, so Terminator armor and Terminator-only weapons are "requires First Company" items. No new class, no special slots.
- **Armor is additionally rare**: research + rare drop items, so slots can exceed suits.
- **Suit effect:** big HP/armor, immunity to disorient and knockback, mobility penalty, scale 1.15. Candidate trade-off: reduced cover bonus (too bulky), compensated by armor - a walking bunker, not a better Marine.
- **Terminator-only gear:** storm bolter, assault cannon, cyclone missile launcher; power fist, thunder hammer, storm shield (WotC Ballistic Shields mod as basis).
- **Deep strike:** unit is not placed at mission start and teleports onto a chosen tile during the player's turn (Iridar's Jet Packs "Dynamic Deployment" demonstrates the pattern). A short tactical teleport with long cooldown is a relic-tier option.
- Art: Gravis parts + Thousand Sons Terminator helmet as placeholder (§4.9).

### 4.5a Armour marks (implemented 2026-10-17)
The armour packs bind their body parts to the **vanilla armour template names** (Kevlar / Plated / Powered), so the vanilla tiers *are* the power armour marks rather than new items:
| Vanilla | 40K | Stats |
|---|---|---|
| KevlarArmor | **Power Armour Mk VII** | +2 HP, +1 armour via `Astartes_PowerArmourStats` (config in XComAstartes.ini); vanilla kevlar gives nothing |
| MediumPlatedArmor | Artificer Power Armour | vanilla (+4 HP, extra slot) - retune later |
| MediumPoweredArmor | Relic Power Armour | vanilla - retune later |
Terminator armour stays a separate item (§4.5). Chaos parity (§6.3) should be re-checked with Mk VII in play.

### 4.5b Weapon lines

**Models (2026-10-17):** our weapons are vanilla clones that *borrow* a donor mod's model, icon and attachments (`MeshFrom` in `X2Item_AstartesWeapons`), keeping vanilla stats and the research upgrade chain. Bolter, Bolt Pistol, Chainsword/Power Sword, Heavy Bolter and Force Sword wear the Space Marine Armory (workshop 3656755854) models, the Space Marine 2 set that matches the Tacticus armour; the donor packs are hidden so the armoury lists one Bolter. Without the donor mod the weapon falls back to the vanilla look. See docs/mod-inventory.md for the remaining candidates.
| Class | Primary | Secondary | Upgrade path / notes |
|---|---|---|---|
| Tactical | Bolter | Bolt pistol or chainsword | Kraken / Hellfire ammo |
| Assault | Chainsword | Bolt pistol | Power sword + plasma pistol, then relic blade + inferno pistol. Jump pack = armor/utility item. |
| Devastator | Heavy bolter **or** plasma cannon; later lascannon / missile launcher | Bolt pistol | Each heavy weapon interacts differently with the tree (suppress / shred+overcharge / single-target / area) |
| Apothecary | Bolter | Narthecium | |
| Librarian | Force sword / force staff | Bolt pistol | Psychic hood |
| Terminator gear | Storm bolter, assault cannon, cyclone | Power fist, thunder hammer, storm shield | First Company only |
Existing weapon mods (bolt pistols, plasma pistols, power claws, bolters, plasmagun, Space Marine Weaponry) already show the 3-tier + schematic template pattern.

**Playtest notes 2026-10-17 (first build):**
- Assault and Librarian carry **no bolter**: chainsword / force sword as *primary* (via Primary Secondaries, now a required mod) with bolt pistol / psychic hood as secondary. Their trees are melee, pistol, psi and survivability only.
- **Stasis-type effects and Sustain are not lore-friendly** for Astartes; banned from all Marine trees (enforced by test).
- **Tactical weapon choice:** bolter, or a plasma gun (shotgun archetype: short range, high damage, blast-style abilities), or a flamer. Needs our own weapon templates: plasma = Shotgun clone with new art; flamer = new primary weapon with cone targeting (the vanilla flamethrower is an armour-mounted heavy weapon; LW2's Technical gauntlet is the precedent). Devastators get a **heavy flamer** the same way.
- **Apothecary's narthecium** = gremlin re-skinned as a servo-skull (servo-skull mod subscribed); anti-robot gremlin abilities are uninteresting with few robotic enemies and were dropped from the tree.
- **Astartes Physiology:** all Marines are innately immune to poison (oolitic kidney / multi-lung); fire and acid still apply. Implemented as a squaddie-kit passive alongside Know No Fear.
- **Librarius training:** Librarians currently promote by XP like other classes. The separate psyker training path (§4.3, Librarius facility like the Psi Lab) is a Phase 2 feature.

### 4.6 Dreadnoughts (SPARK replacement) — key signature mechanic

**Lore correction applied:** a Dreadnought is a **mortally wounded but living** Marine interred in the sarcophagus. It is *not* made from geneseed.

**Mechanic:**
1. A Marine goes into the **bleeding out** state on a mission.
2. An **Apothecary** must be the one who **stabilizes** him.
3. The Marine must be **evacuated** (survives the mission).
4. → The Chapter gains an item: **"Interred Battle-Brother."**
5. Building a Dreadnought requires **research + the Interred Battle-Brother item** (Proving Ground project, like building a SPARK).
6. The new Dreadnought unit **inherits the Marine's name and nickname** (and optionally a stat/perk tied to his old class). The original soldier is retired from the roster.
7. **Dreadnought as a unit (2026-10-17):** SPARK-class unit with its own small tree (Venerable rank names), weapon loadout choice like Devastators (assault cannon / multi-melta / power fist + built-in storm bolter), no cover, slow, very high armor, repaired by Apothecary *Augmentic Repair* not healed. Supply is naturally capped by Interred Battle-Brother items. Pattern: Buildable Geth Redux (SPARK template subclass + Proving Ground project + custom pawn). Art: SM2 Dreadnought SPARK skin (all 3 armor tiers).

**Feasibility notes:**
- Detecting "stabilized by an Apothecary" + "evacuated" = event listeners on the stabilize ability (source unit is known) + mission-end check. Standard work; Highlander helps.
- Custom item as a Proving Ground ingredient = trivial.
- Converting a soldier into a different unit type in place is awkward → **create a new SPARK-based unit and copy identity over**, then retire the original.
- Art is solved by the existing Dreadnought skin mod.

### 4.7 Geneseed (separate from Dreadnoughts)
- **Marine killed + Apothecary recovers the geneseed** (reductor / narthecium) → adds to the Chapter's geneseed pool.
- **New Scouts are limited by geneseed.** This controls replacement rate and makes leaving dead behind costly.
- Effect on play: Apothecaries become essential; every evac is a "do we go back for him?" decision; a failed mission can damage the Chapter's future.
- **Geneseed purity** (idea): geneseed from Chaos-heavy systems may be tainted → better recruit stats but corruption risk later.

### 4.7b Panic, Know No Fear, and the Imperial Officer (decided 2026-10-17)
- **Marines never panic.** Passive *Know No Fear* on every Marine: immune to panicked / berserk / shattered. Will still exists and is spent on Chaos corruption (§8). Perils of the Warp (classes.md, Librarian) is an outcome table rather than Will damage: its worst result drags the Librarian into the Warp and spawns a daemon in his place (decided 2026-10-17). Fatigue stays.
- **Sisters frenzy instead of panicking.** A would-be panic becomes a charge at the nearest enemy.
- **Imperial Guard (haven militia, civilians) panic easily:** low Will in config.
- **Imperial Officer class** - a third promotion path (Novice/Scout stays human). Ranks: Lieutenant, Captain, Major, Colonel... with **Commissar** as the rank-7 title. Three columns: **Command** (orders, give actions, call a Guard fire team), **Commissariat** (aura: Guard in range cannot panic; **Summary Execution**: shoot a panicked allied Guardsman, all friendlies in sight shed panic and gain Will), **Tactician** (artillery, smoke, intel). Ordinary human (scale 0.85, human stats): bringing one is a Marine you did not bring. Mixed-gender human line.
- **Haven advisor (Phase 4):** only an Officer can be stationed in a region, adding Will to that region's Guard and reducing retaliation damage. WotC has no such slot; Long War of the Chosen's outpost/advisor code is the reference. Moderate-hard.

### 4.8 Soldier systems to reflavor
- **Soldier bonds** → battle-brother bonds.
- **Will / negative traits** → Chaos corruption (§8).
- **Memorial** → Wall of the fallen / honors.
- **Relic weapon inheritance** (idea): when a hero dies, his named weapon goes to the armory with his kill count; the next bearer inherits a bit of his legend.

---

### 4.8b Chapter = Country: livery and one-click armour (decided 2026-10-17)
A Marine's **Chapter is his "country"** (`X2CountryTemplate`): flag, name list and, in our mod, **livery**. The chapter flag mods (Blood Angels, Ultramarines, Chaos Legions...) already define `Country_BloodAngels` etc.
- **Campaign start:** the player picks the Chapter; it becomes the default country for every recruit (the generator is re-run with that country, same trick as the gender policy). Mixed-Chapter rosters (Deathwatch) stay possible per soldier.
- **Livery config** per country: primary/secondary armour tints, pattern, optional preferred part packs / set names. Applied by the appearance hook at generation and re-applied when the player changes a soldier's flag in customization (UI listener), so changing the flag re-dresses the Marine.
- **Sets:** add set names to pack parts at load time (same patch mechanism as class/tech locks) so choosing a chapter-specific torso cascades to matching arms/legs. The SM2 Tacticus pack ships no sets; most of its identity is tint.
- **Manual override always allowed:** the customization screen still lets a player put Space Wolves arms on an Ultramarines torso. The livery is a default and a one-click reset, never a lock.
- Goal: remove the per-soldier armour setup grind the user hits every new campaign.

**Look from a pool template (2026-10-18).** Random part picking dressed Marines in power fists and jump packs. Generated Marines now copy the armour parts of a character-pool soldier (`MarineLookTemplates`, random among several); tints and pattern still follow the Chapter. Per-class additions (Assault jump pack deco, Devastator backpack) belong in `Astartes_ClassLook` next to the Librarian hood.

### 4.9 Unit scale (decided 2026-10-17)
Marines stay on the **unmodified rig (scale 1.0)** so the player's most-watched units never have socket or cover glitches. Everyone else is scaled relative to them. Lore ratio: Marine ~2.1 m vs Guardsman ~1.75 m = 0.83.

| Unit | Scale | Notes |
|---|---|---|
| Space Marine | 1.0 | Default rig, no risk. |
| Terminator | 1.15-1.2 | Scale attached to the Terminator **armor template**, so it applies on equip. Gravis parts + Thousand Sons Terminator helmet as placeholder art (no loyalist Terminator pack on the Workshop; "Armours of the Imperium" was removed). |
| Imperial Guard, cultists, civilians, haven soldiers | 0.85 | |
| Chaos Marines | 1.0 | Same frame as loyalists. |
| Eldar | 0.95 | Tall but slender. |
| Orks | 1.0 on Muton rig (Nobz 1.1) | Already big. |

Known cosmetic risks for scaled units: melee contact and carry/hack animations assume standard height. Check how the subscribed scaling mod applies scale (pawn archetype vs. character template) before choosing the hook.

## 5. Enemy factions — overview

| Faction | Role | Holds territory? |
|---|---|---|
| **Orks** | Main territorial enemy | Yes |
| **Tyranids** | Main territorial enemy | Yes |
| **Chaos** | Main territorial enemy | Yes |
| **Eldar** | Wildcard, hostile to everyone | **No** — can appear in any system |

All territorial factions are hostile to each other as well as to the player (see §7.5 / §9.1).

---

## 6. Enemy rosters & rig mapping

**Principle:** build each new enemy model on an **existing alien skeleton** so it inherits existing animations. New models are still needed, but no new animation work.

### 6.1 Tyranids (biggest art job — fully non-human)

| Tyranid unit | Base XCOM rig | Notes |
|---|---|---|
| Carnifex | Berserker (Berserker Queen if Alien Hunters) | Charging armored brute |
| Tyranid Warrior | Muton | Mid-size frontline, ranged + melee. **Synapse leader:** buffs nearby bugs; its death causes panic/disarray among them. |
| Gargoyles | Archon (scaled down, weaker, more numerous) | Winged flyers. Better fit than drones. |
| Hive Tyrant | Archon King (Alien Hunters) | Winged boss variant |
| Purestrain Genestealer | Chryssalid | Fast deadly melee; "victims become enemies" ≈ Genestealer curse |
| Genestealer Cult hybrids | **Faceless** | Hidden among civilians, reveal when approached (§9.4) |
| Zoanthrope | Gatekeeper or Codex | Floating psychic artillery |
| Hormagaunts / Termagants | The Lost | Horde mechanic |
| Spore mines | Drone rig | Float toward squad and explode |
| Lictor (idea) | TBD | Stealth ambusher |

**Tyranid stages within a system:** early = Genestealer Cult (humanoid hybrids with guns, cover fights, ambushes) → later = full swarm (gaunts, warriors, bio-monsters). Natural escalation curve.

**Tyranid-held systems should contain only Tyranids** (lore: the fleet devours everything). Exception: Orks may crash a Tyranid world for a fight.

**Playtest 2026-10-17, all three factions confirmed via pod rewrite.** The Hive's `ChrysHybrid` is tuned as a mid-game unit (9 HP, 1 armour, 75 aim, 16 mobility): too strong for force level 1 against kevlar-stat Marines, about right once Power Armour exists. **Planned tool: faction unit variants** - clone a borrowed character template into our own (e.g. `Astartes_CultHybrid` from `ChrysHybrid`, `Astartes_Cultist` from `AdvTrooperM1`) with our own stats/loadout/appearance, in `OnPostTemplatesCreated`, leaving the source mod's balance untouched. Early lists then use our variants; the source mod's units take over at higher force levels.

### 6.2 Orks

| Ork unit | Base rig |
|---|---|
| Boyz / Nobz | Muton / Berserker |
| Mobs / hordes | Lost-style horde behavior (drawn to noise and fighting) |

- Check whether **Iron's Ork mod** (see §3) already covers this.
- Orks get stronger the more they fight and win (Waaagh! — see §7.3).

### 6.3 Chaos

| Chaos unit | Base rig | Notes |
|---|---|---|
| Chaos Space Marines | Humanoid (ADVENT/Muton frames or soldier-style humanoid enemies) | **Can reuse existing Chaos Marine armor reskin mods** — humanoid enemies can wear soldier-style armor parts (this is how "Advent to Imperium" puts Imperial troops on the enemy side). Needs permission from armor mod author. |
| Cultists | ADVENT trooper rig | Robes/rags from existing cosmetics |
| Sorcerers | Psionic abilities borrowed from Sectoid/Codex/Avatar | |
| Daemons | Teleport/psi-based rigs | |
| Possessed | **Faceless** mechanic | Ordinary-looking people erupt into horrors (§9.4) |

**Chaos Marine balance principle (playtest 2026-10-17): peers with a trade.** Observed: Black Legion M1 vs our Marine = +1 HP, +1 armour. Keep Chaos Marines at parity-or-slightly-above in raw body, because they *gain* dark gifts (mutation traits, sorcery, daemon engines) and *lose*: discipline (aggressive AI, poor cover/coordination, no healer), stability (mutations can be bad: berserk-at-half-health etc.), resistance to faith and anti-Warp effects (Sisters' Zealot, Null Zone, holy weapons hit harder; sorcerers suffer Perils), and numbers (warbands pad pods with cultists, our pods are all Astartes). Note: our Marines currently have kevlar-tier item stats; re-check parity once the Power Armour item exists.

### 6.4 Eldar (wildcard)
- Humanoid → could reuse soldier-style armor parts **if suitable Eldar armor mods exist** (unknown — needs checking).
- Units: Rangers, Farseer, Wraithguard, Warp Spiders (teleport, Codex-like).
- Behavior described in §9.2.

### 6.5 Faction overlords (replace the three Chosen)

| Faction | Overlord | Framework | Mapping |
|---|---|---|---|
| Tyranids | Hive Tyrant / Swarmlord | Chosen (Assassin slot) | Melee, fast, strikes and vanishes. Pawn from The Hive (Queen / Brood Mother). |
| Chaos | Daemon Prince | Chosen (Warlock slot) | Psionic, teleport, "spectral" summons re-flavoured as daemons. Pawn: Chaos Lord / Kytan. |
| Orks | Warboss | Chosen (Hunter slot, abilities replaced: charge, choppa, Waaagh! shout) | Pawn from Ork Raiders (3 Warboss models). |
| Eldar | **Farseer** | **Alien Ruler** (Alien Hunters) | Ruler reactions = foresight; ruler escape = Webway exit; carried-over wounds across missions; ruler armor drop = Rune Armor relic. Spawn weighting toward Chaos continents via the pod hook. |
| Eldar (extra) | **Archon Tahril** (Dark Eldar) and **Autarch Kayleth** (Craftworld) | Alien Ruler slots 2 and 3 | Archon pawn from Dark Eldar Raiders; Autarch built from the Eldar Armor pack (Swooping Hawk / Aspect armor) on a humanoid rig. Autarch replaces the Avatar of Khaine (no model). Voicepacks subscribed: Farseer Macha, Archon Tahril, Autarch Kayleth - a Dawn of War cast. |

Chosen framework notes: hard-wired to exactly three Chosen (hence Eldar on Rulers). Territories are dealt randomly at campaign start, same as our continent assignment. Kidnap → capture for corruption/sacrifice; "knowledge" → locating the strike cruiser; rival Resistance faction per Chosen → Inquisition / Mechanicus / Guard. Strongholds reuse the existing fortress maps unless new ones are built. Strengths/weaknesses are re-flavoured, not extended.

### 6.6 Art gap summary (as currently known)
Already exists (per user / search): Space Marine armor, Chaos Marine armor, Dreadnought skin, Imperial enemy reskin (Advent to Imperium), possibly an Ork mod.

**Still needed:**
1. **Tyranids** — full set of new models on existing rigs. **Biggest job.**
2. **Space Geoscape** textures/art.
3. **Eldar** — maybe reusable if armor mods exist.
4. **Orks** — only if Iron's mod doesn't pan out.

---

## 7. Strategy layer (Geoscape)

### 7.1 Map: reskin, not rebuild
- **A true multi-planet solar-system map is NOT feasible** (the Geoscape is built around one rotating globe; parts live in native code).
- **Feasible:** reskin the globe to read as space and rename everything.
  - **Continent → Star system** (or 40K subsector)
  - **Region → Planet** within that system
  - Continent bonus → "system secured" bonus.
- Region/continent names, descriptions, flavor text = localization edits (easy).
- Globe retexture (starfield, planets painted at region locations, new region border art) = harder; **uncertain how far Geoscape art can be pushed — needs investigation** (check modding Discord / Workshop for prior Geoscape retextures).
- **Constraints:** region and continent **counts are fixed**; **adjacency follows real-world Earth borders** → choose names with that in mind. Cross-continent links can be flavored as warp routes / jump lanes.

### 7.1b Faction ownership of continents (decided 2026-10-17)
- At campaign start each continent is **randomly assigned** an owning faction (Orks / Tyranids / Chaos), like Chosen territories. Config table allows fixed assignment for testing.
- **Mechanism (verified in Highlander source):** `X2DownloadableContentInfo.PostEncounterCreation` is called per pod when a mission's data is cached, with the mission site as `SourceObject` → region → continent → faction. We replace the whole pod with one drawn from the owning faction's encounter lists at the matching force level, so **pods are always faction-pure** (never a Nob next to a Chaos Marine). `PostReinforcementCreation` does the same for reinforcements; `PostSitRepCreation` attaches faction SitReps.
- **Border regions** (adjacent to another faction's continent): each pod rolls its faction independently → mixed mission, pure pods; optionally the second faction spawns on a spare team (`eTeam_One`/`eTeam_Two`) so they fight each other.
- **Tyranid continents** never roll a second faction.
- The Raider mods' own injection is still active and is **not yet disabled**: Ork Raiders adds its raid SitRep in `OnPreMission` (no config knob), Black Legion spawns Geoscape bases per continent that add its SitRep with an appearance chance. Until we neutralise or adopt these, a second faction can occasionally appear as a "raid" on top of our pure pods. Options: a RUN_LAST `OnPreMission` that strips foreign SitReps on owned continents, or adopting Black Legion's base system as the Chaos stronghold.
- **Implemented 2026-10-17:** `Astartes_FactionConfig` + `RewritePodForContinent` in the DLCInfo; Tyranids use our own full-range lists (`Astartes_TyranidLeaders/Followers`, FL 1-20: cult hybrids -> rippers/drones -> swarm) because The Hive's lists start at FL 5.
- Existing data: Ork Raiders / Dark Eldar Raiders / Black Legion already ship Weak/Normal/Strong/Boss encounter lists per force level.

### 7.1c Garrisons replace "make contact" (idea 2026-10-17, Phase 4)
- Vanilla region contact -> **establish a garrison**: an Astra Militarum regiment lands and builds a firebase. Haven militia = Guardsmen (Guardsman Militia mod). Retaliation = defend the firebase.
- Garrisoned regions are the Imperium's; ungarrisoned ones are the war front. Factions push back: an overrun garrison is a lost region (feeds §7.3 pressure and the "enemies can actually win" requirement).
- Garrison = where an **Imperial Officer** is stationed (the haven-advisor slot, §4.7b).
- Possible garrison upgrades in place of LWOTC haven jobs: more Guard, supply lines, intel, orbital uplink.
- **Win condition candidate (answers open question 6):** every region garrisoned and every faction stronghold destroyed / overlords dead.

### 7.2 Liberation structure (two tiers)
1. **System strongholds** (≈ Avatar facilities): each system has a faction stronghold — Ork fortress, Chaos shrine, Tyranid hive node. Destroying it **clears that system**.
2. **Faction overlords** (≈ Chosen): found via a chain of skirmishes / covert actions (like WotC's "hunt the Chosen" chain), culminating in a stronghold assault (like a Chosen stronghold / Blacksite-style story mission). Killing the overlord removes that faction's leadership permanently.

**Cleared systems** still spawn missions, but **weaker ones** — ideal for blooding new Scouts. (Long War 2's regional strength/liberation is a good precedent.)

### 7.3 Doom: soft escalation, no hard loss timer
**Decision:** NO Avatar-style "lose on a specific day" clock.

Instead, each faction has a **threat level** that rises over time:
- Orks → Waaagh! growing
- Tyranids → hive fleet swarm growing
- Chaos → warp tear widening

Rising threat feeds existing XCOM difficulty dials:
- **Force Level** (enemy tier progression)
- **Pod size and count**
- **Elite units** earlier and more often
- **Reinforcement** frequency and wave size (like the escalating reinforcements when you stall before extraction, but campaign-wide)
- **Bleed into neighboring systems** when unchecked

Clearing systems / killing overlords **pushes threat back down**.

**Loss happens naturally:** Marines die, geneseed runs out, the Chapter can't field a squad. The Chapter dies fighting.

**Must have a visible doom/threat meter per faction** so the player can see when things are slipping and know when it's time to push back, make a last stand, or restart. Avoid the hidden "slow death" where a campaign is doomed for hours without the player knowing.

**Practical limit:** "100+ enemies per map" is likely beyond what the engine handles well (enemy turns crawl, performance). Convey "overwhelmed" through fewer but meaner units, endless reinforcement waves, and early elites.

### 7.4 Faction bleed & border systems
- Unchecked factions spread into adjacent systems.
- **Border/contested systems** have multiple factions → more enemies, but they're busy fighting each other.
- **Salvage strategy:** a slipping campaign can be rescued with guile — push one faction's front into another's and let them bleed each other.
- Show threat levels so players can spot a border system as a **trap to exploit**, not just a danger.

### 7.5 Ship / base
The Avenger → **Strike Cruiser or Battle Barge.**

| Room | Role |
|---|---|
| Apothecarion | Infirmary, geneseed |
| Reclusiam | Will recovery, Chaplain training |
| Librarius | Psyker training |
| Forge | Engineering (Techmarines; servitors as staff) |

### 7.6 Allied factions (replace WotC's three Resistance factions)
- **The Inquisition**
- **The Adeptus Mechanicus**
- **The Astra Militarum (Imperial Guard)**

They run covert actions and give resources/favors. (WotC's hero classes — Reaper/Skirmisher/Templar — were discussed as hero-slot mappings in a hybrid roster; currently unused since the roster is Marines-only. Open question: reuse those slots for something?)

### 7.7 Other strategy ideas
- **Exterminatus:** destroy a lost system outright — kills everything there, system lost forever. Very limited uses, steep cost. A last-resort salvage tool.
- **Warp storms:** randomly cut off a system for a while; its faction grows unchecked.

---

## 8. Chaos corruption
- Use WotC's **Will** and **negative trait** systems.
- Fighting Chaos accumulates corruption → dark traits.
- **Chaplains purge** corruption.
- **Fallen brother returns:** a Marine lost to corruption or captured can come back later as an enemy **Chaos champion with his old name** (build on WotC captured-soldier mechanics).
- Tainted geneseed links in (§4.7).

---

## 9. Tactical systems & mission ideas

### 9.1 Multi-faction battles
- WotC already has **The Lost and ADVENT fighting each other** as separate hostile teams; players already kite Lost into ADVENT.
- Extend: Ork and Tyranid (etc.) pods hostile to each other **and** to the player.
- **Player tactics:** kiting groups into each other; **noise as bait** (explosions draw Orks like they draw the Lost); objective-focused play — survive while factions grind each other down.
- **Tuning work:** enemy AI tends to prioritize XCOM; configure AI so factions genuinely target each other when close. Needs testing.
- **Verify:** how many extra hostile team slots WotC exposes for modders (believed to exist beyond XCOM/Alien/Lost — confirm in the SDK).

### 9.2 Eldar interventions (Lost-mechanic, reworked)
Keep "third faction hostile to everyone," change the rest:
- **Small elite strike teams**, not a horde (Rangers, Farseer, Wraithguard).
- **Prophecy-based arrival** instead of noise: appear at a certain point in the fight, or telegraphed a turn or two ahead ("a Farseer foresaw this").
- **Hit-and-run:** high mobility, stealth, may **withdraw** once their goal is met.
- **Preferences:** more likely to appear in **Chaos** systems and to **target Chaos units first** — sometimes a useful distraction, sometimes the deadliest thing on the map.
- Can appear **in any system**.

### 9.3 Signature mission: Warzone Crossing
- Squad inserts **concealed** at one edge; objective (relic, evac, target) on the far side.
- **Ork and Tyranid forces already fighting** across the middle of the map at mission start.
- **Turn timer** so the player can't wait it out.
- **Keep the war alive:** both sides get reinforcement waves; AI nudged to hold zones so the battle line stays mid-map.
- **Player choices:** sneak around the flank, punch through a weakened spot, wait for a lull (timer limits this), use noise to redirect the fight.
- Win = get through, not kill everything. Signature mission for border systems.
- **Precedents:** WotC retaliation missions start with Resistance already fighting ADVENT; some maps start with Lost vs ADVENT engaged.

### 9.4 Infiltrators among civilians (Faceless mechanic)
- **Tyranid systems:** Genestealer Cult hybrids hidden among civilians.
- **Chaos systems:** possessed / daemon eruptions; frequency rises as the warp tear grows.
- **Purging civilians:** lore-accurate for the Imperium to do without remorse. **Open question:** no penalty at all, or a minor one (e.g. standing with a specific ally)? User leans toward lore accuracy (little or no penalty).

### 9.5 Other tactical ideas
- **Drop pod insertion:** player chooses landing points; impact damages nearby enemies. **(Top-3 pick)**
- **Terminator deep strike** mid-mission.
- **Summoning rituals:** Chaos missions with a turn limit to break a ritual circle before a daemon arrives.
- **Orbital strike** as a Chapter Master relic ability (idea).
- **Space Hulk boarding missions:**
  - **Open to any squad** — NOT Terminators-only (Terminators are rare top-tier units; locking content to them would push it to endgame).
  - Narrow corridors and short sightlines → overwatch play, Devastators at chokepoints, Assault in tight melee.
  - Terminators are a **major advantage**, not a requirement.
  - **Scale with the campaign:** small boarding actions early, huge derelicts late.
  - Requires **custom maps** (significant work) — the mod's crown jewel.

**Top 3 brainstorm picks for feel + buildability:** drop pods, relic weapon inheritance, Exterminatus.

---

## 10. Win / loss conditions
- **Win:** kill all three faction overlords (and possibly clear a required number of systems — TBD).
- **Loss:** no hard timer. Escalating faction threat (§7.3) until the Chapter can no longer fight. Visible threat meters signal when a campaign is lost.

---

## 11. Feasibility summary

| Feature | Difficulty | Main cost |
|---|---|---|
| Renaming regions/continents/text | Easy | Localization |
| Classes, ranks, abilities | Moderate | Code/config |
| Unique hero promotions | Moderate | Code (custom promotion rules, one-of-each enforcement) |
| Dreadnought mechanic | Moderate | Event listeners + item + unit creation; art already exists |
| Geneseed economy | Moderate | Strategy-layer code |
| Soft doom / threat meters | Moderate | Hooking into force level, pod size, reinforcements; UI |
| Faction ownership of continents + pure pods | **Easy-Moderate** | One `PostEncounterCreation` override + config tables; encounter lists already exist in the faction mods |
| Overlords on Chosen framework | Moderate | Pawn swap + ability set config + localization; stronghold maps reused |
| Eldar Farseer on Alien Ruler framework | Easy-Moderate | Config thresholds + pawn swap + spawn weighting; Alien Hunters required |
| Multi-faction hostile battles | Moderate | Team setup + AI tuning |
| Warzone Crossing mission | Moderate–Hard | Mission scripting, reinforcement balance |
| Chaos enemies | Moderate | Reuse existing armor mods + permissions |
| Geoscape space reskin | Moderate (art-heavy) | **Verified in SDK:** the globe is a static-mesh sphere with a runtime-bound material (`XComEarth.BindOverworldMaterials`); region shapes come from per-region textures (`Helpers.ConstructRegionActor`). Pure content replacement, no code. Limits: stays a sphere with Earth region layout/adjacency. |
| Avenger crew reskin (Bradford/Tygan/Shen) | Easy (models/text) / Expensive (voice) | Crew are character templates with pawn archetypes (`HeadScientist`, `HeadEngineer`) -> config pawn swap. Subtitles are localization. Voice = hundreds of narrative-moment sound cues: mute, TTS, or re-record. WotC dynamic chatter is template-driven, can be disabled via config. |
| Tyranids | Hard | Many new models (no new animations if rig-matched) |
| Space Hulk missions | Hard | Custom maps |
| True multi-planet solar system map | **Not feasible** | — |

---

## 12. Open questions
1. ~~Which classes can become **Chapter Master**?~~ Answered 2026-10-17: any rank-7 combat class; his relic ability depends on the origin class (4.4).
2. Exact **Will threshold / experiences** for Chaplain eligibility.
3. How slow/expensive is **replacing a dead unique**?
4. **Civilian purge penalty:** none, or minor?
5. Should the **WotC hero-class slots** (Reaper/Skirmisher/Templar) be reused for anything in a Marines-only roster?
6. Win condition: overlords only, or overlords + N systems cleared?
7. **Eldar armor mods** — do any exist that could be reused?
8. **Iron's Ork mod** — does it exist / is it usable / permissions?
9. How far can the **Geoscape globe art** be modded? (Check XCOM 2 modding Discord / Workshop.)
10. Name for the Chapter (custom or existing?) and the mod's title.
11. Exact mapping of real XCOM regions/continents → star systems/planets (must respect fixed counts and adjacency).
12. Number of WotC **extra team slots** available for additional hostile factions.

---

## 13. Suggested build order

**Phase 0 — Research & permissions**
- Inventory existing Workshop art mods (Marine, Chaos, Dreadnought, Ork, Eldar). Contact authors.
- Confirm SDK specifics: team slots, Geoscape moddability, Highlander hooks needed.

**Phase 1 — Player side (smallest playable slice)**
- Marine classes, ranks, Scout start, psyker track with Librarius rank names.
- Localization pass (names, flavor).
- Geneseed recovery by Apothecary.
- **Continent faction ownership + pure-pod spawning** (moved up from Phase 4: it is what makes the enemy rosters matter, and the faction mods already provide the units).

**Phase 2 — Signature mechanics**
- Dreadnought creation (stabilized-by-Apothecary → item → Proving Ground → identity carryover).
- Unique hero promotions (one of each).
- Terminator armor gating.

**Phase 3 — Enemies (start with the cheapest)**
- Chaos (humanoid, reuses armor mods) and cultists.
- Orks (if existing mod usable).
- Eldar wildcard behavior.
- Tyranids last (biggest art job).

**Phase 4 — Strategy layer**
- Region → planet / continent → system mapping and text.
- System strongholds, overlords via Chosen framework.
- Soft doom threat meters, faction bleed, cleared-system training missions.

**Phase 5 — Mission types**
- Multi-faction battles and AI tuning.
- Warzone Crossing.
- Drop pods, rituals, infiltrator civilians.
- Space Hulk (custom maps) — stretch goal.

**Phase 6 — Art polish**
- Geoscape space retexture.
- Remaining Tyranid models.

---

## 15. Testing approach
- **Config validation (pytest, `tests/`)**: every template referenced must exist; every template must have localization; design rules are assertions (one Chief Librarian, 7 ranks per class, no psi on Ork templates, faction-pure encounter lists). Run with `python -m pytest`.
- **Runtime log-assert harness (later)**: debug `exec` commands that set up a game state, run a code path and write PASS/FAIL to `Launch.log`; a pytest wrapper parses it. Required coverage, learned from bugs in the Jedi Class mod: (1) an ability's effects must not break the *next* action's visualization (Reflect crash), (2) persistent effects must be removed cleanly at mission end (Lightsaber Telekinesis crash on mission exit).

### 15.1 Playtest cheats
Enable the console in AML: Quick-toggle `-allowConsole` (already in the launcher's toggle list), then `~` or `\` in game.
Vanilla cheat commands that matter for us (strategy layer unless noted):
- `LevelUpBarracks 7` promotes every soldier 7 ranks (fully promoted squad from a fresh campaign). `LevelUpCrew`, `MakeSoldierAClass <id> <class>`, `MakeAllSoldiersReady`, `HealAllSoldiers`.
- `GiveTech <TechName>`, `GiveResource <Name> <Amount>` (Supplies, AlienAlloy, EleriumDust, Intel), `AddItem <Template> <Qty>`, `GiveFacility <Name>`, `SetForceLevel <n>`, `SetSoldierStat`, `SetSoldierWill`.
- Tactical: `PowerUp` (god mode + infinite actions), `TakeNoDamage`, `GiveAbility <Ability>`, `GiveItem`, `DropUnit <Template> <Team>`, `KillAllAIs`, `AICallReinforcements`, `TeleportUnitIDToCursor`.
Our own dev commands (to add as the runtime harness, §15): `Astartes_DevSquad` (one fully promoted Marine of each class + Sister + Officer with tier-3 gear), `Astartes_SpawnPod <Faction> <ForceLevel>` (tactical), `Astartes_SetContinentFaction <Continent> <Faction>`, `Astartes_Geneseed <n>`, `Astartes_InductTerminator <id>`.

## 14. Notes for Claude Code
- Engine claims in this document came from a design conversation, not from inspecting the SDK. **Verify against the WotC SDK source and Highlander docs** before relying on any specific class, event, or team name.
- Prefer **config (`.ini`) and Highlander event hooks** over class overrides wherever possible, for compatibility with other mods.
- Treat third-party art mods as **required Workshop dependencies**, never bundled assets.
- Keep features modular so phases can ship independently.
