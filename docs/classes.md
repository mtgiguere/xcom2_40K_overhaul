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
| 1 | `Blademaster` re-skin, **Chain Teeth**: +damage with chainsword. | **Jump Pack (new)**: move ignores terrain, costs full turn's movement, one tile landing damage. 2-turn cooldown. | **Power Armour Veteran (new)**: regenerate 1 HP per turn while above half HP. |
| 2 | `Shadowstrike` re-skin, **Charge**: +crit on melee after moving 6+ tiles. | **Shock Landing (new)**: landing from a jump disorients adjacent enemies. | `Fortress` re-skin, **Iron Halo**: immune to fire/poison/acid tiles. |
| 3 | `Reaper` re-skin (Ranger version), **Whirlwind**: every melee kill refunds the action, damage falls per kill. | **Hit and Run (new)**: after a melee kill, free jump out (uses cooldown). | `Shieldwall` re-skin, **Hold Fast**: +2 armor when adjacent to an enemy. |
| 4 | `Bladestorm`: free melee attack against anything that moves adjacent. | **Hammer of Wrath (new)**: jump landing deals AoE damage; 3-turn cooldown; cannot act after. | **Bolt Pistol Suppression (new)**: pin a target with the pistol, keep melee for next turn. |
| 5 | **Duelist (new)**: melee against a single-model elite (Chaos Marine, Eldar, Nob) ignores armor. | `Implacable`: free move after a kill. | **Undying (new)**: first time per mission you would die, drop to 1 HP and go bleeding-out instead. Apothecary synergy. |
| 6 | **Decapitate (new)**: melee that cannot miss, no crit, 4-turn cooldown. | **Deep Jump (new)**: jump range doubled, lands in concealment if no enemy saw you. | `Untouchable`. |
| 7 | **Death from Above + Blade (new)**: a jump followed by a melee attack in one action, once per mission. | **Angel of Death (new)**: three jumps this turn, no cooldown, mobility +4. Once per mission. | **Last Stand (new)**: while bleeding out you can still take one action per turn for 2 turns. |

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
risk: on a failed roll the Librarian takes Will damage, scaling with the power's rank. Chaos-heavy
systems increase the risk. This is the shared cost that keeps raw power honest.

| Rank | Pyromancy | Telepathy | Biomancy / Telekinesis |
|---|---|---|---|
| 1 | `Soulfire` re-skin, **Smite**: guaranteed-hit psychic bolt, biological targets only. | `Insanity` re-skin, **Terrify**: panic or disorient a target. | `Stasis` re-skin, **Quickening** (self only at this rank): take a free move. 3-turn cooldown. |
| 2 | **Flame Breath (new)**: cone of fire, sets tiles burning. 1 charge. | **Psychic Scream (new)**: all enemies in 4 tiles lose Will and may panic. Cooldown. | `Inspire` re-skin, **Might of Heroes**: ally gets +damage and +mobility for a turn. |
| 3 | **Molten Beam (new)**: line attack through cover, armor pierce. | `MindControl` re-skin, **Dominate**: control a non-elite enemy for 2 turns. | **Telekine Shield (new)**: ally gains 3 shield HP, absorbs the first hit. |
| 4 | **Fire Shield (new)**: self aura, adjacent attackers take fire damage. | `Fuse`: detonate a target's explosives. | `Stasis` real: a unit is removed from the fight for a turn. |
| 5 | **Fury of the Ancients (new)**: 3-tile burst, heavy damage, Perils risk doubled. | **Puppet Master (new)**: Dominate works on elites, 1 charge. | **Smite the Earth (new)**: destroy a 3x3 of cover and knock back units. |
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
