//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Devastator.uc
//  PURPOSE: Devastator abilities (docs/classes.md), built on XModBase helpers.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Devastator].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Devastator extends XMBAbility config(Astartes);

var config int BRACE_AIM;
var config int BIPOD_REACTION_AIM;
var config int TANK_HUNTER_CRIT, TANK_HUNTER_DAMAGE, TANK_HUNTER_MIN_ARMOUR;
var config int PLASMA_OVERCHARGE_DAMAGE, PLASMA_OVERCHARGE_COOLDOWN;
var config int LASCANNON_CHARGES, LASCANNON_PIERCE, LASCANNON_DAMAGE;
var config int HEAVY_STANCE_REFUNDS_PER_TURN;
var config int KRAK_MISSILE_COOLDOWN, KRAK_MISSILE_DAMAGE, KRAK_MISSILE_PIERCE;
var config int WEAPON_MOUNT_ARMOUR, WEAPON_MOUNT_DEFENSE;
var config int MELTA_CHARGES, MELTA_RANGE_TILES, MELTA_DAMAGE, MELTA_PIERCE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Brace());
	Templates.AddItem(Bipod());
	Templates.AddItem(TankHunter());
	Templates.AddItem(PlasmaOvercharge());
	Templates.AddItem(LascannonRound());
	Templates.AddItem(HeavyStance());
	Templates.AddItem(KrakMissile());
	Templates.AddItem(WeaponMount());
	Templates.AddItem(MeltaRound());

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

	return Passive('Astartes_Bipod', "img:///UILibrary_PerkIcons.UIPerk_coverfire", false, Effect);
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

// --- Gunner ------------------------------------------------------------------------------------

/// Plasma Overcharge: run the coils hot. Heavy-weapon shots this turn deal extra damage. Cooldown.
static function X2AbilityTemplate PlasmaOvercharge()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Bonus;

	Bonus = new class'XMBEffect_ConditionalBonus';
	Bonus.EffectName = 'Astartes_PlasmaOvercharge_Bonus';
	Bonus.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Bonus.DuplicateResponse = eDupe_Refresh;
	Bonus.AddDamageModifier(default.PLASMA_OVERCHARGE_DAMAGE);
	Bonus.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);

	Template = SelfTargetActivated('Astartes_PlasmaOvercharge', "img:///UILibrary_PerkIcons.UIPerk_capacitordischarge", false, Bonus, class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY, eCost_Free);
	AddCooldown(Template, default.PLASMA_OVERCHARGE_COOLDOWN);
	Template.bShowActivation = true;
	return Template;
}

/// Lascannon Round: one shot, one hole. A heavy-weapon shot with great armour piercing. Limited charges.
static function X2AbilityTemplate LascannonRound()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Bonus;

	Template = Attack('Astartes_LascannonRound', "img:///UILibrary_PerkIcons.UIPerk_shreddergun", false, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_WeaponConsumeAll);
	AddCharges(Template, default.LASCANNON_CHARGES);
	Bonus = AddBonusPassive(Template);
	Bonus.AddArmorPiercingModifier(default.LASCANNON_PIERCE);
	Bonus.AddDamageModifier(default.LASCANNON_DAMAGE);
	return Template;
}

/// Krak Missile: the anti-armour shot. Extra damage and piercing. Cooldown.
static function X2AbilityTemplate KrakMissile()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Bonus;

	Template = Attack('Astartes_KrakMissile', "img:///UILibrary_PerkIcons.UIPerk_firerocket", false, none, class'UIUtilities_Tactical'.const.CLASS_CAPTAIN_PRIORITY, eCost_WeaponConsumeAll);
	AddCooldown(Template, default.KRAK_MISSILE_COOLDOWN);
	Bonus = AddBonusPassive(Template);
	Bonus.AddDamageModifier(default.KRAK_MISSILE_DAMAGE);
	Bonus.AddArmorPiercingModifier(default.KRAK_MISSILE_PIERCE);
	return Template;
}

/// Melta Round: point blank, nothing stops it. A short-range heavy shot that ignores armour. Limited charges.
static function X2AbilityTemplate MeltaRound()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Bonus;

	Template = Attack('Astartes_MeltaRound', "img:///UILibrary_PerkIcons.UIPerk_shredder", false, none, class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY, eCost_WeaponConsumeAll);
	AddCharges(Template, default.MELTA_CHARGES);
	Template.AbilityTargetConditions.AddItem(TargetWithinTiles(default.MELTA_RANGE_TILES));
	Bonus = AddBonusPassive(Template);
	Bonus.AddArmorPiercingModifier(default.MELTA_PIERCE);
	Bonus.AddDamageModifier(default.MELTA_DAMAGE);
	return Template;
}

// --- Emplacement (continued) -------------------------------------------------------------------

/// Heavy Stance: from a set position the heavy weapon's first shot of the turn does not end it.
static function X2AbilityTemplate HeavyStance()
{
	local XMBEffect_AbilityCostRefund Effect;
	local XMBCondition_AbilityName NameCondition;

	Effect = new class'XMBEffect_AbilityCostRefund';
	Effect.EffectName = 'Astartes_HeavyStance_Refund';
	Effect.TriggeredEvent = 'Astartes_HeavyStance';
	Effect.bShowFlyOver = true;
	Effect.CountValueName = 'Astartes_HeavyStance_Uses';
	Effect.MaxRefundsPerTurn = default.HEAVY_STANCE_REFUNDS_PER_TURN;

	NameCondition = new class'XMBCondition_AbilityName';
	NameCondition.IncludeAbilityNames.AddItem('StandardShot');
	Effect.AbilityShooterConditions.AddItem(NameCondition);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityShooterConditions.AddItem(NotMovedCondition());

	return Passive('Astartes_HeavyStance', "img:///UILibrary_PerkIcons.UIPerk_salvo", false, Effect);
}

/// Weapon Mount: dug in behind the gun. While the Devastator has not moved this turn he gains armour and defence.
static function X2AbilityTemplate WeaponMount()
{
	local XMBEffect_ConditionalStatChange Effect;

	Effect = new class'XMBEffect_ConditionalStatChange';
	Effect.EffectName = 'Astartes_WeaponMount_Effect';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.AddPersistentStatChange(eStat_ArmorMitigation, default.WEAPON_MOUNT_ARMOUR);
	Effect.AddPersistentStatChange(eStat_Defense, default.WEAPON_MOUNT_DEFENSE);
	Effect.Conditions.AddItem(NotMovedCondition());

	return Passive('Astartes_WeaponMount', "img:///UILibrary_PerkIcons.UIPerk_fortress", false, Effect);
}
