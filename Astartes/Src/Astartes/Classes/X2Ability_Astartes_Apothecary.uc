//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Apothecary.uc
//  PURPOSE: Apothecary abilities (docs/classes.md), built on XModBase helpers. The narthecium is
//           a gremlin-slot item, so the vanilla protocol abilities work on it unchanged.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Apothecary].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Apothecary extends XMBAbility config(Astartes);

var config int STIMM_SHOT_COOLDOWN, STIMM_SHOT_RANGE_TILES;
var config int FIELD_SURGERY_CHARGES, REDUCTOR_MASTERY_BONUS_GENESEED;
var config int EMPERORS_MERCY_RADIUS_TILES, EMPERORS_MERCY_HEAL;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(StimmShot());
	Templates.AddItem(WarriorMedic());
	Templates.AddItem(FieldSurgery());
	Templates.AddItem(ReductorMastery());
	Templates.AddItem(ChirurgeonsFury());
	Templates.AddItem(EmperorsMercy());

	return Templates;
}

// --- Battle-Medic ----------------------------------------------------------------------------

/// Stimm Shot: a combat stimm gives a nearby battle-brother a free move. Cooldown.
static function X2AbilityTemplate StimmShot()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints Effect;
	local X2Condition_UnitProperty InRange;

	Effect = new class'X2Effect_GrantActionPoints';
	Effect.NumActionPoints = 1;
	Effect.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;

	Template = TargetedBuff('Astartes_StimmShot', "img:///UILibrary_PerkIcons.UIPerk_adrenalneurosympathy", false, Effect, class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY, eCost_Single);
	AddCooldown(Template, default.STIMM_SHOT_COOLDOWN);

	InRange = new class'X2Condition_UnitProperty';
	InRange.ExcludeDead = true;
	InRange.ExcludeHostileToSource = true;
	InRange.ExcludeFriendlyToSource = false;
	InRange.RequireWithinRange = true;
	InRange.WithinRange = class'XComWorldData'.const.WORLD_StepSize * default.STIMM_SHOT_RANGE_TILES * 1.5;
	Template.AbilityTargetConditions.AddItem(InRange);

	Template.ActivationSpeech = 'HealingAlly';
	return Template;
}

/// Warrior Medic: using the narthecium's healing protocols does not end the Apothecary's turn.
static function X2AbilityTemplate WarriorMedic()
{
	local XMBEffect_DoNotConsumeAllPoints Effect;

	Effect = new class'XMBEffect_DoNotConsumeAllPoints';
	Effect.EffectName = 'Astartes_WarriorMedic_Effect';
	Effect.AbilityNames.AddItem('MedicalProtocol');
	Effect.AbilityNames.AddItem('GremlinHeal');
	Effect.AbilityNames.AddItem('GremlinStabilize');
	Effect.AbilityNames.AddItem('RevivalProtocol');
	Effect.AbilityNames.AddItem('RestorativeMist');

	return Passive('Astartes_WarriorMedic', "img:///UILibrary_PerkIcons.UIPerk_medicalprotocol", false, Effect);
}

// --- Triage ----------------------------------------------------------------------------------

/// Field Surgery: a better-stocked narthecium. Extra heal charges per mission.
static function X2AbilityTemplate FieldSurgery()
{
	local XMBEffect_AddAbilityCharges Effect;

	Effect = new class'XMBEffect_AddAbilityCharges';
	Effect.AbilityNames.AddItem('GremlinHeal');
	Effect.BonusCharges = default.FIELD_SURGERY_CHARGES;

	return Passive('Astartes_FieldSurgery', "img:///UILibrary_PerkIcons.UIPerk_medkit", false, Effect);
}

// --- Reductor --------------------------------------------------------------------------------

/// Reductor Mastery: every recovery yields more geneseed (X2Effect_Astartes_RecoverGeneseed checks for this ability).
static function X2AbilityTemplate ReductorMastery()
{
	return Passive('Astartes_ReductorMastery', "img:///UILibrary_PerkIcons.UIPerk_stabilize", false);
}

// --- Battle-Medic (continued) ----------------------------------------------------------------

/// Chirurgeon's Fury: tending a brother sharpens the Apothecary's aim. After using the narthecium, his bolter hits this turn are critical.
static function X2AbilityTemplate ChirurgeonsFury()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ChangeHitResultForAttacker Crit;
	local XMBCondition_AbilityName Heals;

	Crit = new class'XMBEffect_ChangeHitResultForAttacker';
	Crit.EffectName = 'Astartes_ChirurgeonsFury_Crit';
	Crit.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Crit.DuplicateResponse = eDupe_Refresh;
	Crit.IncludeHitResults.AddItem(eHit_Success);
	Crit.IncludeHitResults.AddItem(eHit_Graze);
	Crit.NewResult = eHit_Crit;
	Crit.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);

	Heals = new class'XMBCondition_AbilityName';
	Heals.IncludeAbilityNames.AddItem('GremlinHeal');
	Heals.IncludeAbilityNames.AddItem('GremlinStabilize');
	Heals.IncludeAbilityNames.AddItem('RevivalProtocol');
	Heals.IncludeAbilityNames.AddItem('RestorativeMist');
	Heals.IncludeAbilityNames.AddItem('Astartes_StimmShot');
	Heals.ExcludeAbilityNames.AddItem('Astartes_ChirurgeonsFury'); // never trigger on itself

	Template = SelfTargetTrigger('Astartes_ChirurgeonsFury', "img:///UILibrary_PerkIcons.UIPerk_coupdegrace", false, Crit, 'AbilityActivated');
	// XMB evaluates ability-name/property conditions only in the trigger's TARGET conditions (shooter conditions
	// are plain unit checks). A shooter-side filter here let the ability re-trigger on its own activation forever
	// and crashed the game at mission start (playtest 2026-10-17).
	AddTriggerTargetCondition(Template, Heals);
	Template.bShowActivation = true;
	return Template;
}

// --- Chapter Master capstone ------------------------------------------------------------------

/// The Emperor's Mercy: every brother within reach is healed, bleeding-out and unconscious brothers stand up with
/// their actions restored. The Apothecary-born Chapter Master's relic ability. Free action, once per mission.
static function X2AbilityTemplate EmperorsMercy()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Effect_ApplyMedikitHeal Heal;
	local X2Effect_RemoveEffects Revive;
	local X2Condition_UnitProperty Brothers;

	Template = SelfTargetActivated('Astartes_EmperorsMercy', "img:///UILibrary_PerkIcons.UIPerk_revivalprotocol", false, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	AddCharges(Template, 1);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.EMPERORS_MERCY_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = false;
	Radius.bAllowDeadMultiTargetUnits = false;
	Template.AbilityMultiTargetStyle = Radius;

	Brothers = new class'X2Condition_UnitProperty';
	Brothers.ExcludeDead = true;
	Brothers.ExcludeHostileToSource = true;
	Brothers.ExcludeFriendlyToSource = false;
	Brothers.ExcludeRobotic = true;
	Brothers.ExcludeAlive = false;
	Template.AbilityMultiTargetConditions.AddItem(Brothers);

	Revive = new class'X2Effect_RemoveEffects';
	Revive.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	Revive.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	Revive.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Revive.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	Revive.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BurningName);
	Revive.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.PoisonedName);
	Revive.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.AcidBurningName);
	Template.AddMultiTargetEffect(Revive);

	Heal = new class'X2Effect_ApplyMedikitHeal';
	Heal.PerUseHP = default.EMPERORS_MERCY_HEAL;
	Template.AddMultiTargetEffect(Heal);

	Template.AddMultiTargetEffect(new class'X2Effect_RestoreActionPoints');

	Template.ActivationSpeech = 'HealingAlly';
	Template.bShowActivation = true;
	return Template;
}
