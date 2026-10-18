//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Devastator.uc
//  PURPOSE: Devastator abilities (docs/classes.md), built on XModBase helpers.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Devastator].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Devastator extends XMBAbility config(Astartes);

var config int BRACE_AIM;
var config int BIPOD_REACTION_AIM;
var config int TANK_HUNTER_CRIT, TANK_HUNTER_DAMAGE, TANK_HUNTER_MIN_ARMOUR;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Brace());
	Templates.AddItem(Bipod());
	Templates.AddItem(TankHunter());

	return Templates;
}

/// A shooter condition: the unit has not moved this turn (vanilla tracks 'MovesThisTurn').
static function X2Condition_UnitValue NotMovedCondition()
{
	local X2Condition_UnitValue Condition;

	Condition = new class'X2Condition_UnitValue';
	Condition.AddCheckValue('MovesThisTurn', 0, eCheck_Exact);
	return Condition;
}

// --- Emplacement ---------------------------------------------------------------------------

/// Brace: heavy weapon shots gain aim when the Devastator has not moved this turn.
static function X2AbilityTemplate Brace()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_Brace_Bonus';
	Effect.AddToHitModifier(default.BRACE_AIM);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(NotMovedCondition());

	return Passive('Astartes_Brace', "img:///UILibrary_PerkIcons.UIPerk_steadyhands", false, Effect);
}

/// Bipod: reaction fire from an unmoved position gains aim (offsets the usual overwatch penalty).
static function X2AbilityTemplate Bipod()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_Bipod_Bonus';
	Effect.AddToHitModifier(default.BIPOD_REACTION_AIM);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(default.ReactionFireCondition);
	Effect.AbilityShooterConditions.AddItem(NotMovedCondition());

	return Passive('Astartes_Bipod', "img:///UILibrary_PerkIcons.UIPerk_coveringfire", false, Effect);
}

// --- Gunner --------------------------------------------------------------------------------

/// Tank Hunter: heavy weapon shots against armoured targets gain crit chance and damage.
/// Carnifexes, Dreadnoughts, Kytans and Meganobz all qualify; a cultist in rags does not.
static function X2AbilityTemplate TankHunter()
{
	local XMBEffect_ConditionalBonus Effect;
	local X2Condition_UnitStatCheck Armoured;

	Armoured = new class'X2Condition_UnitStatCheck';
	Armoured.AddCheckStat(eStat_ArmorMitigation, default.TANK_HUNTER_MIN_ARMOUR, eCheck_GreaterThanOrEqual);

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_TankHunter_Bonus';
	Effect.AddToHitModifier(default.TANK_HUNTER_CRIT, eHit_Crit);
	Effect.AddDamageModifier(default.TANK_HUNTER_DAMAGE);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityTargetConditions.AddItem(Armoured);

	return Passive('Astartes_TankHunter', "img:///UILibrary_PerkIcons.UIPerk_shredder", false, Effect);
}
