//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AstartesChapter.uc
//  PURPOSE: Campaign-wide state of the Chapter: the geneseed pool, which enemy faction owns
//           each continent, and later First Company inductions, unique positions and threat.
//           One instance per campaign.
//---------------------------------------------------------------------------------------
class XComGameState_AstartesChapter extends XComGameState_BaseObject;

struct ContinentFaction
{
	var StateObjectReference ContinentRef;
	var name ContinentTemplate;
	var name FactionName;
};

/// Geneseed in the Chapter's vaults. Each unit of geneseed allows one new Scout to be recruited.
var int Geneseed;

/// Lifetime counters, for the Wall of the Fallen and for tests.
var int GeneseedRecoveredTotal;
var int BrothersFallen;

/// Which enemy faction owns each continent (design.md 7.1b). Assigned at campaign start.
var array<ContinentFaction> ContinentFactions;

/// The Chapter this campaign fights as (an X2CountryTemplate name). '' = use the config default.
var name ChapterCountry;

// The Chapter Master (Astartes_ChapterMaster): one at a time; lost ones are counted for the replacement cost.
var StateObjectReference ChapterMasterRef;
var int ChapterMastersLost;

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

/// Creates the Chapter state (and continent assignments) in its own submitted game state if the campaign lacks one.
static function EnsureChapterExists()
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	Chapter = GetChapter(true);
	if (Chapter != none && Chapter.ContinentFactions.Length > 0)
	{
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: create Chapter state");
	Chapter = GetOrCreateChapter(NewGameState);
	Chapter.AssignContinentFactions(NewGameState);
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

function AddGeneseed(int Amount)
{
	Geneseed += Amount;
	GeneseedRecoveredTotal += Amount;
}

// ---------------------------------------------------------------------------------------
// Continent ownership
// ---------------------------------------------------------------------------------------

/// Deal a faction to every continent. Config overrides win; the rest are shuffled round-robin so the
/// factions come out as evenly as the continent count allows. Continents are read from NewGameState
/// first (campaign start) and the history otherwise.
function AssignContinentFactions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;
	local array<XComGameState_Continent> Continents;
	local array<name> Pool, Shuffled;
	local ContinentFaction Entry;
	local name Tmp;
	local int i, j;

	History = `XCOMHISTORY;
	ContinentFactions.Length = 0;

	foreach NewGameState.IterateByClassType(class'XComGameState_Continent', ContinentState)
	{
		Continents.AddItem(ContinentState);
	}
	if (Continents.Length == 0)
	{
		foreach History.IterateByClassType(class'XComGameState_Continent', ContinentState)
		{
			Continents.AddItem(ContinentState);
		}
	}

	Pool = class'Astartes_FactionConfig'.static.GetFactionNames();
	if (Pool.Length == 0 || Continents.Length == 0)
	{
		`log("Astartes: cannot assign continent factions (factions=" $ Pool.Length @ "continents=" $ Continents.Length $ ")",, 'Astartes');
		return;
	}

	// Build a shuffled sequence long enough to cover every continent, round-robin through the pool.
	while (Shuffled.Length < Continents.Length)
	{
		for (i = 0; i < Pool.Length; i++)
		{
			Shuffled.AddItem(Pool[i]);
		}
	}
	// Fisher-Yates shuffle.
	for (i = Shuffled.Length - 1; i > 0; i--)
	{
		j = `SYNC_RAND(i + 1);
		Tmp = Shuffled[i];
		Shuffled[i] = Shuffled[j];
		Shuffled[j] = Tmp;
	}

	for (i = 0; i < Continents.Length; i++)
	{
		Entry.ContinentRef = Continents[i].GetReference();
		Entry.ContinentTemplate = Continents[i].GetMyTemplateName();
		Entry.FactionName = class'Astartes_FactionConfig'.static.GetOverrideForContinent(Entry.ContinentTemplate);
		if (Entry.FactionName == '')
		{
			Entry.FactionName = Shuffled[i];
		}
		ContinentFactions.AddItem(Entry);
		`log("Astartes: continent" @ Entry.ContinentTemplate @ "->" @ Entry.FactionName,, 'Astartes');
	}
}

function name GetFactionForContinent(StateObjectReference ContinentRef)
{
	local int i;

	for (i = 0; i < ContinentFactions.Length; i++)
	{
		if (ContinentFactions[i].ContinentRef.ObjectID == ContinentRef.ObjectID)
		{
			return ContinentFactions[i].FactionName;
		}
	}
	return '';
}

function bool SetFactionForContinent(name ContinentTemplate, name FactionName)
{
	local int i;

	for (i = 0; i < ContinentFactions.Length; i++)
	{
		if (ContinentFactions[i].ContinentTemplate == ContinentTemplate)
		{
			ContinentFactions[i].FactionName = FactionName;
			return true;
		}
	}
	return false;
}
