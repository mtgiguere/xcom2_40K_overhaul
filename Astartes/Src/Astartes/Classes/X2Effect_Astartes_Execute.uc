//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Astartes_Execute.uc
//  PURPOSE: Summary Execution's kill. The vanilla X2Effect_Executed puts a unit that can bleed out
//           into bleed-out instead of killing it (an XCOM soldier would survive his own execution);
//           this one always kills. Keeps the vanilla effect's "Executed" flyover and visualization.
//---------------------------------------------------------------------------------------
class X2Effect_Astartes_Execute extends X2Effect_Executed;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Target;
	local array<name> NoDamageTypes;
	local int Kill;

	super(X2Effect).OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	Target = XComGameState_Unit(kNewTargetState);
	if (Target == none || Target.IsDead())
	{
		return;
	}
	Kill = Target.GetCurrentStat(eStat_HP) + Target.GetCurrentStat(eStat_ShieldHP) + 100;
	// no forced bleed-out, bleed-out not allowed, shields ignored
	Target.TakeEffectDamage(self, Kill, 0, 0, ApplyEffectParameters, NewGameState, false, false, true, NoDamageTypes);
}
