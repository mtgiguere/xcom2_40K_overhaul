//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Astartes_Wavering.uc
//  PURPOSE: Summary Execution's target rule: the unit has broken (panicked) or is in an enemy
//           psyker's grip (mind-controlled). Team does not matter.
//---------------------------------------------------------------------------------------
class X2Condition_Astartes_Wavering extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(kTarget);
	if (Unit == none)
	{
		return 'AA_NotAUnit';
	}
	if (Unit.IsPanicked() || Unit.IsMindControlled()
		|| Unit.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.PanickedName)
		|| Unit.IsUnitAffectedByEffectName(class'X2Effect_MindControl'.default.EffectName))
	{
		return 'AA_Success';
	}
	return 'AA_AbilityUnavailable';
}
