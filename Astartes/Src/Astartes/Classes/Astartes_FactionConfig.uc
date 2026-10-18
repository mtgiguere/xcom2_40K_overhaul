//---------------------------------------------------------------------------------------
//  FILE:    Astartes_FactionConfig.uc
//  PURPOSE: Enemy faction definitions (which spawn lists belong to Orks, Chaos, Tyranids...) and
//           the pod builder that draws a faction-pure pod from those lists at a force level.
//           Mirrors the native leader/follower selection loosely: one leader, N-1 followers,
//           weighted by SpawnWeight, filtered by force level, capped by MaxCharactersPerGroup.
//---------------------------------------------------------------------------------------
class Astartes_FactionConfig extends Object config(Astartes);

struct FactionDef
{
	var name FactionName;
	var name LeaderList;
	var name FollowerList;
	var name CommanderList;    // optional: leaders for special "commander" encounters (Field Commander etc.)
	var name RequiredDLC;
};

struct ContinentFactionOverride
{
	var name Continent;
	var name FactionName;
};

var config bool bEnableContinentFactions;
var config bool bLogPodRewrites;
var config array<FactionDef> Factions;
var config array<ContinentFactionOverride> ContinentFactionOverrides;

/// Encounter IDs that are never rewritten (hidden Faceless, swarm VIPs...). Chosen/VIP pods are skipped by tag anyway.
var config array<name> NeverRewriteEncounters;
/// Encounter ID prefixes whose leader is drawn from the faction's CommanderList (e.g. "SPCx" = Field Commander groups).
var config array<string> CommanderEncounterPrefixes;
/// SitRep templates the faction mods inject on their own (raids). Removed from missions on continents we own.
var config array<name> ForeignRaidSitReps;

static function bool IsNeverRewritten(name EncounterID)
{
	return default.NeverRewriteEncounters.Find(EncounterID) != INDEX_NONE;
}

static function bool IsCommanderEncounter(name EncounterID)
{
	local string Prefix;

	foreach default.CommanderEncounterPrefixes(Prefix)
	{
		if (Left(string(EncounterID), Len(Prefix)) ~= Prefix)
		{
			return true;
		}
	}
	return false;
}

static function bool GetFaction(name FactionName, out FactionDef Def)
{
	local int i;

	for (i = 0; i < default.Factions.Length; i++)
	{
		if (default.Factions[i].FactionName == FactionName)
		{
			Def = default.Factions[i];
			return true;
		}
	}
	return false;
}

static function array<name> GetFactionNames()
{
	local array<name> Names;
	local int i;

	for (i = 0; i < default.Factions.Length; i++)
	{
		Names.AddItem(default.Factions[i].FactionName);
	}
	return Names;
}

static function name GetOverrideForContinent(name ContinentTemplate)
{
	local int i;

	for (i = 0; i < default.ContinentFactionOverrides.Length; i++)
	{
		if (default.ContinentFactionOverrides[i].Continent == ContinentTemplate)
		{
			return default.ContinentFactionOverrides[i].FactionName;
		}
	}
	return '';
}

/// A faction is available when its spawn lists are loaded (i.e. the faction mod is installed and active).
static function bool IsFactionAvailable(const out FactionDef Def)
{
	local array<SpawnDistributionListEntry> Entries;

	return GetSpawnList(Def.LeaderList, Entries) && GetSpawnList(Def.FollowerList, Entries);
}

static function bool GetSpawnList(name ListID, out array<SpawnDistributionListEntry> OutEntries)
{
	local XComTacticalMissionManager MissionMgr;
	local int i;

	OutEntries.Length = 0;
	MissionMgr = `TACTICALMISSIONMGR;
	for (i = 0; i < MissionMgr.SpawnDistributionLists.Length; i++)
	{
		if (MissionMgr.SpawnDistributionLists[i].ListID == ListID)
		{
			OutEntries = MissionMgr.SpawnDistributionLists[i].SpawnDistribution;
			return OutEntries.Length > 0;
		}
	}
	return false;
}

/// Build a pod of PodSize units from the faction's lists. Returns false (and leaves OutTemplates empty)
/// if the lists are missing or nothing is eligible at this force level.
static function bool BuildPod(const out FactionDef Def, int ForceLevel, int PodSize, out array<name> OutTemplates, optional bool bCommanderPod = false)
{
	local array<SpawnDistributionListEntry> Leaders, Followers, Commanders;
	local array<name> PickedNames;
	local array<int> PickedCounts;
	local name Picked;
	local int i;

	OutTemplates.Length = 0;
	if (PodSize <= 0 || !GetSpawnList(Def.LeaderList, Leaders) || !GetSpawnList(Def.FollowerList, Followers))
	{
		return false;
	}

	// Commander pods (Field Commander objectives etc.) lead with a real faction leader when one is configured.
	if (bCommanderPod && Def.CommanderList != '' && GetSpawnList(Def.CommanderList, Commanders))
	{
		Picked = WeightedPick(Commanders, ForceLevel, PickedNames, PickedCounts);
	}
	if (Picked == '')
	{
		Picked = WeightedPick(Leaders, ForceLevel, PickedNames, PickedCounts);
	}
	if (Picked == '')
	{
		Picked = WeightedPick(Followers, ForceLevel, PickedNames, PickedCounts);
	}
	if (Picked == '')
	{
		return false;
	}
	OutTemplates.AddItem(Picked);

	for (i = 1; i < PodSize; i++)
	{
		Picked = WeightedPick(Followers, ForceLevel, PickedNames, PickedCounts);
		if (Picked == '')
		{
			Picked = WeightedPick(Leaders, ForceLevel, PickedNames, PickedCounts);
		}
		if (Picked == '')
		{
			break;
		}
		OutTemplates.AddItem(Picked);
	}
	return OutTemplates.Length > 0;
}

/// Weighted random pick among entries valid at ForceLevel whose per-pod cap is not yet reached and whose
/// character template exists. Updates the pick counts. Returns '' when nothing is eligible.
static function name WeightedPick(const out array<SpawnDistributionListEntry> Entries, int ForceLevel, out array<name> PickedNames, out array<int> PickedCounts)
{
	local X2CharacterTemplateManager CharMgr;
	local array<int> Eligible;
	local float TotalWeight, Roll;
	local int i, idx;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	for (i = 0; i < Entries.Length; i++)
	{
		if (ForceLevel < Entries[i].MinForceLevel || ForceLevel > Entries[i].MaxForceLevel || Entries[i].SpawnWeight <= 0)
		{
			continue;
		}
		idx = PickedNames.Find(Entries[i].Template);
		if (idx != INDEX_NONE && Entries[i].MaxCharactersPerGroup > 0 && PickedCounts[idx] >= Entries[i].MaxCharactersPerGroup)
		{
			continue;
		}
		if (CharMgr.FindCharacterTemplate(Entries[i].Template) == none)
		{
			continue;
		}
		Eligible.AddItem(i);
		TotalWeight += Entries[i].SpawnWeight;
	}

	if (Eligible.Length == 0)
	{
		return '';
	}

	Roll = `SYNC_FRAND_STATIC() * TotalWeight;
	for (i = 0; i < Eligible.Length; i++)
	{
		Roll -= Entries[Eligible[i]].SpawnWeight;
		if (Roll <= 0 || i == Eligible.Length - 1)
		{
			idx = PickedNames.Find(Entries[Eligible[i]].Template);
			if (idx == INDEX_NONE)
			{
				PickedNames.AddItem(Entries[Eligible[i]].Template);
				PickedCounts.AddItem(1);
			}
			else
			{
				PickedCounts[idx]++;
			}
			return Entries[Eligible[i]].Template;
		}
	}
	return '';
}
