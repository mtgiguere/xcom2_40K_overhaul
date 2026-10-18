//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_Astartes.uc
//  PURPOSE: Entry point for the Warhammer 40K overhaul. Campaign-start hooks, Highlander
//           hooks (recruit appearance), and the developer console commands (exec functions)
//           that double as the runtime test harness.
//---------------------------------------------------------------------------------------
class X2DownloadableContentInfo_Astartes extends X2DownloadableContentInfo;

/// Soldier classes this mod defines, in roster order. Kept in sync with tests/data/class_trees.json.
var config array<name> MarineClasses;

/// Lore default: Space Marines are male. Set true to let the generator roll female Marines
/// (they will wear whatever female-compatible armour exists, which today is XCOM gear).
var config bool bAllowFemaleMarines;

/// Body-part packs (DLCName values) that define the Marine look. Recruits are generated from
/// these packs only, when present. Empty list = vanilla random appearance.
var config array<name> MarineArmorPartPacks;

// ---------------------------------------------------------------------------------------
// Campaign lifecycle
// ---------------------------------------------------------------------------------------

/// Called when the player starts a new campaign while this mod is installed.
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_AstartesChapter Chapter;

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(StartState);
	Chapter.AssignContinentFactions(StartState);
	`log("Astartes: new campaign started",, 'Astartes');
}

// ---------------------------------------------------------------------------------------
// Continent faction ownership (Highlander hooks, issues #136 / #278)
// ---------------------------------------------------------------------------------------

/// Called per pod when a mission's encounter data is cached. SourceObject is the mission site.
static function PostEncounterCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject)
{
	RewritePodForContinent(Encounter, ForceLevel, XComGameState_MissionSite(SourceObject), "pod" @ EncounterName);
}

/// Called per reinforcement group. SourceObject is the BattleData, which knows the mission.
static function PostReinforcementCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject, optional XComGameState_BaseObject ReinforcementState)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSite;

	BattleData = XComGameState_BattleData(SourceObject);
	if (BattleData != none)
	{
		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(BattleData.m_iMissionID));
	}
	RewritePodForContinent(Encounter, ForceLevel, MissionSite, "reinforcements" @ EncounterName);
}

/// Replace an alien-team pod with a same-sized pod from the faction that owns the mission's continent.
static function RewritePodForContinent(out PodSpawnInfo Encounter, int ForceLevel, XComGameState_MissionSite MissionSite, string Context)
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Continent Continent;
	local FactionDef Def;
	local name FactionName;
	local array<name> NewTemplates;
	local string Before, After;
	local int i;

	if (!class'Astartes_FactionConfig'.default.bEnableContinentFactions || MissionSite == none)
	{
		return;
	}
	if (Encounter.Team != eTeam_Alien || Encounter.StrategyUnitTag != '' || Encounter.SelectedCharacterTemplateNames.Length == 0)
	{
		return;
	}

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	Continent = MissionSite.GetContinent();
	if (Chapter == none || Continent == none)
	{
		return;
	}

	FactionName = Chapter.GetFactionForContinent(Continent.GetReference());
	if (FactionName == '' || !class'Astartes_FactionConfig'.static.GetFaction(FactionName, Def))
	{
		return;
	}
	if (!class'Astartes_FactionConfig'.static.IsFactionAvailable(Def))
	{
		`log("Astartes: faction" @ FactionName @ "owns" @ Continent.GetMyTemplateName() @ "but its spawn lists are not loaded (is" @ Def.RequiredDLC @ "enabled?). Leaving" @ Context @ "vanilla.",, 'Astartes');
		return;
	}

	if (!class'Astartes_FactionConfig'.static.BuildPod(Def, ForceLevel, Encounter.SelectedCharacterTemplateNames.Length, NewTemplates))
	{
		`log("Astartes: faction" @ FactionName @ "has no eligible units at force level" @ ForceLevel @ "for" @ Context $ ". Leaving it vanilla.",, 'Astartes');
		return;
	}

	if (class'Astartes_FactionConfig'.default.bLogPodRewrites)
	{
		for (i = 0; i < Encounter.SelectedCharacterTemplateNames.Length; i++)
		{
			Before @= string(Encounter.SelectedCharacterTemplateNames[i]);
		}
		for (i = 0; i < NewTemplates.Length; i++)
		{
			After @= string(NewTemplates[i]);
		}
		`log("Astartes: PodRewrite" @ Context @ "on" @ Continent.GetMyTemplateName() @ "->" @ FactionName @ "FL" $ ForceLevel @ "[" $ Before @ "] => [" $ After @ "]",, 'Astartes');
	}

	Encounter.SelectedCharacterTemplateNames = NewTemplates;
}

/// Called when the player loads a saved game that was created without this mod.
static event OnLoadedSavedGame()
{
	`log("Astartes: loaded a save created without this mod",, 'Astartes');
}

/// Called when a save is loaded directly into the strategy layer. Repairs campaigns that predate the Chapter state.
static event OnLoadedSavedGameToStrategy()
{
	class'XComGameState_AstartesChapter'.static.EnsureChapterExists();
}

/// Called once all mods' templates exist. Use for edits that must run after every CreateTemplates.
static event OnPostTemplatesCreated()
{
	`log("Astartes: OnPostTemplatesCreated",, 'Astartes');
	class'Astartes_UnitVariants'.static.CreateVariants();
}

// ---------------------------------------------------------------------------------------
// Recruit appearance (Highlander hook, issue #783)
// ---------------------------------------------------------------------------------------

/// Runs at the end of XGCharacterGenerator.CreateTSoldier, before it returns CharGen.kSoldier.
/// For Marines ('Soldier' template): enforce the gender policy, then dress them from the Marine armour packs.
static function ModifyGeneratedUnitAppearance(XGCharacterGenerator CharGen, const name CharacterTemplateName, const EGender eForceGender, const name nmCountry, const int iRace, const name ArmorName, XComGameState_Unit UnitState, XComGameState UseGameState)
{
	// Chaos Cultists dress like the civilian militia: regenerate as that template. The nested call
	// re-enters this hook with 'CivilianMilitia', which falls through untouched.
	if (CharacterTemplateName == 'Astartes_Cultist')
	{
		CharGen.CreateTSoldier('CivilianMilitia', eForceGender, nmCountry, iRace, ArmorName);
		return;
	}

	if (CharacterTemplateName != 'Soldier')
	{
		return;
	}

	if (!default.bAllowFemaleMarines && eForceGender != eGender_Male && CharGen.kSoldier.kAppearance.iGender != eGender_Male)
	{
		// Regenerate as male. The nested call re-enters this hook with eForceGender == eGender_Male,
		// so it cannot recurse, and it applies the armour look itself. CreateTSoldier returns kSoldier
		// after this hook, so the regenerated soldier is what the caller receives.
		CharGen.CreateTSoldier(CharacterTemplateName, eGender_Male, nmCountry, iRace, ArmorName);
		return;
	}

	ApplyMarineArmourLook(CharGen, ArmorName);
}

/// Replace torso, arms, legs, deco and helmet with random parts from the configured Marine packs.
/// Leaves the vanilla look untouched when no pack is installed.
static function ApplyMarineArmourLook(XGCharacterGenerator CharGen, name ArmorName)
{
	local X2BodyPartTemplateManager PartMgr;
	local Astartes_BodyPartFilter Filter;
	local X2BodyPartTemplate Torso;
	local EGender Gender;
	local ECharacterRace Race;

	if (default.MarineArmorPartPacks.Length == 0)
	{
		return;
	}

	PartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	Gender = EGender(CharGen.kSoldier.kAppearance.iGender);
	Race = ECharacterRace(CharGen.kSoldier.kAppearance.iRace);

	Filter = new class'Astartes_BodyPartFilter';
	Filter.RequiredPacks = default.MarineArmorPartPacks;
	Filter.Set(Gender, Race, '', , , default.MarineArmorPartPacks);
	Filter.SetTorsoSelection('NoCharacterTemplateName', ArmorName == '' ? 'KevlarArmor' : ArmorName);

	Torso = PartMgr.GetRandomUberTemplate("Torso", Filter, Filter.FilterMarineTorso);
	if (Torso == none)
	{
		`log("Astartes: no Marine torso found for armour" @ ArmorName @ "- is the armour pack installed? Keeping vanilla look.",, 'Astartes');
		return;
	}
	CharGen.kSoldier.kAppearance.nmTorso = Torso.DataName;

	// Everything else must match the chosen torso's armour.
	Filter.Set(Gender, Race, Torso.DataName, false, false, default.MarineArmorPartPacks);

	CharGen.kSoldier.kAppearance.nmArms = PickMarinePart(PartMgr, Filter, "Arms");
	if (CharGen.kSoldier.kAppearance.nmArms == '')
	{
		CharGen.kSoldier.kAppearance.nmLeftArm = PickMarinePart(PartMgr, Filter, "LeftArm");
		CharGen.kSoldier.kAppearance.nmRightArm = PickMarinePart(PartMgr, Filter, "RightArm");
		CharGen.kSoldier.kAppearance.nmLeftArmDeco = PickMarinePart(PartMgr, Filter, "LeftArmDeco");
		CharGen.kSoldier.kAppearance.nmRightArmDeco = PickMarinePart(PartMgr, Filter, "RightArmDeco");
	}
	else
	{
		CharGen.kSoldier.kAppearance.nmLeftArm = '';
		CharGen.kSoldier.kAppearance.nmRightArm = '';
		CharGen.kSoldier.kAppearance.nmLeftArmDeco = '';
		CharGen.kSoldier.kAppearance.nmRightArmDeco = '';
	}
	CharGen.kSoldier.kAppearance.nmLegs = PickMarinePart(PartMgr, Filter, "Legs");
	CharGen.kSoldier.kAppearance.nmThighs = PickMarinePart(PartMgr, Filter, "Thighs");
	CharGen.kSoldier.kAppearance.nmShins = PickMarinePart(PartMgr, Filter, "Shins");
	CharGen.kSoldier.kAppearance.nmTorsoDeco = PickMarinePart(PartMgr, Filter, "TorsoDeco");
	CharGen.kSoldier.kAppearance.nmLeftForearm = PickMarinePart(PartMgr, Filter, "LeftForearm");
	CharGen.kSoldier.kAppearance.nmRightForearm = PickMarinePart(PartMgr, Filter, "RightForearm");

	// Marines wear helmets. Keep the vanilla head if the pack has none.
	if (PickMarinePart(PartMgr, Filter, "Helmets") != '')
	{
		CharGen.kSoldier.kAppearance.nmHelmet = PickMarinePart(PartMgr, Filter, "Helmets");
	}
}

static function name PickMarinePart(X2BodyPartTemplateManager PartMgr, Astartes_BodyPartFilter Filter, string PartType)
{
	local X2BodyPartTemplate Part;

	Part = PartMgr.GetRandomUberTemplate(PartType, Filter, Filter.FilterMarinePart);
	return Part == none ? '' : Part.DataName;
}


/// Log a line and echo it to the in-game console, so dev commands give visible feedback.
static function Say(string Msg)
{
	local Engine Eng;

	`log(Msg,, 'Astartes');
	Eng = class'Engine'.static.GetEngine();
	if (Eng != none && Eng.GameViewport != none && Eng.GameViewport.ViewportConsole != none)
	{
		Eng.GameViewport.ViewportConsole.OutputText(Msg);
	}
}

// ---------------------------------------------------------------------------------------
// Developer console commands. Require -allowConsole. Strategy layer only unless noted.
// Each logs a line starting "Astartes_<Command>: PASS" or "FAIL" so a log parser can assert on it.
// ---------------------------------------------------------------------------------------

/// Astartes_DevSquad [Ranks]
/// Adds one soldier of every Marine class to the barracks, promoted to the given rank (default: max),
/// with squaddie loadout and the best gear available. Nicknames them after their class.
exec function Astartes_DevSquad(optional int Ranks = -1)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassName;
	local int MaxRank, i, Created;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ == none)
	{
		Say("Astartes_DevSquad: FAIL no XComHQ (strategy layer only)");
		return;
	}

	MaxRank = class'X2ExperienceConfig'.static.GetMaxRank();
	if (Ranks < 1 || Ranks > MaxRank)
	{
		Ranks = MaxRank;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: DevSquad");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	foreach default.MarineClasses(ClassName)
	{
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
		if (ClassTemplate == none)
		{
			Say("Astartes_DevSquad: FAIL unknown class" @ ClassName);
			continue;
		}

		UnitState = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, 'Soldier', '', true);
		UnitState.ResetSoldierRank();
		UnitState.ResetSoldierAbilities();

		for (i = 0; i < Ranks; i++)
		{
			UnitState.RankUpSoldier(NewGameState, i == 0 ? ClassName : '');
			if (UnitState.GetRank() == 1)
			{
				UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
			}
		}
		UnitState.ApplyBestGearLoadout(NewGameState);
		UnitState.SetCharacterName(UnitState.GetFirstName(), UnitState.GetLastName(), ClassTemplate.DisplayName);
		UnitState.SetStatus(eStatus_Active);

		XComHQ.AddToCrew(NewGameState, UnitState);
		Created++;
		Say("Astartes_DevSquad: created" @ UnitState.GetFullName() @ "as" @ ClassName @ "rank" @ UnitState.GetRank());
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	Say("Astartes_DevSquad: PASS created" @ Created @ "of" @ default.MarineClasses.Length);
}

/// Astartes_ListClasses
/// Logs every soldier class template this mod registered and how many ranks it has.
exec function Astartes_ListClasses()
{
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassName;

	foreach default.MarineClasses(ClassName)
	{
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
		if (ClassTemplate == none)
		{
			Say("Astartes_ListClasses: FAIL missing" @ ClassName);
		}
		else
		{
			Say("Astartes_ListClasses: PASS" @ ClassName @ "ranks=" $ ClassTemplate.GetMaxConfiguredRank() @ "display=" $ ClassTemplate.DisplayName);
		}
	}
}

/// Astartes_Geneseed [NewAmount]
/// Logs the Chapter's geneseed pool; with an argument, sets it. Works in strategy and tactical.
exec function Astartes_Geneseed(optional int NewAmount = -1)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none)
	{
		Say("Astartes_Geneseed: FAIL no Chapter state in this campaign");
		return;
	}

	if (NewAmount >= 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set geneseed");
		Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
		Chapter.Geneseed = NewAmount;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	Say("Astartes_Geneseed: PASS geneseed=" $ Chapter.Geneseed @ "recovered_total=" $ Chapter.GeneseedRecoveredTotal @ "fallen=" $ Chapter.BrothersFallen);
}

/// Astartes_Factions
/// Logs which faction owns each continent and whether that faction's spawn lists are loaded.
exec function Astartes_Factions()
{
	local XComGameState_AstartesChapter Chapter;
	local FactionDef Def;
	local int i;
	local string Status;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none || Chapter.ContinentFactions.Length == 0)
	{
		// Campaign predates this feature (or the strategy-load repair did not run): deal factions now.
		class'XComGameState_AstartesChapter'.static.EnsureChapterExists();
		Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	}
	if (Chapter == none || Chapter.ContinentFactions.Length == 0)
	{
		Say("Astartes_Factions: FAIL could not assign continent factions (are any factions configured?)");
		return;
	}
	for (i = 0; i < Chapter.ContinentFactions.Length; i++)
	{
		Status = "unknown faction";
		if (class'Astartes_FactionConfig'.static.GetFaction(Chapter.ContinentFactions[i].FactionName, Def))
		{
			Status = class'Astartes_FactionConfig'.static.IsFactionAvailable(Def) ? "lists loaded" : ("lists MISSING - enable" @ Def.RequiredDLC);
		}
		Say("Astartes_Factions: PASS" @ Chapter.ContinentFactions[i].ContinentTemplate @ "->" @ Chapter.ContinentFactions[i].FactionName @ "(" $ Status $ ")");
	}
}

/// Astartes_AssignFactions
/// (Re)deals factions to continents. Use on a campaign that predates this feature, or to re-roll.
exec function Astartes_AssignFactions()
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: assign factions");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.AssignContinentFactions(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_AssignFactions: PASS assigned" @ Chapter.ContinentFactions.Length @ "continents");
}

/// Astartes_SetContinentFaction <ContinentTemplate> <FactionName>
/// e.g. Astartes_SetContinentFaction Continent_NorthAmerica Orks
exec function Astartes_SetContinentFaction(string ContinentTemplateStr, string FactionNameStr)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;
	local FactionDef Def;
	local name ContinentTemplate, FactionName;

	// The console cannot parse 'name' parameters; take strings and convert.
	ContinentTemplate = name(ContinentTemplateStr);
	FactionName = name(FactionNameStr);

	if (!class'Astartes_FactionConfig'.static.GetFaction(FactionName, Def))
	{
		Say("Astartes_SetContinentFaction: FAIL unknown faction" @ FactionName);
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set continent faction");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	if (!Chapter.SetFactionForContinent(ContinentTemplate, FactionName))
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		Say("Astartes_SetContinentFaction: FAIL unknown continent" @ ContinentTemplate);
		return;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_SetContinentFaction: PASS" @ ContinentTemplate @ "->" @ FactionName);
}

/// Astartes_Variants
/// Logs every configured unit variant: created (with HP) or skipped because its base mod is off.
exec function Astartes_Variants()
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate T;
	local int i;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	T = CharMgr.FindCharacterTemplate('Astartes_Cultist');
	Say("Astartes_Variants:" @ (T != none ? "PASS" : "FAIL") @ "Astartes_Cultist" @ (T != none ? ("HP=" $ T.CharacterBaseStats[eStat_HP]) : "missing"));
	for (i = 0; i < class'Astartes_UnitVariants'.default.Variants.Length; i++)
	{
		T = CharMgr.FindCharacterTemplate(class'Astartes_UnitVariants'.default.Variants[i].NewName);
		if (T == none)
		{
			Say("Astartes_Variants: FAIL" @ class'Astartes_UnitVariants'.default.Variants[i].NewName @ "not created (base" @ class'Astartes_UnitVariants'.default.Variants[i].BaseTemplate @ "loaded?)");
		}
		else
		{
			Say("Astartes_Variants: PASS" @ T.DataName @ "from" @ class'Astartes_UnitVariants'.default.Variants[i].BaseTemplate @ "HP=" $ T.CharacterBaseStats[eStat_HP] @ "armor=" $ T.CharacterBaseStats[eStat_ArmorMitigation]);
		}
	}
}

/// Astartes_PartPacks
/// Lists the body-part packs the game knows about and how many male Kevlar-tier torsos each has.
/// Use to check that an armour pack (e.g. SM2Tacticus) is actually loaded.
exec function Astartes_PartPacks()
{
	local X2BodyPartTemplateManager PartMgr;
	local array<name> Packs;
	local array<X2BodyPartTemplate> Torsos;
	local name Pack;
	local int i, Count, Configured;

	PartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	Packs = PartMgr.GetPartPackNames();
	PartMgr.GetUberTemplates("Torso", Torsos);
	Say("Astartes_PartPacks: PASS" @ Packs.Length @ "packs," @ Torsos.Length @ "torsos total");
	foreach Packs(Pack)
	{
		Count = 0;
		for (i = 0; i < Torsos.Length; i++)
		{
			if (Torsos[i].DLCName == Pack && Torsos[i].Gender == eGender_Male && Torsos[i].ArmorTemplate == 'KevlarArmor')
			{
				Count++;
			}
		}
		Configured = default.MarineArmorPartPacks.Find(Pack) != INDEX_NONE ? 1 : 0;
		Say("Astartes_PartPacks:   " $ Pack @ "male kevlar torsos=" $ Count @ (Configured == 1 ? "<- Marine look pack" : ""));
	}
	foreach default.MarineArmorPartPacks(Pack)
	{
		if (Packs.Find(Pack) == INDEX_NONE)
		{
			Say("Astartes_PartPacks: FAIL configured Marine pack" @ Pack @ "is not loaded (enable its mod in AML)");
		}
	}
}

/// Astartes_Redress
/// Re-rolls every barracks soldier's appearance through the Marine generator (gender policy + armour packs).
/// Use after enabling an armour pack mid-campaign.
exec function Astartes_Redress()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XGCharacterGenerator CharGen;
	local TSoldier Generated;
	local int idx, Count;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ == none)
	{
		Say("Astartes_Redress: FAIL no XComHQ");
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: Redress");
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
		if (UnitState == none || !UnitState.IsSoldier() || UnitState.GetMyTemplateName() != 'Soldier')
		{
			continue;
		}
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		CharGen = `XCOMGRI.Spawn(UnitState.GetMyTemplate().CharacterGeneratorClass);
		Generated = CharGen.CreateTSoldierFromUnit(UnitState, NewGameState);
		UnitState.SetTAppearance(Generated.kAppearance);
		UnitState.StoreAppearance();
		CharGen.Destroy();
		Count++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_Redress: PASS redressed" @ Count @ "soldiers");
}
