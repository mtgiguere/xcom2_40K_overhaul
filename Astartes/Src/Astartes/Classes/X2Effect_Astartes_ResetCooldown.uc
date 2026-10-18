//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Astartes_ResetCooldown.uc
//  PURPOSE: Clear the cooldown of the named abilities on the target unit. Used by the Assault
//           Marine's Hit and Run (melee kill resets the Jump Pack) and Angel of Death.
//---------------------------------------------------------------------------------------
class X2Effect_Astartes_ResetCooldown extends X2Effect;

var array<name> AbilityNames;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local XComGameStateHistory History;
	local int i;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit == none)
	{
		return;
	}
	History = `XCOMHISTORY;
	for (i = 0; i < Unit.Abilities.Length; i++)
	{
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(Unit.Abilities[i].ObjectID));
		if (Ability != none && Ability.iCooldown > 0 && AbilityNames.Find(Ability.GetMyTemplateName()) != INDEX_NONE)
		{
			Ability = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', Ability.ObjectID));
			Ability.iCooldown = 0;
		}
	}
}
