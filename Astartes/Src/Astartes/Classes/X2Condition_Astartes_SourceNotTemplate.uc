//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Astartes_SourceNotTemplate.uc
//  PURPOSE: Fails when the effect's source unit is one of the listed character templates. Lets a
//           shared ability (the Chryssalid's slash) skip one of its effects for our variants only.
//---------------------------------------------------------------------------------------
class X2Condition_Astartes_SourceNotTemplate extends X2Condition;

var array<name> ExcludedSources;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit Source;

	Source = XComGameState_Unit(kSource);
	if (Source != none && ExcludedSources.Find(Source.GetMyTemplateName()) != INDEX_NONE)
	{
		return 'AA_AbilityUnavailable';
	}
	return 'AA_Success';
}
