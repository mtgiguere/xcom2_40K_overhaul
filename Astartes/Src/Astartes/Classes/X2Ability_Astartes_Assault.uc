//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Assault.uc
//  PURPOSE: Assault Marine abilities (docs/classes.md), built on XModBase helpers.
//           Chainsword is the primary weapon, bolt pistol the secondary.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Assault].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Assault extends XMBAbility config(Astartes);

var config int CHAIN_TEETH_DAMAGE;
var config int WHIRLWIND_REFUNDS_PER_TURN;
var config int POWER_ARMOUR_VETERAN_REGEN, POWER_ARMOUR_VETERAN_MAX_PER_MISSION;
var config int DUELIST_PIERCE, DUELIST_CRIT;
var config int DECAPITATE_COOLDOWN;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(ChainTeeth());
	Templates.AddItem(Whirlwind());
	Templates.AddItem(PowerArmourVeteran());
	Templates.AddItem(Duelist());
	Templates.AddItem(Decapitate());

	return Templates;
}

// --- Blade --------------------------------------------------------------------------------

/// Chain Teeth: chainsword attacks deal extra damage.
static function X2AbilityTemplate ChainTeeth()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_ChainTeeth_Bonus';
	Effect.AddDamageModifier(default.CHAIN_TEETH_DAMAGE);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);

	return Passive('Astartes_ChainTeeth', "img:///UILibrary_PerkIcons.UIPerk_blademaster", false, Effect);
}

/// Whirlwind: a melee kill refunds the action, up to a limit per turn.
static function X2AbilityTemplate Whirlwind()
{
	local XMBEffect_AbilityCostRefund Effect;

	Effect = new class'XMBEffect_AbilityCostRefund';
	Effect.EffectName = 'Astartes_Whirlwind_Refund';
	Effect.TriggeredEvent = 'Astartes_Whirlwind';
	Effect.bShowFlyOver = true;
	Effect.CountValueName = 'Astartes_Whirlwind_Uses';
	Effect.MaxRefundsPerTurn = default.WHIRLWIND_REFUNDS_PER_TURN;
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);
	Effect.AbilityTargetConditions.AddItem(default.DeadCondition);

	return Passive('Astartes_Whirlwind', "img:///UILibrary_PerkIcons.UIPerk_reaper", false, Effect);
}

/// Duelist: chainsword attacks pierce armour and crit more often. Built to kill armoured champions.
static function X2AbilityTemplate Duelist()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_Duelist_Bonus';
	Effect.AddArmorPiercingModifier(default.DUELIST_PIERCE);
	Effect.AddToHitModifier(default.DUELIST_CRIT, eHit_Crit);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);

	return Passive('Astartes_Duelist', "img:///UILibrary_PerkIcons.UIPerk_slash", false, Effect);
}

/// Decapitate: a chainsword strike that cannot miss. Cooldown.
static function X2AbilityTemplate Decapitate()
{
	local X2AbilityTemplate Template;

	Template = MeleeAttack('Astartes_Decapitate', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", false, none, class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY, eCost_SingleConsumeAll);
	Template.AbilityToHitCalc = default.DeadEye;
	AddCooldown(Template, default.DECAPITATE_COOLDOWN);
	Template.bShowActivation = true;
	return Template;
}

// --- Bulwark ------------------------------------------------------------------------------

/// Power Armour Veteran: the Larraman cells and the suit's systems close wounds mid-fight.
static function X2AbilityTemplate PowerArmourVeteran()
{
	local X2Effect_Regeneration Effect;

	Effect = new class'X2Effect_Regeneration';
	Effect.EffectName = 'Astartes_PowerArmourVeteran_Regen';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.HealAmount = default.POWER_ARMOUR_VETERAN_REGEN;
	Effect.MaxHealAmount = default.POWER_ARMOUR_VETERAN_MAX_PER_MISSION;
	Effect.HealthRegeneratedName = 'Astartes_PowerArmourVeteran_Healed';

	return Passive('Astartes_PowerArmourVeteran', "img:///UILibrary_PerkIcons.UIPerk_regeneration", false, Effect);
}
