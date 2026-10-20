//---------------------------------------------------------------------------------------
//  FILE:    Astartes_Tyranids.uc
//  PURPOSE: Template edits for our Tyranids. The Ripper swarm is a Chryssalid variant (burrow, ambush and
//           AI for free) whose slash must not plant the parthenogenic poison: no cocoons from Rippers.
//---------------------------------------------------------------------------------------
class Astartes_Tyranids extends Object config(Astartes);

/// Abilities whose parthenogenic poison these attackers never apply.
var config array<name> CocoonAbilities;
/// Our units that use those abilities but must not make cocoons.
var config array<name> NoCocoonAttackers;

static function Apply()
{
	local X2AbilityTemplateManager AbilityMgr;
	local array<X2DataTemplate> Found;
	local X2AbilityTemplate Ability;
	local X2Condition_Astartes_SourceNotTemplate NotFrom;
	local int i, j, k, Patched;

	if (default.NoCocoonAttackers.Length == 0)
	{
		return;
	}
	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = 0; i < default.CocoonAbilities.Length; i++)
	{
		Found.Length = 0;
		AbilityMgr.FindDataTemplateAllDifficulties(default.CocoonAbilities[i], Found);
		for (j = 0; j < Found.Length; j++)
		{
			Ability = X2AbilityTemplate(Found[j]);
			if (Ability == none)
			{
				continue;
			}
			for (k = 0; k < Ability.AbilityTargetEffects.Length; k++)
			{
				if (X2Effect_ParthenogenicPoison(Ability.AbilityTargetEffects[k]) == none)
				{
					continue;
				}
				NotFrom = new class'X2Condition_Astartes_SourceNotTemplate';
				NotFrom.ExcludedSources = default.NoCocoonAttackers;
				Ability.AbilityTargetEffects[k].TargetConditions.AddItem(NotFrom);
				Patched++;
			}
		}
	}
	`log("Astartes: cocoon poison skipped for" @ default.NoCocoonAttackers.Length @ "attacker(s) on" @ Patched @ "effect(s)",, 'Astartes');
}
