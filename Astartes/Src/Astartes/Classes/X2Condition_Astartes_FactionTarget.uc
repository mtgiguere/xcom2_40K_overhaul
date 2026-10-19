//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Astartes_FactionTarget.uc
//  PURPOSE: The target belongs to an enemy faction: its character template appears in that faction's
//           leader, follower or commander spawn list (Astartes_FactionConfig). New units added to a
//           faction's lists are covered without touching the abilities that use this.
//---------------------------------------------------------------------------------------
class X2Condition_Astartes_FactionTarget extends X2Condition;

var name FactionName;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none)
	{
		return 'AA_NotAUnit';
	}
	return IsOfFaction(Unit.GetMyTemplateName(), FactionName) ? 'AA_Success' : 'AA_AbilityUnavailable';
}

static function bool IsOfFaction(name TemplateName, name Faction)
{
	local FactionDef Def;
	local array<SpawnDistributionListEntry> Entries;
	local array<name> Lists;
	local int i, j;

	if (!class'Astartes_FactionConfig'.static.GetFaction(Faction, Def))
	{
		return false;
	}
	Lists.AddItem(Def.LeaderList);
	Lists.AddItem(Def.FollowerList);
	Lists.AddItem(Def.CommanderList);
	for (i = 0; i < Lists.Length; i++)
	{
		if (Lists[i] == '' || !class'Astartes_FactionConfig'.static.GetSpawnList(Lists[i], Entries))
		{
			continue;
		}
		for (j = 0; j < Entries.Length; j++)
		{
			if (Entries[j].Template == TemplateName)
			{
				return true;
			}
		}
	}
	return false;
}
