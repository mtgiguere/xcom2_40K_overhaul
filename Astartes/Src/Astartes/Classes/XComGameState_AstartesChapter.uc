//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AstartesChapter.uc
//  PURPOSE: Campaign-wide state of the Chapter: the geneseed pool and, later, First Company
//           inductions, unique positions and faction threat. One instance per campaign.
//---------------------------------------------------------------------------------------
class XComGameState_AstartesChapter extends XComGameState_BaseObject;

/// Geneseed in the Chapter's vaults. Each unit of geneseed allows one new Scout to be recruited.
var int Geneseed;

/// Lifetime counters, for the Wall of the Fallen and for tests.
var int GeneseedRecoveredTotal;
var int BrothersFallen;

static function XComGameState_AstartesChapter GetChapter(optional bool bAllowNone = false)
{
	return XComGameState_AstartesChapter(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AstartesChapter', bAllowNone));
}

/// Returns the Chapter state as a modifiable object in NewGameState, creating it if this campaign has none.
static function XComGameState_AstartesChapter GetOrCreateChapter(XComGameState NewGameState)
{
	local XComGameState_AstartesChapter Chapter;

	foreach NewGameState.IterateByClassType(class'XComGameState_AstartesChapter', Chapter)
	{
		return Chapter;
	}

	Chapter = GetChapter(true);
	if (Chapter == none)
	{
		Chapter = XComGameState_AstartesChapter(NewGameState.CreateNewStateObject(class'XComGameState_AstartesChapter'));
		`log("Astartes: created Chapter state",, 'Astartes');
	}
	else
	{
		Chapter = XComGameState_AstartesChapter(NewGameState.ModifyStateObject(class'XComGameState_AstartesChapter', Chapter.ObjectID));
	}
	return Chapter;
}

/// Creates the Chapter state in its own submitted game state if the campaign lacks one (save made before this mod).
static function EnsureChapterExists()
{
	local XComGameState NewGameState;

	if (GetChapter(true) != none)
	{
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: create Chapter state");
	GetOrCreateChapter(NewGameState);
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

function AddGeneseed(int Amount)
{
	Geneseed += Amount;
	GeneseedRecoveredTotal += Amount;
}
