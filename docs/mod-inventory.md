# Subscribed Workshop mod inventory (2026-10-17)

331 items under `steamapps/workshop/content/268500`. Only the ones relevant to the 40K overhaul are
categorised; the full list is at the bottom. Team-slot facts verified against the WotC SDK
(`Core/Classes/Object.uc` ETeam enum) and the Community Highlander (`CHHelpers.uc`).

## Player-side 40K art
| Mod | ID | Notes |
|---|---|---|
| Space Marine 2 Tacticus Armor | 3457562492 | 445 MB, ~1100 body parts. Primary Marine look. |
| Space Marine 2 Gravis Armor | 3459640872 | Heavy pattern. Terminator stand-in candidate. |
| Space Marine 2 Phobos Armor | 3450281558 | Light pattern. Scout stand-in candidate. |
| Space Marine 2 Chaplain Armor | 3454751781 | Chaplain / Master of Sanctity. |
| Space Marine 2 Deathwatch Armor | 3443715780 | |
| WH40k SpaceMarine Armor | 1412506430 | Older, small set (classic Mk VII). |
| Space Marine 2 Dreadnought SPARK | 3461880832 | Torso/arms/legs for `SparkSoldier`, all 3 SPARK armor tiers; open/closed sarcophagus, Ultramarines + tintable. |
| WH40k_SisterOfBattle_Armor | 1417074510 | |
| Imperial Guard 40k Helmets mod | 1312608118 | Astra Militarum set (torso/legs/helmets too). |
| Space Marine 2 Cadian Imperial Guard Armor | 3470263959 | |
| Warhammer40KNecron | 2025800523 | Necron soldier skin (cosmetic). |
| Add* chapter flags | 622070992 etc. | Blood Angels, Dark Angels, Imperial Fists, Salamanders, Ultramarines, Loyalist Legions, Chaos Legions, Chaos Undivided as "countries". |
| 40K Names For Soldiers | 1563135968 | Name generator override. |
| Ultimate Character Pool Warhammer 40k | 3653071156 | |
| 40KBoltPistolsMod / 40KPlasmaPistolsMod / 40KPowerclawsMod | 1495590206 / 1497538465 / 1517417627 | Full weapon templates w/ schematics, 3 tiers, config-driven stats. Good pattern for bolters. |
| Voicepacks (11) | various | Force Commander, Librarian, Tactical Sgt, Apothecary, Assault Sgt, Chaos Lord, Ork, Scout Sgt, Scout, Chaplain, Space Marine, Tactical, Terminator, WAAAAARGH!, Chaos Sorcerer, Eliphas, Khorne Berserker. |
| ASI40kCS | 848376030 | 40K squad icons for LW squad barracks UI. |
| Warhammer40KRPGOVanillaThemedClassIcons | | 40K class icons for RPGO. |

## Chaos art
| Mod | ID | Notes |
|---|---|---|
| Space Marine 2 Chaos Armor | 3479475586 | 378 MB. |
| Space Marine 2 Thousand Sons Armor | 3513992564 | |
| World Eaters Armors | 1398611395 | 2.5 GB. Includes **Kytan** and **Decimator** daemon-engine bodies as SPARK skins. Chaos Dreadnought / boss candidate. |

## Enemy factions (complete, new models)
| Mod | ID | Team | Notes |
|---|---|---|---|
| DarkEldar_Raiders | 1904215974 | `eTeam_Two` via HL `ModAddedTeams` | ~40 character templates: Kabalite Warriors (3 tiers, Sybarite, Splinter Cannon, Dark Blaster), Wyches/Hekatrix, Wracks, Grotesques, Haemonculus, Succubus, Archon/Dracon, Incubus, Scourges. Own voices, UI, weapons. Added by SitRep; supports "Raider Faction Bases" framework (not subscribed). **Ready-made Eldar wildcard.** |
| Dark Eldar Plugin | 1976289979 | | Same armor made wearable by XCOM soldiers. |
| The Hive | 1918499687 | `eTeam_One` | Chryssalid faction: Hybrids, Zombies, Brood Mother, Chameleon, Drone, Hive Guard, Rippers, Juvenile Queens, Hive Queen. Custom anims/FX, cinematic maps. **~80% of a Tyranid faction.** |
| LostHive | 3099917923 | | Config-only. Re-points every `TheLost_*` encounter from `eTeam_TheLost` to `eTeam_One` (The Hive). Exact pattern for "Lost -> gaunts". |
| WOTCAlienElitePack | 1563023889 | Alien | Muton Elite, Sectoid Commander, Viper Elite (LW ports). |

## Technique references
| Mod | ID | What it demonstrates |
|---|---|---|
| Reaper{Banshee,Brute,Cannibal,Praetorian}Replacer | 2328289644 etc. | **Pawn swap by config**: `+RemovePawns=` / `+AddPawns=` on a character template, one small class. This is how Berserker -> Carnifex, Muton -> Ork Boy etc. would be done once a model exists. |
| X2_MissionCaptureZone | 3810810829 | Kismet SeqActs for capture zones / timers. Warzone Crossing building block. |
| Additional Mission Types Redux | 1133287457 | New mission types, faction soldier units, narrative. |
| FBmissionpack2 | 1768950112 | Skyranger Down, Protect the Device, Destroy Relay; resistance reinforcements. |
| WOTC_FactionAnchor | 2387956032 | Keeps an extra-team faction alive until last unit dead. |
| IridarsPsiOverhaul, Even More Psionic Abilities, WOTC_RustyPsionic, VCP_WarpWarden | | Psi ability/class examples for the Librarius track. |
| JediClassRevised | 2031929512 | 55 classes; full custom force-power class. Librarian template. |
| XCOM2RPGOverhaul + perk packs | 1280477867 | Class/spec framework; alternative to hand-built classes. |
| Long War of the Chosen | 2683996590 | Regional strength / liberation / infiltration reference. Reference only, not a dependency. |
| LW_Overhaul | 844674609 | **Vanilla LW2, not WotC.** Will not load with WotC. Unsubscribe. |
| X2WOTCCommunityHighlander | 1134256495 | Required framework. |
| WOTCIridarTemplateMaster | 2363075446 | Config-driven template editing. |
| Mod Config Menu | | In-game settings UI. |

## Subscribed but NOT yet downloaded (as of 2026-10-17, Steam still pulling ~10 GB)
Steam's `appworkshop_268500.acf` lists 403 subscriptions vs 338 folders on disk. The 40K-relevant pending ones:

| Mod | ID | Size | Why it matters |
|---|---|---|---|
| **Ork Raiders** | 3655297403 | 1.0 GB | Ork enemy faction (Raider framework, like Dark Eldar Raiders). Closes the Ork gap. |
| **Lost2Ork - OPEN BETA** | 1765652830 | 1.0 GB | Lost replaced by Ork horde. Waaagh! mob mechanic reference. |
| **Eldar Armor [WOTC]** | 1872771143 | 0.9 GB | Craftworld Eldar armor (player-wearable -> enemy humanoids). |
| **Eldar Weapons [WOTC]** | 1872776042 | 1.0 GB | |
| Black Legion | 1582632067 | 0.9 GB | Chaos Marine armor set. |
| [WOTC] Space Marine Weaponry (Warhammer) | 3656755854 | 117 MB | Bolters etc. |
| BolterWeaponMod | 1493097153 | 21 MB | |
| 40kMechanicus | 1943761564 | 40kAdMec_MechanicusPowerAxe/OmnissianPowerAxe/MechanicusPowerSword/TransonicBlade CV/MG/BM, arc and phosphor guns | **In use**: the Crozius wears the Mechanicus power axe. Power sword and Omnissian axe are alternatives; the ranged kit is Mechanicus faction material later |
| TheAxeMod / LegacyKatanaMod / NightsisterGear | 718190620 / 698579656 / 2858248083 | Axes, katanas, vibrostaff (sword cat) | Alternative crozius/power-sword looks; not wired |
| Space Marine Class Pack | 3789746906 | 0.5 MB | Someone already built Marine classes; inspect before writing ours. |
| Storm Eagle Replacer | 1563067479 | 530 MB | Skyranger -> Storm Eagle gunship. |
| WotC: Skyranger Skins | 1346067153 | 65 MB | |
| Guardsman Militia | 1587389950 | 0.3 MB | Imperial Guard as resistance militia (config). |
| Kasrkin [WotC] | 1139643280 | | Guard elite cosmetics. |
| The Lasgun - WOTC Edition | 1237846886 | 109 MB | |
| MEC Troopers Redux / Mechatronic Warfare Perk Pack | 3260691408 / 2329989067 | | SPARK-track references for Dreadnought abilities. |
| Buildable Geth Redux | 1134160419 | 185 MB | Example of a *buildable custom SPARK-type unit* (Dreadnought mechanic reference). |
| [WOTC] Jet Packs | 1576958692 | 70 MB | Assault Marine jump packs. |
| [WOTC] Dual Wielded Pistols 2.0, True Primary Secondaries | 1494099360 / 2133399183 | | Weapon-slot frameworks. |
| [WOTC] WSR Weapon Skin Replacer - Core | 1517938486 | | Weapon reskin framework. |
| [WOTC] Alien Hunters Community Highlander | 2534737016 | | Needed if Alien Hunters units are used. |
| Voicepacks | various | | Chaos Space Marine, Obliterator, Titus, Dreadnought, Gabriel Angelos, Avitus, Canoness Selena, Commissar Lord Bernn. **Eldar ruler cast:** Farseer Macha, Archon Tahril (DoWArchonVoicePack), Autarch Kayleth. |

The remaining pending items are Fortnite/Marvel/RE outfits and non-40K voicepacks.

## Downloaded 2026-10-17 (second wave) - inspected
| Mod | ID | Verdict |
|---|---|---|
| **Ork Raiders** | 3655297403 | Complete Ork faction, same "Raider" pattern as Dark Eldar (RealityMachina style). 15 unit types x 3 tiers: Slugga/Shoota/'Ard/Burna/Skar Boyz, Stormboyz (teleport-jump), Lootas (Deffgun/Zzap/Plasma), Nobz, Meganobz, Gretchin, **Weirdboy** (psyker), **Deff Dread**, Warboss + 2 named Warbosses. Own voices, weapons, UI. Two Ork "kamps" on `eTeam_One` and `eTeam_Two` so **Orks fight Orks**; `XComRaiderRelations.ini` defines rival groups. Force-level-bucketed encounter lists (Weak/Normal/Strong/Boss at FL1/10/16). |
| **Lost2Ork** | 1765652830 | Lost replaced by Orks via character templates with per-HP variants. Horde reference. |
| **Black Legion** | 1582632067 | **Full Chaos Marine enemy faction**, not an armor pack: Marine, Assault, Raptor (jump), Havoc/Flamer, Berserker, Captain, Lord, melta variants, 3 tiers, own weapons + voices. On `eTeam_Two`. **Has a Geoscape base system**: `XComGameState_BlackLegionBase(Manager)`, `UIStrategyMapItem_BlackLegionBase`, covert actions and rewards, listens to `RegionContacted`. This is a working prototype of design.md §7.2 "system strongholds". |
| **Space Marine Class Pack** | 3789746906 | Config-only; 10 classes (Field Commander, Assault, Tactical, Scout, Devastator, Tech Marine, Apothecary, Chaplain, Librarian, Dreadnought) built from other perk packs (LW2, Mitzruti, Shadow Ops, Favid's). Random ability decks. Useful as a loadout/weapon-type reference; our tree design stays. |
| **Buildable Geth Redux** | 1134160419 | Exact Dreadnought pattern: `X2SparkCharacterTemplate_DLC_3` subclass, Proving Ground techs (`bProvingGround=true`) that create the unit, custom country, custom character generator and pawn, custom customization UI. |
| **Customize Soldier Size** | 1147128235 | Scale via `Mesh.SetScale()` on the pawn from a per-unit value ("BodySize") read from the unit state (`CharacterPoolHelper.ApplyScale`). Our Terminator/Guard scaling can set the same unit value from the armor/character template. |
| **Eldar Armor / Eldar Weapons** | 1872771143 / 1872776042 | Player items: Aspect/Heavy Aspect/Rune/Swooping Hawk armors (3 tiers, abilities), shuriken catapults, witchblades, power glaives, Banshee masks (Howl), Mandiblasters, forceshields, flamers/firepikes. Reusable on enemy humanoid templates for Craftworld Eldar. |
| **[WOTC] Jet Packs** (Iridar) | 1576958692 | Flight, Jet Shot, Rocket Punch/Slam, Crater, Dynamic Deployment, Emergency Evac. Assault Marine jump-pack basis. |
| **Storm Eagle Replacer** | 1563067479 | Skyranger -> Storm Eagle, with Sisters of Battle comm-link UI. |
| **Guardsman Militia** | 1587389950 | Haven/resistance militia as Imperial Guard (character + name generator + weapon skin replacer). |
| **Lasgun, BolterWeaponMod, Space Marine Weaponry, Plasmagun** | 1237846886 / 1493097153 / 3656755854 / 1499457957 | Weapon templates with schematics. |

Not subscribed but referenced by the Raider mods (optional): **Raider Faction Bases** (`X2Helpers_RM_RaiderBases`) and **Raider Relations** (`X2Helpers_RaiderRelations`). Worth adding: they make raider factions appear as Geoscape bases and fight each other.

## Gaps
- **Tyranid-specific** models: none (The Hive covers the role).
- Advent to Imperium, Raider Faction Bases framework: not subscribed (Ork Raiders / Dark Eldar Raiders may bundle or require it; check once downloaded).
- Orks: covered (Ork Raiders). Craftworld Eldar: armor/weapons exist; enemy templates must be written.
- Loyalist Terminator armor: none on the Workshop (Armours of the Imperium is hidden). Use Gravis + scale.

## Team slots (verified)
`ETeam` has exactly two spare hostile slots, `eTeam_One` (2) and `eTeam_Two` (4); every other value is `DONT_USE`.
Highlander comment: "eTeam_One and eTeam_Two should be the only ones here." The Hive takes One, Dark Eldar takes Two.

## Full list
- 40K Force Commander Voicepack `648677935`
- 40K Librarian Voicepack `643809627`
- 40K Names For Soldiers `1563135968`
- 40K Tactical Sergeant Voicepack `634922280`
- 40KBoltPistolsMod `1495590206`
- 40KPlasmaPistolsMod `1497538465`
- 40KPowerclawsMod `1517417627`
- A2X_AnimationSocketsSupplement `1943613600`
- ABBPerkPack `1993868715`
- Ability To Slot Reassignment `2133397762`
- AccurateSituationReport `2567229533`
- AddBloodAngels `622070992`
- AddChaosLegions `626245748`
- AddChaosUndivided `627060057`
- AddDarkAngels `621620908`
- AddImperialFists `622045333`
- Additional Mission Types Redux `1133287457`
- AddLoyalistLegions `623755352`
- AddSalamanders `622789644`
- AddUltramarines `622761570`
- Agent Venom `3507400984`
- AlienArmorCustomization `1595591864`
- Allies Unknown Evac Zone Fix `1124713229`
- AOT_Hange_Zoe `3724206629`
- AOT_Ymir `3721608032`
- ASI40kCS `848376030`
- B4B_Karlee_Fincher `3785972010`
- B4B_Karlee_Fincher_BH `3786512273`
- B4B_Karlee_ZWAT `3789481656`
- BayonettaClimax `2836026723`
- BayonettaVoicePack `1566525595`
- Better Second Wave Support `1149493976`
- BG3_Orin_the_Red `3686839607`
- BL2_Siren_Lilith `3629719027`
- BL2_Siren_Maya `3600341943`
- Black_Panther `3409461095`
- Bombshell `3819377194`
- BstarsPerkPack `2115077818`
- Bumblebee SPARK `3408923946`
- BunnyKitten `3595483740`
- Cannon Animation Redux `1541141667`
- Captain_Marvel `3410901268`
- Chimera Squad Ability Icons `2094355561`
- ClaireVoice `2681176073`
- COC Jane Foster `3430482024`
- COC_Beast `3423171711`
- COC_Ironheart `3426205453`
- COC_Luke_Cage `3428932043`
- COC_Photon `3424767294`
- Codwatcher `3367908965`
- Commanders Choice `688405905`
- CompletelyInvisibleHeads `1943567671`
- CortanaVoice `2796950566`
- CP2077_Altiera_Cunningham `3769284351`
- CP2077_Panam_Palmer `3766053729`
- Cryo Perk Pack `2066389408`
- CRYSIS NS `3658950353`
- CSO2_Helga `3472426381`
- Dark Eldar Plugin `1976289979`
- DarkEldar_Raiders `1904215974`
- Dbdskullmerchant `3231150528`
- DCL_Huntress `3431073243`
- DCUO_Superboy `3431775862`
- Dead Space Ellie Langford `3568857908`
- DFFNT_Squall_Leonhart `3810832093`
- DinaVoice `2850353398`
- DisableAnyClassWotc `2956818409`
- Dissidia Final Fantasy Squall Leonhart Voice Pack `2215441148`
- Dissidia Final Fantasy Tifa Lockhart Voice Pack `2206730074`
- DissidiaYunaVoiceMod `2550783907`
- DMC5_Gloria_Trish `3751487557`
- Dual Wield Melee `1439279281`
- E33_33_Lune `3564863946`
- E33_33_Sciel `3565401856`
- Empty WOTC Deco Slots for XCOM Soldiers `1127014384`
- EvacAll_WotC `1126395106`
- Even More Psionic Abilities `3703758245`
- Fate Officer Class `3730463883`
- FBmissionpack2 `1768950112`
- FFVIIEC_Tifa_Lockhart_Bahamut `3807351310`
- FFXIII_Oerba_Yun_Fang `3749974349`
- FFXVI_Benedikta_Harman `3807814453`
- FFXVI_Jill_Warrick `3809753171`
- Finalpaine `3238469631`
- First_Descendant_Hailey `3424648059`
- First_Descendant_Sharen `3439864837`
- FN ChampH `3503024649`
- FN CLARA `3733615979`
- FN Cyborg `3551148815`
- FN EJULES `3727530712`
- FN HeroicH `3605898737`
- FN Killswitch `3532574644`
- FN Moon Knight `3442442089`
- FN Sarah `3508440125`
- FN Scrap Jules `3469779718`
- FN Shuri `3433821958`
- FN Sofia `3497268002`
- FN Sorana `3549421480`
- FN VanZad `3475031325`
- Fortnite Blade `2806538063`
- Fortnite Kor `3549317354`
- Fortnite Lara Croft `3438220920`
- Fortnite Wonder `3480446043`
- Fortnite X23 `3451811941`
- Fortnite_Ant_Man `3409606626`
- Fortnite_Ben_Grimm `3622538092`
- Fortnite_Firehawk_Lilith `3795726816`
- Fortnite_Iron_Man_Prime `3433284318`
- Fortnite_Johnny_Storm `3624554978`
- Fortnite_Lady_Windfrost `3708671351`
- Fortnite_Reed_Richards `3625094600`
- Fortnite_Solid_Snake `3599290224`
- Fortnite_Spider_Woman `3629114130`
- Fortnite_Susan_Storm `3625641367`
- Fortnitecable `2887030720`
- Fortnitecatwoman `3114645583`
- Fortnitecolossus `3382707767`
- Fortnitecyclops `3379252485`
- Fortnitedeadpool `3281175906`
- Fortnitedune `3107919870`
- Fortnitegamora `3109841371`
- Fortniteironman `3377256526`
- Fortnitejill `3136658684`
- Fortnitenatasha `3382056864`
- Fortniteraven `2845116336`
- Fortnitesamwilson `3280384784`
- Fortnitewarmachine `3377973853`
- Fortnitexeno `2846503779`
- GF2E_Nemesis `3587065596`
- GFL2_Helen `3618413540`
- GITS_CH_Motoko_Kusanagi `3719895157`
- GITS_Saito `3480596588`
- GITS_Togusa `3478179773`
- GOW5_Kait_Winter `3469812727`
- GOW5_Onyx `3469979679`
- GOW5_VDAY_Sam `3480652986`
- helenavoice `3733906708`
- Heroesmasks `3270591342`
- Imperial Guard 40k Helmets mod `1312608118`
- ImperialSurplusForceWeapons `2171892934`
- Invisible Heads `646749278`
- InvisibleLimbs `2146403415`
- IridarsPsiOverhaul `1662114279`
- JediClassRevised `2031929512`
- JediClassRPGOPlugin `2102085393`
- Jericho_Black `3456067795`
- Jericho_Church `3451974712`
- Jericho_Cole `3456192295`
- Jericho_Xavier `3453950982`
- JillVoice `2713044242`
- KarleeVoice `2643749098`
- kasumivoice `3731823701`
- Ketaros2DResources `1557951815`
- KPPPerkPack `3231706929`
- Left4deadzoey `3225073196`
- Legendsecho `2948717058`
- Long War 2 Abilities for WotC `1335226018`
- Long War of the Chosen `2683996590`
- LostHive `3099917923`
- Lucubrations Infantry Class Wotc `1128300381`
- Lucubrations Sniper Class Wotc `1131082568`
- LW_Overhaul `844674609`
- MA Warmachine `3682927038`
- MaraSovSquadmateMod `3012702664`
- MaraSovVoiceMod `3012693887`
- MarkIVCore `3398372784`
- Marvelscap `3385784540`
- MasterChief(John-117)VoicePack `3602415129`
- MasterChiefCortanaVoicepack `3602427476`
- MFF Quasar Wendall `3445983435`
- MFF Rescue `3430860975`
- MFF_IIM_War_Machine `3677201768`
- MFF_Moondragon `3420674614`
- MFF_Nova `3421275788`
- MFF_Quicksilver `3421407495`
- MFF_Red_She_Hulk `3783469007`
- MFF_Wasp_Nadia `3626825524`
- MirandaVoice `2593914005`
- Mitzruti Perk Pack `1561030099`
- MiyaVoice `2487708602`
- Mod Config Menu `667104300`
- ModSkin_AyaneNG4 `3605311197`
- ModSkin_M_Captain_Mar_Vell `3618541206`
- ModSkin_M_Darkhawk `3622596063`
- ModSkin_M_HTUI `3624297641`
- ModSkin_M_Hyperion `3620466867`
- ModSkin_M_Mockingbird `3619218596`
- ModSkin_MGSD_Eva_Suit `3708998919`
- ModSkin_SB_Orca_Pathfinder `3687633153`
- ModSkin_SB_Planet_Diving_Suit_2nd `3669438034`
- ModSkin_SB_Raven `3644124779`
- ModSkin_SB_Tachy_Suit `3698873487`
- MR Invisible Woman `3456078896`
- MR Iron Man `3432867637`
- MR Magik `3477459445`
- MR Wolverine `3485815458`
- MR_Peni_Parker `3442159129`
- MR_Rival_Black_Widow `3708565870`
- MR_SPdr_Venom `3531452687`
- MSF Crystal `3431798842`
- MSF Songbird `3579323396`
- MSF Spider Woman `3441988222`
- MSW Sersi `3432174793`
- MSW The Wasp `3441856466`
- MUA_Thor `3415476786`
- MUA_Wasp `3413335337`
- MUA3 Black Panther `3438280466`
- MUA3 Daredevil `3442980744`
- MUA3 Iceman `3445275249`
- MUA3 Valkyrie `3457169136`
- nellvoice `3782285462`
- New Promotion Screen by Default `1124609091`
- NIER_Type_A2 `3791138180`
- Nightwing `3296140665`
- No Invisible Heads On Randoms `1311131438`
- OptimusSPARK `3414031419`
- Overwatchmercy `3223424258`
- P5_Makoto_Queen `3578514396`
- PHG Dutch `3463765151`
- Primary Secondaries `1142234205`
- rachelvoice `3733752136`
- RC_Rogue_Lancer `3750423946`
- RC_Rogue_Phantom `3750467622`
- RE_Rachel_Foley `3429635614`
- Re9_Grace_Skin_MoDS `3744382662`
- ReaperBansheeReplacer `2328289644`
- ReaperBruteReplacer `2328289215`
- ReaperCannibalReplacer `2328289015`
- ReaperPraetorianReplacer `2328288326`
- ResistanceOperationOverhaul `2647635178`
- Reverse Jill `3554148093`
- Reward Decks Refresher `665435869`
- robojumperSquadSelect `1122974240`
- RPG Overhaul -Geomancer Class Specializations `3463823170`
- RPG Overhaul -Twmpes  Class Specializations `3463587961`
- RPG Overhaul Warp Warden Class Specializations `3464868250`
- RPGOMoreSpecializations `1491778957`
- SA2 Miya `1331372042`
- SA2Leona `1345289584`
- Sephiroth `2863036140`
- Shadow Ops Perk Pack `1519841231`
- Signaliselster `3204076530`
- SM2 Blackcat `3522508433`
- SMITE_Da_Ji `3642250812`
- SMITE_Discordia `3693250733`
- SMITE_Neith `3641659646`
- SnakeVoice `2746587854`
- Space Marine 2 Cadian Imperial Guard Armor `3470263959`
- Space Marine 2 Chaos Armor `3479475586`
- Space Marine 2 Chaplain Armor `3454751781`
- Space Marine 2 Deathwatch Armor `3443715780`
- Space Marine 2 Dreadnought SPARK `3461880832`
- Space Marine 2 Gravis Armor `3459640872`
- Space Marine 2 Phobos Armor `3450281558`
- Space Marine 2 Tacticus Armor `3457562492`
- Space Marine 2 Thousand Sons Armor `3513992564`
- SquadBasedRoster `2604662194`
- Stellar_Blade_Eve `3504738623`
- Stellar_Blade_Lily `3507927520`
- Stellar_Blade_Tachy `3507244262`
- Super_War_Hawkeye `3419189613`
- TFD_Ines `3570511453`
- The Hive `1918499687`
- Thebatman2022 `3292881750`
- UA3 WSol `3412266355`
- Ultimate Character Pool Warhammer 40k `3653071156`
- UnrestrictedCustomization `2438621356`
- Uruk1VoiceMod `3243058075`
- Uruk2VoiceMod `3247979399`
- V_Valorant_Reyna `3595600330`
- V_Valorant_Viper `3588258404`
- Val Neon `3617731066`
- Val Sova `3615360449`
- VCP_WarpWarden `3445333328`
- WAAAAARGH! Voice Pack `1169965190`
- Warhammer 40K Apothecary Voicepack `1432656086`
- Warhammer 40K Assault Marine Sergeant Voicepack `1442184334`
- Warhammer 40K Chaos Lord Voicepack `1452428537`
- Warhammer 40K Ork Voicepack `1430790604`
- Warhammer 40K Scout Marine Sergeant Voicepack `1447280231`
- Warhammer 40K Scout Marine Voicepack `1455881628`
- Warhammer 40K Space Marine Chaplain Voicepack `1448879269`
- Warhammer 40K Space Marine Voicepack `1449060024`
- Warhammer 40K Tactical Marine Voicepack `1460928325`
- Warhammer 40K Terminator Voicepack `1437631254`
- Warhammer40KNecron `2025800523`
- Warhammer40KRPGOVanillaThemedClassIcons `2137905002`
- WH40k SpaceMarine Armor `1412506430`
- WH40k_SisterOfBattle_Armor `1417074510`
- WH40KCSVP `3771203387`
- WH40KETHVP `3767608688`
- WH40KKBVP `3762502164`
- World Eaters Armors `1398611395`
- WotC Ballistic Shields `1416242202`
- WotC Combat Knives `1135248412`
- WotC Stealth Overhaul `1135111760`
- WotC_AL_Wraith `1695282441`
- WOTC_APA_Class_Pack `1265143828`
- WotC_AVA_GinnyGear `1955067432`
- WOTC_ExtendedPerkPack `1546482849`
- WOTC_FactionAnchor `2387956032`
- WOTC_Female_Clothing_Pack `1586643354`
- WOTC_Hair_Pack `1471399748`
- WOTC_Head_Pack `1835888336`
- WOTC_LW2SecondaryWeapons `1140434643`
- WOTC_Male_Hair_Pack `1733669574`
- WOTC_Miranda_Squadmate `1163123939`
- WOTC_Nova_Squadmate `1131360448`
- WotC_Paragon_Belica `1775285605`
- WOTC_RustyPsionic `2360051437`
- WotC_SA2_HannaGear `1696878398`
- WotC_T7NinaOutfit `1397895113`
- WOTCAlienElitePack `1563023889`
- WOTCIridarTemplateMaster `2363075446`
- WOTCMusashiModFixes `2569592723`
- WOTCPulsefireCaitlyn `1547080108`
- WOTCRevertOverwatchRules `1127539414`
- WOTCRocketLaunchers `1775963384`
- WOTCXSkin `2337161588`
- X2_MissionCaptureZone `3810810829`
- X2WOTCCommunityHighlander `1134256495`
- X2WOTCCommunityPromotionScreen `2550561145`
- XCOM2RPGOverhaul `1280477867`
- Xlegendsazure `3173387059`
- Xlegendsblade `3265906622`
- Xlegendsdream `3179364577`
- Xlegendsfreyja `3269958175`
- Xlegendsmortis `3371915248`
- Xlegendsneph `3372335738`
- YetAnotherF1 `934236622`
- ZelfExtraDamagePatcher `2971495164`

## Daemons
| Mod | ID | Notes |
|---|---|---|
| Resident Evil 2: Remake G-Virus (Beta) | 2264204537 | Full enemy units (G1/G2/G3 forms, own AI, melee sweeps, a civilian that morphs). G3 = `Astartes_GreaterDaemon`, G2 = `Astartes_Daemon` via `Astartes_UnitVariants`. Used by Perils of the Warp possession; candidate for Chaos pods at high force level. |

**Daemon Prince (2026-10-18):** RE3 Nemesis Prototype (2400021624) stage-2 Nemesis is `Astartes_DaemonPrince`, the form a possessed
Librarian takes, so it differs from the G-Virus daemons a Sorcerer's rift lets through. Needs that mod ticked; Greater Daemon otherwise.

## 40K weapon models (reviewed 2026-10-17)
| Mod | ID | Templates | Use |
|---|---|---|---|
| Space Marine Armory ("Space Marine Weaponry (Warhammer)") | 3656755854 | WP_BoltRifle, WP_BoltPistol, WP_Chainsword, WP_PowerSword, WP_HeavyBolter, WP_AutoBolter, WP_BoltSniperRifle (CV/MG/BM) | **In use**: Bolter, Bolt Pistol, Chainsword (CV) and Power Sword (MG/BM), Heavy Bolter and Force Sword wear its models via `MeshFrom`; the whole pack is hidden from the armoury. Auto Bolter and Bolt Sniper Rifle reserved for Tactical options / Scouts |
| BolterWeaponMod | 1493097153 | BOLTER_CV/MG/BM (rifle) | Godwyn-pattern bolter; hidden, kept as an alternative look |
| 40KBoltPistolsMod | 1495590206 | BOLTPISTOL_CV/MG/BM (pistol) | Hidden, alternative look |
| 40KPlasmagunMod | 1499457957 | PLASMAGUN_CV/MG/BM (rifle) | **In use**: Astartes_PlasmaGun wears its models and bolt (confirmed blue in play 2026-10-18); donors hidden |
| 40KPlasmaPistolsMod | 1497538465 | PLASMAPISTOL_CV/MG/BM (pistol) | **In use**: Astartes_PlasmaPistol wears its models; donors hidden |
| 40KPowerclawsMod | 1517417627 | POWERCLAW_LEFT_CV/MG/BM (sword) | Terminator lightning claws later |
| LasgunWotC / The Lasgun | 1237846886 / 1081412760 | Lasgun, HotshotLasgun, MastercraftedLasgun, DecayedLasgun | Imperial Guard / Officer line later (two copies subscribed; keep the WotC one) |
| Spark Bolter | 945783807 | Bolter (sparkrifle) | Dreadnought heavy bolter later |
| Space Marine Class Pack | 3789746906 | 10 AA_* classes, no weapons/models | Its classes are removed from our class deck (`remove_from_deck`). Reference for its Dreadnought class |

Still without a 40K model: Psychic Hood and Narthecium (vanilla psi amp and gremlin meshes); a servo-skull mod is subscribed for the Narthecium look.

## Enemy psyker ability sources (reviewed 2026-10-18)
| Mod | ID | What | Use |
|---|---|---|---|
| Imperial Surplus Force Weapons | 2171892934 | lightning / shove as weapons | Chaos Sorcerer, Eldar Warlock main attacks (AI fires them as guns) |
| Mitzruti Perk Pack | 1561030099 | `MZ*` elemental psi abilities: Fireball, Burning Hands, Cinder Bolt, Fire Whip, Hellish Rebuke (fire); Poisonball, Fetid Breath, Malaise, Venom Bolt, Acid Bolt, Acid Spray, Evil Gaze (poison/acid); Ball Lightning, Stun Bolt, Electric Fingers, Thunderous Roar (shock); Soulshock, Psionic Bomb, Pandemonium, Kinetic Pull, Boulder Crush, Marionette Control | God-flavoured Chaos Sorcerers (Tzeentch fire, Nurgle plague), Tyranid synapse creatures (Zoanthrope: Soulshock / Psionic Bomb; Venom Cannon = Venom Bolt), Eldar Farseer (Pandemonium, Mind War = Soulshock). Enemy use needs behaviour-tree nodes per ability in XComAI.ini; optional with existence checks like the Jedi powers. UTF-16 loc file |
| Fate's Psionic Elementalist | 3481038872 | a soldier class built from the MZ abilities above (+ Iridar Null Ward / Phase Walk); ice powers come from the Cryo Perk Pack (2066389408) | Not needed itself: the abilities live in Mitzruti's pack. Remove from the class deck if enabled |

**Autarch candidate (noted 2026-10-18, not yet downloaded):** a "Psionic Swordmaster" class mod (psi + melee + speed). Reviewed when
Steam has it: its abilities as the kit of an **Autarch** ruler-style fight for the Eldar incursions (the Alien Ruler analogue), with
EldarArmor's Autarch helmets and the dressed-body technique. Whether its abilities carry AI nodes decides how much work that is.

## Animation sources
| Mod | ID | Use |
|---|---|---|
| *Alien Hunters DLC (vanilla)* | DLC_2 | **In use (2026-10-18)**: Jump Pack jet sounds (`DLC_60_SoundCharacterFX.IcarusJump_Burst_On`, `IcarusJump_High_Air`, `IcarusJetLand`) and flames (`DLC_2_FX_Icarus_Suit.P_Launch`, `P_Hover_Burst`, `P_Thruster_Main_L/R`). Found by reading the imports of Iridar's WOTC Jet Packs (1576958692), which uses the same assets; nothing of that mod is needed. |
| Jedi Class Revised | 2031929512 | Force Jump animation set (`AS_ForcePowers`: HL_ForceJumpStart/Loop/Stop) and ignition cue for the Jump Pack arc; optional, loaded by path when enabled. Its `Jedi` class is removed from our deck. Known crashers (Reflect, Lightsaber Telekinesis) are Jedi abilities we never grant. |
