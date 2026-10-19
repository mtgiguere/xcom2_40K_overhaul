//---------------------------------------------------------------------------------------
//  FILE:    Astartes_GuardClasses.uc
//  PURPOSE: LWOTI: LWOTC's human soldier classes are the Imperial Guard regiment (docs/lwotc.md).
//           Their trees stay LWOTC's; their names, summaries and rank titles become the Guard's.
//           Applied to the templates at load, so no localization load order can undo it. Classes
//           that are not loaded (no LWOTC) are skipped.
//---------------------------------------------------------------------------------------
class Astartes_GuardClasses extends Object config(Astartes);

var config array<name> GuardClasses;               // in the order of the localized lists below
var localized array<string> GuardNames, GuardSummaries;
var localized array<string> GuardRankNames, GuardShortNames;

static function Apply()
{
	local X2SoldierClassTemplateManager ClassMgr;
	local X2SoldierClassTemplate T;
	local int i, Renamed;

	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	for (i = 0; i < default.GuardClasses.Length; i++)
	{
		T = ClassMgr.FindSoldierClassTemplate(default.GuardClasses[i]);
		if (T == none)
		{
			continue;
		}
		if (i < default.GuardNames.Length && default.GuardNames[i] != "")
		{
			T.DisplayName = default.GuardNames[i];
		}
		if (i < default.GuardSummaries.Length && default.GuardSummaries[i] != "")
		{
			T.ClassSummary = default.GuardSummaries[i];
		}
		if (default.GuardRankNames.Length > 0)
		{
			T.RankNames = default.GuardRankNames;
			T.ShortNames = default.GuardShortNames;
		}
		Renamed++;
	}
	`log("Astartes: Imperial Guard classes:" @ Renamed @ "of" @ default.GuardClasses.Length @ "LWOTC classes renamed",, 'Astartes');
}
