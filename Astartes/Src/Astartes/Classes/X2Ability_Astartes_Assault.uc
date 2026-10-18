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
var config int CHARGE_CRIT, CHARGE_DAMAGE;
var config float SHOCK_LANDING_RADIUS_METERS;
var config int HOLD_FAST_DEFENSE;
var config int HAMMER_OF_WRATH_DAMAGE, HAMMER_OF_WRATH_SHRED;
var config int ANGEL_OF_DEATH_ACTIONS, ANGEL_OF_DEATH_MOBILITY;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(ChainTeeth());
	Templates.AddItem(Whirlwind());
	Templates.AddItem(PowerArmourVeteran());
	Templates.AddItem(Duelist());
	Templates.AddItem(Decapitate());
	Templates.AddItem(Charge());
	Templates.AddItem(DeathFromAbove());
	Templates.AddItem(ShockLanding());
	Templates.AddItem(HitAndRun());
	Templates.AddItem(HammerOfWrath());
	Templates.AddItem(AngelOfDeath());
	Templates.AddItem(HoldFast());

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

// --- Blade (continued) ----------------------------------------------------------------------

/// A shooter condition: the unit has moved this turn (vanilla tracks 'MovesThisTurn').
static function X2Condition_UnitValue MovedCondition()
{
	local X2Condition_UnitValue Condition;

	Condition = new class'X2Condition_UnitValue';
	Condition.AddCheckValue('MovesThisTurn', 1, eCheck_GreaterThanOrEqual);
	return Condition;
}

/// Charge: a chainsword swung at the end of a charge bites deeper. After moving this turn, melee gains crit and damage.
static function X2AbilityTemplate Charge()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_Charge_Bonus';
	Effect.AddToHitModifier(default.CHARGE_CRIT, eHit_Crit);
	Effect.AddDamageModifier(default.CHARGE_DAMAGE);
	Effect.AbilityShooterConditions.AddItem(default.MeleeCondition);
	Effect.AbilityShooterConditions.AddItem(MovedCondition());

	return Passive('Astartes_Charge', "img:///UILibrary_PerkIcons.UIPerk_runandgun", false, Effect);
}

/// Death from Above: once per mission, this turn the jump pack costs nothing and the chainsword cannot miss.
static function X2AbilityTemplate DeathFromAbove()
{
	local X2AbilityTemplate Template;
	local XMBEffect_AbilityCostRefund FreeJump;
	local XMBEffect_ChangeHitResultForAttacker SureStrike;
	local XMBCondition_AbilityName JumpNames;

	JumpNames = new class'XMBCondition_AbilityName';
	JumpNames.IncludeAbilityNames.AddItem('Astartes_JumpPack');
	JumpNames.IncludeAbilityNames.AddItem('Astartes_DeepJump');

	FreeJump = new class'XMBEffect_AbilityCostRefund';
	FreeJump.EffectName = 'Astartes_DeathFromAbove_FreeJump';
	FreeJump.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	FreeJump.DuplicateResponse = eDupe_Refresh;
	FreeJump.bFreeCost = true;
	FreeJump.AbilityShooterConditions.AddItem(JumpNames);

	SureStrike = new class'XMBEffect_ChangeHitResultForAttacker';
	SureStrike.EffectName = 'Astartes_DeathFromAbove_SureStrike';
	SureStrike.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	SureStrike.DuplicateResponse = eDupe_Refresh;
	SureStrike.bRequireMiss = true;
	SureStrike.NewResult = eHit_Success;
	SureStrike.AbilityShooterConditions.AddItem(default.MeleeCondition);

	Template = SelfTargetActivated('Astartes_DeathFromAboveBlade', "img:///UILibrary_PerkIcons.UIPerk_reaper", false, FreeJump, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	Template.AddTargetEffect(SureStrike);
	AddCharges(Template, 1);
	Template.bShowActivation = true;
	return Template;
}

// --- Jump ----------------------------------------------------------------------------------

/// Shock Landing: the jump pack's landing concusses every enemy around the impact point.
static function X2AbilityTemplate ShockLanding()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius Radius;

	Template = SelfTargetTrigger('Astartes_ShockLanding', "img:///UILibrary_PerkIcons.UIPerk_stun", false, none, 'UnitIcarusJumped');

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.SHOCK_LANDING_RADIUS_METERS;
	Radius.bExcludeSelfAsTargetIfWithinRadius = true;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	Template.AddMultiTargetEffect(class'X2StatusEffects'.static.CreateDisorientedStatusEffect());
	Template.bShowActivation = true;
	return Template;
}

/// Hit and Run: a melee kill clears the jump pack's cooldown. Strike, then leave.
static function X2AbilityTemplate HitAndRun()
{
	local X2AbilityTemplate Template;
	local X2Effect_Astartes_ResetCooldown Reset;

	Reset = new class'X2Effect_Astartes_ResetCooldown';
	Reset.AbilityNames.AddItem('Astartes_JumpPack');
	Reset.AbilityNames.AddItem('Astartes_DeepJump');

	Template = SelfTargetTrigger('Astartes_HitAndRun', "img:///UILibrary_PerkIcons.UIPerk_hitandrun", false, Reset, 'KillMail');
	AddTriggerShooterCondition(Template, default.MeleeCondition);
	Template.bShowActivation = true;
	return Template;
}

/// Hammer of Wrath: come down on them. The turn the Marine lands from a jump, his melee hits harder and shreds armour.
static function X2AbilityTemplate HammerOfWrath()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Bonus;

	Bonus = new class'XMBEffect_ConditionalBonus';
	Bonus.EffectName = 'Astartes_HammerOfWrath_Bonus';
	Bonus.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Bonus.DuplicateResponse = eDupe_Refresh;
	Bonus.AddDamageModifier(default.HAMMER_OF_WRATH_DAMAGE);
	Bonus.AddShredModifier(default.HAMMER_OF_WRATH_SHRED);
	Bonus.AbilityShooterConditions.AddItem(default.MeleeCondition);

	Template = SelfTargetTrigger('Astartes_HammerOfWrath', "img:///UILibrary_PerkIcons.UIPerk_bladestorm", false, Bonus, 'UnitIcarusJumped');
	Template.bShowActivation = true;
	return Template;
}

/// Angel of Death: once per mission, the Marine becomes the storm. Actions restored, jump pack ready, faster this turn.
static function X2AbilityTemplate AngelOfDeath()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints Actions;
	local X2Effect_Astartes_ResetCooldown Reset;
	local X2Effect_PersistentStatChange Mobility;

	Actions = new class'X2Effect_GrantActionPoints';
	Actions.NumActionPoints = default.ANGEL_OF_DEATH_ACTIONS;
	Actions.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;

	Reset = new class'X2Effect_Astartes_ResetCooldown';
	Reset.AbilityNames.AddItem('Astartes_JumpPack');
	Reset.AbilityNames.AddItem('Astartes_DeepJump');

	Mobility = new class'X2Effect_PersistentStatChange';
	Mobility.EffectName = 'Astartes_AngelOfDeath_Mobility';
	Mobility.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Mobility.DuplicateResponse = eDupe_Refresh;
	Mobility.AddPersistentStatChange(eStat_Mobility, default.ANGEL_OF_DEATH_MOBILITY);

	Template = SelfTargetActivated('Astartes_AngelOfDeath', "img:///UILibrary_PerkIcons.UIPerk_icarusjump", false, Actions, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	Template.AddTargetEffect(Reset);
	Template.AddTargetEffect(Mobility);
	AddCharges(Template, 1);
	Template.bShowActivation = true;
	return Template;
}

// --- Bulwark (continued) -------------------------------------------------------------------

/// Hold Fast: braced in power armour, the Marine is far harder to hit in melee.
static function X2AbilityTemplate HoldFast()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_HoldFast_Bonus';
	Effect.AddToHitAsTargetModifier(-default.HOLD_FAST_DEFENSE);
	Effect.AbilityShooterConditionsAsTarget.AddItem(default.MeleeCondition);

	return Passive('Astartes_HoldFast', "img:///UILibrary_PerkIcons.UIPerk_fortress", false, Effect);
}
