//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Astartes_MentalPurge.uc
//  PURPOSE: Perils outcome "Mental Purge": every psychic power the unit knows goes on cooldown.
//---------------------------------------------------------------------------------------
class X2Effect_Astartes_MentalPurge extends X2Effect;

var int CooldownTurns;
var array<name> Powers;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_Ability Ability;
	local XComGameStateHistory History;
	local int i, Purged;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit == none)
	{
		return;
	}
	History = `XCOMHISTORY;
	for (i = 0; i < Unit.Abilities.Length; i++)
	{
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(Unit.Abilities[i].ObjectID));
		if (Ability != none && Powers.Find(Ability.GetMyTemplateName()) != INDEX_NONE)
		{
			Ability = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', Ability.ObjectID));
			Ability.iCooldown = Max(Ability.iCooldown, CooldownTurns);
			Purged++;
		}
	}
	`log("Astartes: Mental Purge put" @ Purged @ "powers on cooldown for" @ CooldownTurns @ "turns",, 'Astartes');
}
