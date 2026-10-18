//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Astartes_RecoverGeneseed.uc
//  PURPOSE: Applied to a fallen Marine's body by an Apothecary. Marks the body as harvested
//           (so it cannot be harvested twice) and adds geneseed to the Chapter pool.
//---------------------------------------------------------------------------------------
class X2Effect_Astartes_RecoverGeneseed extends X2Effect;

var name HarvestedValueName;
var int GeneseedAmount;
var int MasteryBonus; // extra geneseed when the Apothecary knows Reductor Mastery

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Body, Apothecary;
	local XComGameState_AstartesChapter Chapter;
	local int Amount;

	Body = XComGameState_Unit(kNewTargetState);
	if (Body == none)
	{
		return;
	}

	Body.SetUnitFloatValue(default.HarvestedValueName, 1, eCleanup_Never);

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Amount = GeneseedAmount;
	Apothecary = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (Apothecary != none && Apothecary.HasSoldierAbility('Astartes_ReductorMastery'))
	{
		Amount += MasteryBonus;
	}
	Chapter.AddGeneseed(Amount);

	`log("Astartes: geneseed recovered from" @ Body.GetFullName() @ "pool now" @ Chapter.Geneseed,, 'Astartes');
}

defaultproperties
{
	HarvestedValueName = "Astartes_GeneseedRecovered"
	GeneseedAmount = 1
	MasteryBonus = 1
}
