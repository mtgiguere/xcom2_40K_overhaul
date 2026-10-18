# Marine classes: ability tree draft v0.1

Status: **draft for review**. Nothing here is implemented. Template names in `code` are vanilla WotC
abilities we reuse as-is or re-skin; names marked **(new)** need UnrealScript. Tests in
`tests/test_soldier_classes.py` grow from this document once it is approved.

## Design rules for hard choices

The user's rule: no promotion should have an obviously best pick. Soldiers of one class must end up
different from each other. Every rank in every tree below is checked against these:

1. **Different axes, not different power.** The three options at a rank each answer a different
   question: *who am I best against*, *when am I strongest*, *who do I protect*. The campaign makes
   this bite: Tyranid and Ork systems reward anti-horde picks, Chaos and Eldar systems reward
   anti-elite picks, and the player does not know which systems they will be fighting in next month.
2. **Never pair a flat passive against an active of the same purpose.** "+10 aim" vs "a shot
   ability" is not a choice.
3. **Each column has a capstone identity** (rank 7) that only pays off if you committed to it, so
   splashing is a real cost.
4. **Cross-column synergies exist** so hybrids are viable builds, not failed ones.
5. **Costs differ**: some picks are free passives, some eat action economy, some have cooldowns,
   some carry a risk (Will damage, exposure). Equal power at unequal cost is still a choice.
6. **Review gate:** anything reviewers would "always take" gets rebalanced or moved before code.

**Rank 1 is the Squaddie kit, not a choice.** XCOM grants every ability in the rank-1 row at once (vanilla
behaviour, same as Ranger getting Slash + Phantom... at Squaddie). So the rank-1 rows below are the class's
starting kit and the hard choices begin at rank 2. Every Marine class also carries **Know No Fear**
(panic immunity) in its rank-1 row, and the Apothecary's **Recover Geneseed** is in its rank-1 row and
therefore innate (resolves open question 2).

Column layout: three columns (the subscribed New Promotion Screen supports it). The vanilla
XCOM-AP "buy the off-column ability later" system stays on, which keeps "I want both" alive without
making it free.

## Rank names

| Rank | Combat classes | Librarius |
|---|---|---|
| Rookie | Scout | Scout |
| 1 | Neophyte | Aspirant |
| 2 | Battle-Brother | Acolyte |
| 3 | Brother-Sergeant | Lexicanium |
| 4 | Veteran Brother | Codicier |
| 5 | Veteran Sergeant | Epistolary |
| 6 | Lieutenant | Librarian |
| 7 | Captain | Senior Librarian |

Uniques (Chapter Master, Chief Librarian, Master of Sanctity) are **not** ranks; see design.md §4.4.

---

## Tactical (bolter + chainsword / bolt pistol)

Role: the adaptable backbone. Columns: **Marksman** (bolter mastery), **Sergeant** (squad command),
**Reactive** (overwatch and positioning).

| Rank | Marksman | Sergeant | Reactive |
|---|---|---|---|
| 1 | **Bolter Drill (new)**: first shot each turn costs one action but does not end the turn. | **Rally (new)**: once per mission, grant an adjacent brother an action. | `CoveringFire`: overwatch triggers on any enemy action, not just movement. |
| 2 | `DeadeyeDamage` re-skin, **Kraken Rounds**: aim penalty for +damage and armor pierce. | **Tactical Doctrine (new)**: allies within 4 tiles get +1 mobility on turns you did not fire. | `ReturnFire` re-skin, **Bolter Discipline**: free reaction shot at the first enemy who shoots you each turn. |
| 3 | `LightningHands` re-skin, **Pistol Snap**: free bolt-pistol shot once per turn. | **Hold the Line (new)**: adjacent brothers gain +20 defense while you are in full cover. | `Suppression` (bolter version): pins a target, reaction fire if it moves. |
| 4 | **Hellfire Rounds (new)**: ammo swap, shred and bonus vs biological (Tyranid/Ork) targets. Cooldown. | **Chapter Banner (new)**: aura, +Will and immunity to panic within 6 tiles while you are alive. | `EverVigilant`: free overwatch if you only moved this turn. |
| 5 | `RapidFire`: two shots, aim penalty each. | **Combat Squads (new)**: once per mission, split: you and one brother get a free move. | `Sentinel`: two overwatch shots per turn. |
| 6 | **Executioner (new)**: guaranteed crit vs targets at or below half health. Cooldown. | **Inspire (new)**: remove disorient/panic/stun from all allies in 6 tiles. Cooldown. | `Untouchable` re-skin, **Transhuman Physiology**: after a kill, next enemy shot misses. |
| 7 | **Codex Volley (new)**: fire at every visible enemy within bolter range once; all shots at -aim. Once per mission. | **For the Emperor (new)**: once per mission, all allies refund actions. Chapter Master prerequisite. | **Kill Zone** `KillZone`: cone overwatch, shoot every enemy that moves in it. |

Hard-choice check: Marksman wins when one target must die (Chaos champion, Nob), Sergeant wins when
the squad is in trouble (Tyranid swarm turns), Reactive wins in defensive and extraction missions. Rank 7
is three different missions' MVP.

## Assault (jump pack + chainsword + bolt pistol)

Role: mobility and melee. Columns: **Blade** (chainsword lethality), **Jump** (jump-pack mobility
and shock), **Bulwark** (survive what you dive into).

| Rank | Blade | Jump | Bulwark |
|---|---|---|---|
| 1 | `Blademaster` re-skin, **Chain Teeth**: +damage with chainsword. | **Jump Pack** (built 2026-10-17: `IcarusJump` retuned via `Astartes_AbilityVariants`): jump to any visible tile within 14 tiles ignoring terrain; one action, does not end the turn (jump, then strike); 2-turn cooldown; no ruler reaction. | **Power Armour Veteran (new)**: regenerate 1 HP per turn while above half HP. |
| 2 | `Shadowstrike` re-skin, **Charge**: +crit on melee after moving 6+ tiles. | **Shock Landing (new)**: landing from a jump disorients adjacent enemies. | `Fortress` re-skin, **Iron Halo**: immune to fire/poison/acid tiles. |
| 3 | `Reaper` re-skin (Ranger version), **Whirlwind**: every melee kill refunds the action, damage falls per kill. | **Hit and Run (new)**: after a melee kill, free jump out (uses cooldown). | `Shieldwall` re-skin, **Hold Fast**: +2 armor when adjacent to an enemy. |
| 4 | `Bladestorm`: free melee attack against anything that moves adjacent. | **Hammer of Wrath (new)**: jump landing deals AoE damage; 3-turn cooldown; cannot act after. | **Bolt Pistol Suppression (new)**: pin a target with the pistol, keep melee for next turn. |
| 5 | **Duelist (new)**: melee against a single-model elite (Chaos Marine, Eldar, Nob) ignores armor. | `Implacable`: free move after a kill. | **Undying (new)**: first time per mission you would die, drop to 1 HP and go bleeding-out instead. Apothecary synergy. |
| 6 | **Decapitate (new)**: melee that cannot miss, no crit, 4-turn cooldown. | **Deep Jump (new)**: jump range doubled, lands in concealment if no enemy saw you. | `Untouchable`. |
| 7 | **Death from Above + Blade (new)**: a jump followed by a melee attack in one action, once per mission. | **Angel of Death (new)**: three jumps this turn, no cooldown, mobility +4. Once per mission. | **Last Stand (new)**: while bleeding out you can still take one action per turn for 2 turns. |

**Jump line, next steps (2026-10-17).** The Jedi Class Revised mod (workshop 2031929512, source shipped) has a *Leap Strike*: a melee attack whose approach is a grenade-style arc path with a synced jump animation, plus a *Force Jump* with a traversal passive. Its pattern (precomputed arc path + `X2AbilityTarget_MovingMelee` + custom targeting method) is the model for **Hammer of Wrath** / **Death from Above + Blade** (jump straight into a chainsword strike), ported into our own classes with no runtime dependency on the Jedi mod and without its Reflect/Telekinesis crashers. The Jump Pack itself stays on the vanilla Icarus path, which is proven on soldier pawns.

Hard-choice check: Blade is the Tyranid/Ork answer, Jump is for objective-rush and Eldar hit-and-run,
Bulwark keeps the brother alive against Chaos (lore: losses are permanent and geneseed matters).
Rank 5 is the knife edge: armor-ignore vs. free move vs. death save.

## Devastator (heavy bolter / plasma cannon / missile launcher)

Role: heavy weapons and zone control. Columns: **Suppressor** (deny the map), **Gunner** (kill
big things), **Emplacement** (reward not moving).

| Rank | Suppressor | Gunner | Emplacement |
|---|---|---|---|
| 1 | `Suppression`. | `Shredder`: shots shred armor. | **Brace (new)**: if you did not move, +15 aim this turn. |
| 2 | `HoloTargeting`: shots mark the target, allies +aim. | **Plasma Overcharge (new)**: next shot +damage, weapon disabled next turn. | **Bipod (new)**: overwatch from unmoved position does not suffer the reaction-fire aim penalty. |
| 3 | `AreaSuppression` (Demolition re-skin, **Sweeping Fire**): suppress a cone. | **Lascannon Round (new)**: ammo, single target, huge pierce, 1 charge. | **Sandbag Position (new)**: deploy a cover piece in an adjacent tile, once per mission. |
| 4 | **Grinding Advance (new)**: suppressed enemies that move take damage. | `ChainShot`: a second shot if the first hits. Aim penalty. | `Salvo` re-skin, **Heavy Stance**: fire the heavy weapon, then may still reload. |
| 5 | **Fire Lane (new)**: a line of tiles becomes a reaction-fire zone for 2 turns. | **Krak Missile (new)**: single-target heavy-weapon shot, bonus vs armor and robotic/daemon-engine. | **Weapon Mount (new)**: while unmoved for 2 turns, +1 heavy-weapon charge. |
| 6 | **Hunker Them Down (new)**: suppressed enemies cannot use abilities, only move. | **Melta Round (new)**: ammo, point blank, ignores all armor, destroys cover. | `Sentinel`. |
| 7 | **Whirlwind Barrage (new)**: all enemies in a large zone are suppressed and marked. Once per mission. | **Tank Hunter (new)**: your shots vs large units (Carnifex, Dreadnought, Kytan) always crit. | **Castellan (new)**: unmoved allies within 3 tiles also get Brace. |

Hard-choice check: Suppressor trades damage for control, Gunner is the anti-Carnifex/anti-daemon
engine path, Emplacement is for Warzone Crossing and defense missions where you own a position.

## Apothecary (bolter + narthecium)

Role: medic and keeper of the geneseed. Columns: **Triage** (keep them fighting), **Reductor**
(the dead and dying are the Chapter's future), **Battle-Medic** (fights while healing).

| Rank | Triage | Reductor | Battle-Medic |
|---|---|---|---|
| 1 | `MedicalProtocol` re-skin, **Narthecium**: heal adjacent ally, 2 charges. Stabilize is free for all Apothecaries. | **Recover Geneseed (new)**: on an adjacent dead Marine, adds geneseed to the Chapter. Always on; this is the class's reason to exist. | `Aid Protocol` re-skin, **Combat Stims**: +defense and clear suppression on an ally. |
| 2 | **Field Surgery (new)**: healed allies also lose one negative status. | **Interment Rites (new)**: a Marine you stabilize and who evacuates becomes an Interred Battle-Brother (Dreadnought item). | **Stimm Shot (new)**: ally gets a free move; costs them 2 Will. |
| 3 | `RevivalProtocol`. | **Reductor Mastery (new)**: geneseed recovery from one tile away, and from Marines who died this mission even if their body was destroyed. | `Suppression` (bolter). |
| 4 | **Augmentic Repair (new)**: heal a Dreadnought or Terminator for armor, not HP. | **Preservation (new)**: stabilized Marines cannot be killed by area damage for 2 turns. | **Warrior Medic (new)**: healing does not end your turn. |
| 5 | **Mass Triage (new)**: heal all allies within 4 tiles for less. 1 charge. | **Purity Check (new)**: recovered geneseed from Chaos systems is cleansed (no taint), 1 use per mission. | `SavingGrace` re-skin, **Guardian**: heals grant +1 armor until next turn. |
| 6 | **Combat Doctrine (new)**: +1 narthecium charge per Marine on the mission above 4. | **Honour the Fallen (new)**: when a Marine dies, allies within 6 tiles gain +Will instead of losing it. | **Chirurgeon's Fury (new)**: after healing, your next shot this mission crits. 2 charges. |
| 7 | **Miracle of the Emperor (new)**: once per mission, revive a Marine who died this turn at 1 HP, bleeding out. Costs 1 geneseed. | **Harvest (new)**: geneseed recovery doubles for the mission; every recovery grants the squad +Will. | **Last Rites (new)**: a dying Marine adjacent to you gets one final action. |

Hard-choice check: Triage keeps the squad in the fight today, Reductor protects the Chapter's future
(the mod's whole economy), Battle-Medic lets a squad of 4 bring a medic without losing a gun. Rank 7
is explicitly "today vs. tomorrow vs. right now."

## Librarian (force weapon + psychic hood)

Role: the psyker. Columns are the three classic disciplines so the fantasy itself is the choice:
**Pyromancy** (damage and area denial), **Telepathy** (control and Will warfare),
**Biomancy/Telekinesis** (bodies and objects). Every psychic power carries a **Perils of the Warp**
risk. This is the shared cost that keeps raw power honest.

**Perils of the Warp (built 2026-10-17, `X2Ability_Astartes_Librarian`).** Decision: no Warp Charge *pool*;
cooldowns stay vanilla and the resource is *risk*. Each power has a Warp Charge rating (1 minor, 2 major,
3 cataclysmic) and rolls for Perils after it resolves: 8% / 14% / 20%, less 3% with a Mk II Psychic Hood
and 6% with a relic hood (so the hood is the Librarian's real upgrade). A failed roll draws from a weighted
table modelled on the tabletop one (weights in `XComAstartes.ini`):

| Outcome | Weight | Effect |
|---|---|---|
| Warp Surge | 1 | The power succeeds *and* the Librarian regains an action |
| Psychic Backlash | 3 | 2-4 damage that ignores armour |
| Warp Shock | 3 | Stunned |
| Mental Purge | 2 | Every psychic power goes on a 3-turn cooldown |
| Dragged into the Warp | 1 | A daemon bursts out on his tile, hostile. The Librarian is KIA and his geneseed is lost (the Apothecary cannot harvest him). It is a *greater* daemon from mission one, by decision: that is the point of Chaos. The daemon is `Astartes_GreaterDaemon`, our variant of the RE2 G-Virus mod's G3 form (30 HP, 3 armour, melee monster with its own AI); vanilla Gatekeeper if that mod is not loaded. Force-level tiers (`PerilsDaemons`) are supported in config for anyone who wants mercy |

Overall a minor power loses the Librarian 0.8% of the time, a cataclysmic one 2%; over a campaign of
hundreds of casts that is a real chance, which is the point. Future hooks: Chaos-heavy regions raise the
base chance; the Tactical **Chapter Banner** lowers it; a Chapter relic could let a lost brother be
rescued from the daemon instead of killed. Dev command: `Astartes_ForcePerils <Outcome>`.

| Rank | Pyromancy | Telepathy | Biomancy / Telekinesis |
|---|---|---|---|
| 1 | `Soulfire` re-skin, **Smite**: guaranteed-hit psychic bolt, biological targets only. | `Insanity` re-skin, **Terrify**: panic or disorient a target. | `Stasis` re-skin, **Quickening** (self only at this rank): take a free move. 3-turn cooldown. |
| 2 | **Flame Breath (new)**: cone of fire, sets tiles burning. 1 charge. | **Psychic Scream (new)**: all enemies in 4 tiles lose Will and may panic. Cooldown. | `Inspire` re-skin, **Might of Heroes**: ally gets +damage and +mobility for a turn. |
| 3 | **Molten Beam (new)**: line attack through cover, armor pierce. | `MindControl` re-skin, **Dominate**: control a non-elite enemy for 2 turns. | **Telekine Shield (new)**: ally gains 3 shield HP, absorbs the first hit. |
| 4 | **Fire Shield (new)**: self aura, adjacent attackers take fire damage. | `Fuse`: detonate a target's explosives. | `Stasis` real: a unit is removed from the fight for a turn. |
| 5 | **Fury of the Ancients (new)**: 3-tile burst, heavy damage, Warp Charge 3 (Perils 20%). | **Puppet Master (new)**: Dominate works on elites, 1 charge. | **Smite the Earth (new)**: destroy a 3x3 of cover and knock back units. |
| 6 | `Sustain`: survive one lethal hit per mission at 1 HP (lore: warp-fuelled vigour). | **Hallucination (new)**: target attacks its own side next turn. | **Vortex of Doom (new)**: large area, pulls enemies to the center and damages. Once per mission. |
| 7 | **Firestorm (new)**: every enemy in sight is set on fire; Will cost scales with count. Once per mission. | **Null Zone** `NullZone` re-skin, **Psychic Hood**: all enemy psykers in 8 tiles lose their powers for 2 turns; counters Chaos sorcerers and Eldar seers. | `VoidRift` re-skin, **Warp Quake**: a huge burst that also stuns daemons and Warp-dependent units for a turn. |

Hard-choice check: Pyromancy is the Tyranid/Ork horde answer and the riskiest, Telepathy is the
anti-Chaos/anti-Eldar duel column and the only psyker counter, Biomancy makes the Librarian a
force multiplier and the safest. Perils keeps Pyromancy from being "the damage column" by default.

---

## Cross-class synergies (deliberate)

- Apothecary **Undying/Interment Rites** + Assault **Undying** = the Dreadnought pipeline.
- Tactical **Chapter Banner** + Librarian Perils = Will aura lowers Perils risk.
- Devastator **Suppressor** + Assault **Blade** = suppressed enemies cannot react to charges.
- Librarian **Telekine Shield** + Devastator **Emplacement** = immovable gun position.
- Apothecary + Chaplain (unique) = body-and-soul bonus (design.md §4.4).

## Open balance questions for review

1. Is Assault rank 5 (Duelist / Implacable / Undying) too hard? It is meant to be the hardest pick in the mod.
2. Apothecary **Recover Geneseed** at rank 1 is mandatory for the economy. Should it be a class
   passive outside the tree so the rank-1 choice stays a real choice? (Recommendation: yes, make it
   innate; replace the slot with **Enhanced Narthecium**: +1 heal charge.)
3. Does Perils of the Warp need a visible UI indicator? (Recommendation: yes, like the Templar's Focus bar.)
4. Rank 7 "once per mission" powers: should some be "once per campaign" relic abilities reserved for the uniques instead?

---

## Ideas borrowed from other class mods (reviewed 2026-10-17)

**Guardsmen_WotC** (Workshop 1139714141), a 15-ability single class. Worth stealing:
- *On Guard / Vigilance*: +defense per enemy in sight (cap 25). Perfect for Guard militia and the Officer's **Hold the Line** flavour: the more enemies, the steadier the line.
- *Fervor*: +1 action per turn for -5 mobility. A natural **Terminator** stance trade (bulk for tempo).
- *Volley Fire*: shot at -10, and a second at -5 if it hits. Cleaner than Rapid Fire for **Bolter Drill**.
- *In the Zone*: activated, primary kills refund actions, 4-turn cooldown. Candidate for Assault **Whirlwind** instead of a flat Reaper clone.
- *Full Kit / Minefield*: bonus charges per equipped item. Devastator **Weapon Mount** and Officer **Call Fire Team** could use the same effect.
- *Improved Survival Gear*: fire + gas immunity passive, same shape as **Astartes Physiology**.
- It is built on **XModBase**, an ability-authoring library (conditional bonuses, cost refunds, reserve action points, stat changes, event-listener triggers). Adopting XModBase for our own abilities would cut the UnrealScript for most "(new)" abilities to a few lines each. **Adopted 2026-10-17**: first seven Tactical abilities built on it (`X2Ability_Astartes_Tactical`).

**The Servoskull** (Workshop 1193993048): a gremlin-type item (`X2Item_Servoskull`) with its own cosmetic unit. The Apothecary's **Narthecium** can be a clone of this item rather than a gremlin re-skin.

## Librarius power ideas from the subscribed psi mods (reviewed 2026-10-17)

Source material: Iridar's Psi Overhaul, Even More Psionic Abilities, Rusty's Psionic class, Jedi Class Revised,
Imperial Surplus Force Weapons. (Warp Warden is config-only on other perk packs; nothing new.) Mapped onto the three
disciplines. Mechanics only; names are ours.

**Pyromancy (damage, area, fire)**
- *Soul Storm* (Iridar): psionic meteors on an area, destroys cover -> **Fury of the Ancients** done right.
- *Frostfire Blast* (EMPA): guaranteed psi damage ignoring cover and armor, burns -> **Smite** tier 2 / **Molten Beam**.
- *Force Lightning / Chain Lightning* (Jedi): single and chained arcs -> Pyromancy's **Flame Breath** could chain instead of cone, which reads very "warp lightning".
- *Force Drain* (Jedi): damage all around you, heal yourself -> **Fire Shield** variant that feeds the Librarian.

**Telepathy (control, Will)**
- *Jedi Mind Tricks*: zero move/sight/detection, does not break concealment -> **Hallucination** / a stealth-opener for Librarians.
- *Force Fear*: fear that cascades -> **Terrify** upgrade (**Psychic Scream**).
- *Reimage* (EMPA): control that makes the target attack its own side -> **Puppet Master**.
- *Reformat / Void's Adjuration* (EMPA): permanent control, one per mission -> too strong for a Marine; reserve for the **Chief Librarian** relic tier.
- *Force Choke*: ranged single-target damage + stun -> a Telepathy damage option so the column is not pure utility.

**Biomancy / Telekinesis (bodies and objects)**
- *Force Push / Force Shove / Force Wind* (Jedi, Imperial Surplus): knockback, cancel overwatch, stun chance, environmental destruction -> **Smite the Earth** and a new rank-2 **Telekine Shove** (replaces the stand-in for Might of Heroes).
- *Null Ward* (Iridar): shields on self and nearby allies, collapse if caster dies -> **Telekine Shield** as an aura instead of single target.
- *Soul Merge* (Iridar): link to an ally, they gain action + stats while linked -> **Might of Heroes** exactly.
- *Soul Mend / Panacea* (Rusty): psionic body heal / mind heal -> Biomancy **Quickening** could heal; mind heal = **corruption cleanse** (a Librarian alternative to the Chaplain, at Perils risk).
- *Phase Walk* (Iridar): short teleport -> Biomancy mobility pick; also the Terminator deep-strike visual.
- *Force Speed*: three non-ending actions this turn -> **Quickening** at rank 7 instead of rank 1.
- *Battle Precognition / Battle Meditation* (Jedi): pre-emptive melee strike, deflect shots -> the force-sword duellist flavour for the Librarian's melee slots.

**Resource model.** The Jedi mod's **Force Power pool** (spent per power, holocrons raise the cap, Meditation refills it at
the cost of vulnerability) is the right skeleton for **Warp Charge**: powers cost charge; Perils of the Warp triggers
when a Librarian casts with low charge or above his rank; a "focus" action refills charge but leaves him exposed.
This makes "cast everything every turn" impossible without copying Templar Focus. Decision pending.

**Known crashers to avoid copying** (from the user's Jedi playtests): Reflect (crash on the next action) and
Lightsaber Telekinesis (crash on mission exit). Deflect and Lightsaber Toss were stable.

## Implementation status (2026-10-17, end of day one)

| Class | Real abilities | Vanilla used as final | Still stand-ins |
|---|---|---|---|
| Tactical | Bolter Drill, Kraken Rounds, Hellfire Rounds, Executioner, Rally, Inspire, For the Emperor | Lightning Hands, Return Fire, Untouchable, Covering Fire, Suppression, Ever Vigilant, Rapid Fire, Sentinel, Kill Zone | Tactical Doctrine, Hold the Line, Chapter Banner, Combat Squads, Codex Volley |
| Assault | Chain Teeth, Whirlwind, Duelist, Decapitate, Power Armour Veteran, **Jump Pack** | Fortress (Iron Halo), Quickdraw, Bladestorm, Implacable, Untouchable | Charge, Shock Landing, Hit and Run, Hold Fast, Hammer of Wrath, Undying, Deep Jump, Last Stand, Death from Above, Angel of Death |
| Devastator | Brace, Bipod, Tank Hunter | Suppression, Shredder, Holo Targeting, Chain Shot, Sentinel | ammo/zone mechanics: Plasma Overcharge, Lascannon Round, Sandbag, Grinding Advance, Heavy Stance, Fire Lane, Krak Missile, Weapon Mount, Hunker Them Down, Melta Round, Whirlwind Barrage, Castellan, Sweeping Fire |
| Apothecary | Recover Geneseed, Stimm Shot, Warrior Medic | Medical Protocol (Narthecium), Aid Protocol (Combat Stims), Restorative Mist (Mass Triage), Revival Protocol | geneseed-linked: Interment Rites, Reductor Mastery, Preservation, Purity Check, Honour the Fallen, Harvest, Miracle, Last Rites; Field Surgery, Augmentic Repair, Guardian, Combat Doctrine, Chirurgeon's Fury |
| Librarian | Smite, Flame Breath, Molten Beam, Fury of the Ancients, Terrify, Psychic Scream, Dominate, Quickening, Might of Heroes (clones of vanilla psionics under 40K names, via `Astartes_AbilityVariants`) | Fuse, Fortress | Fire Shield, Warp Bind, Puppet Master, Smite the Earth, Warp Vigour, Hallucination, Vortex of Doom, Firestorm, Psychic Hood power, Warp Quake. Perils of the Warp is live (passive + 5 outcomes incl. daemonic possession); no Warp Charge pool by decision. |
| Shared | Know No Fear, Astartes Physiology, Power Armour Mk VII stats | | |

Weapon and ability clones are created as named objects (`new(none, string(Name))`) so their 40K localization loads; unnamed clones showed vanilla names in play (fixed 2026-10-17, guarded by `tests/test_wargear.py`).

Librarians wear the Tacticus Hood on promotion (Astartes_ClassLook). Wargear: Bolter, Bolt Pistol, Chainsword/Power Sword/Relic Blade, Heavy Bolter, Force Sword, Psychic Hood, Narthecium as vanilla clones (X2Item_AstartesWeapons).

