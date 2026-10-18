//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Chaplain.uc
//  PURPOSE: Chaplain abilities (docs/classes.md). The Chaplain is the Chapter's spiritual leader and a
//           melee fighter: crozius arcanum, bolt pistol, rosarius, and litanies that lift the brothers
//           around him. Most of his tree reuses Assault and Tactical abilities; these three are his own.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Chaplain].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Chaplain extends XMBAbility config(Astartes);

var config int CROZIUS_MASTERY_DAMAGE, CROZIUS_MASTERY_CRIT;
var config int LITANY_OF_HATE_CRIT;
var config int ROSARIUS_ARMOUR, ROSARIUS_DEFENSE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CroziusMastery());
	Templates.AddItem(LitanyOfHate());
	Templates.AddItem(Rosarius());

	return Templates;
}

// --- Crozius -------------------------------------------------------------------------------

/// Crozius Mastery: the crozius arcanum is a power maul in the hands of a zealot. Extra damage and crit with it.
static function X2AbilityTemplate CroziusMastery()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_CroziusMastery_Bonus';
	Effect.AddDamageModifier(default.CROZIUS_MASTERY_DAMAGE);
	Effect.AddToHitModifier(default.CROZIUS_MASTERY_CRIT, eHit_Crit);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);

	return Passive('Astartes_CroziusMastery', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", false, Effect);
}

// --- Litanies -------------------------------------------------------------------------------

/// Litany of Hate: the Chaplain's words carry. Every brother on the mission strikes harder in melee.
static function X2AbilityTemplate LitanyOfHate()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_LitanyOfHate_Effect';
	Effect.AddToHitModifier(default.LITANY_OF_HATE_CRIT, eHit_Crit);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);

	return SquadPassive('Astartes_LitanyOfHate', "img:///UILibrary_PerkIcons.UIPerk_inspire", false, Effect);
}

// --- Zeal -----------------------------------------------------------------------------------

/// Rosarius: the Chaplain's conversion field. Armour and defence.
static function X2AbilityTemplate Rosarius()
{
	local X2Effect_PersistentStatChange Effect;

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'Astartes_Rosarius_Effect';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.AddPersistentStatChange(eStat_ArmorMitigation, default.ROSARIUS_ARMOUR);
	Effect.AddPersistentStatChange(eStat_Defense, default.ROSARIUS_DEFENSE);

	return Passive('Astartes_Rosarius', "img:///UILibrary_PerkIcons.UIPerk_fortress", false, Effect);
}
