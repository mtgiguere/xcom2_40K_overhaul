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
	class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(StartState);
	`log("Astartes: new campaign started",, 'Astartes');
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
}

// ---------------------------------------------------------------------------------------
// Recruit appearance (Highlander hook, issue #783)
// ---------------------------------------------------------------------------------------

/// Runs at the end of XGCharacterGenerator.CreateTSoldier, before it returns CharGen.kSoldier.
/// For Marines ('Soldier' template): enforce the gender policy, then dress them from the Marine armour packs.
static function ModifyGeneratedUnitAppearance(XGCharacterGenerator CharGen, const name CharacterTemplateName, const EGender eForceGender, const name nmCountry, const int iRace, const name ArmorName, XComGameState_Unit UnitState, XComGameState UseGameState)
{
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
		`log("Astartes_DevSquad: FAIL no XComHQ (strategy layer only)",, 'Astartes');
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
			`log("Astartes_DevSquad: FAIL unknown class" @ ClassName,, 'Astartes');
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
		`log("Astartes_DevSquad: created" @ UnitState.GetFullName() @ "as" @ ClassName @ "rank" @ UnitState.GetRank(),, 'Astartes');
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	`log("Astartes_DevSquad: PASS created" @ Created @ "of" @ default.MarineClasses.Length,, 'Astartes');
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
			`log("Astartes_ListClasses: FAIL missing" @ ClassName,, 'Astartes');
		}
		else
		{
			`log("Astartes_ListClasses: PASS" @ ClassName @ "ranks=" $ ClassTemplate.GetMaxConfiguredRank() @ "display=" $ ClassTemplate.DisplayName,, 'Astartes');
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
		`log("Astartes_Geneseed: FAIL no Chapter state in this campaign",, 'Astartes');
		return;
	}

	if (NewAmount >= 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set geneseed");
		Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
		Chapter.Geneseed = NewAmount;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	`log("Astartes_Geneseed: PASS geneseed=" $ Chapter.Geneseed @ "recovered_total=" $ Chapter.GeneseedRecoveredTotal @ "fallen=" $ Chapter.BrothersFallen,, 'Astartes');
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
		`log("Astartes_Redress: FAIL no XComHQ",, 'Astartes');
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
	`log("Astartes_Redress: PASS redressed" @ Count @ "soldiers",, 'Astartes');
}
