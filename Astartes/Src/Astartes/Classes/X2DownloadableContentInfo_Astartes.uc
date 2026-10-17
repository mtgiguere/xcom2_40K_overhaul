//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_Astartes.uc
//  PURPOSE: Entry point for the Warhammer 40K overhaul. Campaign-start hooks, Highlander
//           event registration, and the developer console commands (exec functions) that
//           double as the runtime test harness.
//---------------------------------------------------------------------------------------
class X2DownloadableContentInfo_Astartes extends X2DownloadableContentInfo;

/// Soldier classes this mod defines, in roster order. Kept in sync with tests/data/class_trees.json.
var config array<name> MarineClasses;

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
