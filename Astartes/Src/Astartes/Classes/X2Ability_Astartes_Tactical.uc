//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Tactical.uc
//  PURPOSE: Tactical Marine abilities (docs/classes.md), built on XModBase helpers.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Tactical].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Tactical extends XMBAbility config(Astartes);

var config int BOLTER_DRILL_REFUNDS_PER_TURN;
var config int KRAKEN_DAMAGE, KRAKEN_PIERCE, KRAKEN_AIM;
var config int HELLFIRE_DAMAGE, HELLFIRE_SHRED;
var config int EXECUTIONER_HP_PERCENT, EXECUTIONER_CRITS_PER_TURN;
var config int RALLY_CHARGES, RALLY_RANGE_TILES;
var config int INSPIRE_RADIUS_TILES, INSPIRE_COOLDOWN;
var config int FOR_THE_EMPEROR_RADIUS_TILES, FOR_THE_EMPEROR_CHARGES;
var config int TACTICAL_DOCTRINE_MOBILITY, HOLD_THE_LINE_DEFENSE, CHAPTER_BANNER_WILL, COMBAT_SQUADS_CHARGES;
var config int RITES_OF_BATTLE_RADIUS_TILES, RITES_OF_BATTLE_AIM;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(BolterDrill());
	Templates.AddItem(KrakenRounds());
	Templates.AddItem(HellfireRounds());
	Templates.AddItem(Executioner());
	Templates.AddItem(Rally());
	Templates.AddItem(Inspire());
	Templates.AddItem(ForTheEmperor());
	Templates.AddItem(TacticalDoctrine());
	Templates.AddItem(HoldTheLine());
	Templates.AddItem(ChapterBanner());
	Templates.AddItem(CombatSquads());
	Templates.AddItem(RitesOfBattle());

	return Templates;
}

// --- Marksman ---------------------------------------------------------------------------

/// Bolter Drill: the first standard shot with the bolter each turn does not end the turn.
static function X2AbilityTemplate BolterDrill()
{
	local XMBEffect_AbilityCostRefund Effect;
	local XMBCondition_AbilityName NameCondition;

	Effect = new class'XMBEffect_AbilityCostRefund';
	Effect.EffectName = 'Astartes_BolterDrill_Refund';
	Effect.TriggeredEvent = 'Astartes_BolterDrill';
	Effect.bShowFlyOver = true;
	Effect.CountValueName = 'Astartes_BolterDrill_Uses';
	Effect.MaxRefundsPerTurn = default.BOLTER_DRILL_REFUNDS_PER_TURN;

	NameCondition = new class'XMBCondition_AbilityName';
	NameCondition.IncludeAbilityNames.AddItem('StandardShot');
	Effect.AbilityShooterConditions.AddItem(NameCondition);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);

	return Passive('Astartes_BolterDrill', "img:///UILibrary_PerkIcons.UIPerk_lightninghands", false, Effect);
}

/// Kraken Rounds: bolter shots trade aim for damage and armour piercing.
static function X2AbilityTemplate KrakenRounds()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_KrakenRounds_Bonus';
	Effect.AddDamageModifier(default.KRAKEN_DAMAGE);
	Effect.AddArmorPiercingModifier(default.KRAKEN_PIERCE);
	Effect.AddToHitModifier(default.KRAKEN_AIM);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);

	return Passive('Astartes_KrakenRounds', "img:///UILibrary_PerkIcons.UIPerk_deadeye", false, Effect);
}

/// Hellfire Rounds: bolter shots do extra damage and shred against organic targets (Tyranids, Orks, flesh).
static function X2AbilityTemplate HellfireRounds()
{
	local XMBEffect_ConditionalBonus Effect;
	local X2Condition_UnitProperty OrganicTarget;

	OrganicTarget = new class'X2Condition_UnitProperty';
	OrganicTarget.ExcludeRobotic = true;
	OrganicTarget.ExcludeOrganic = false;
	OrganicTarget.ExcludeFriendlyToSource = true;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_HellfireRounds_Bonus';
	Effect.AddDamageModifier(default.HELLFIRE_DAMAGE);
	Effect.AddShredModifier(default.HELLFIRE_SHRED);
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityTargetConditions.AddItem(OrganicTarget);

	return Passive('Astartes_HellfireRounds', "img:///UILibrary_PerkIcons.UIPerk_shredder", false, Effect);
}

/// Executioner: once per turn, a bolter hit on a target at or below half health is a critical hit.
static function X2AbilityTemplate Executioner()
{
	local XMBEffect_ChangeHitResultForAttacker Effect;
	local X2Condition_UnitStatCheck WoundedTarget;

	WoundedTarget = new class'X2Condition_UnitStatCheck';
	WoundedTarget.AddCheckStat(eStat_HP, default.EXECUTIONER_HP_PERCENT, eCheck_LessThanOrEqual, , , true);

	Effect = new class'XMBEffect_ChangeHitResultForAttacker';
	Effect.EffectName = 'Astartes_Executioner_Crit';
	Effect.IncludeHitResults.AddItem(eHit_Success);
	Effect.IncludeHitResults.AddItem(eHit_Graze);
	Effect.NewResult = eHit_Crit;
	Effect.TriggeredEvent = 'Astartes_Executioner';
	Effect.bShowFlyOver = true;
	Effect.CountValueName = 'Astartes_Executioner_Uses';
	Effect.MaxChangesPerTurn = default.EXECUTIONER_CRITS_PER_TURN;
	Effect.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Effect.AbilityTargetConditions.AddItem(WoundedTarget);

	return Passive('Astartes_Executioner', "img:///UILibrary_PerkIcons.UIPerk_coupdegrace", false, Effect);
}

// --- Sergeant ---------------------------------------------------------------------------

/// Rally: give a nearby battle-brother an extra action. Limited charges per mission.
static function X2AbilityTemplate Rally()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints Effect;
	local X2Condition_UnitProperty InRange;

	Effect = new class'X2Effect_GrantActionPoints';
	Effect.NumActionPoints = 1;
	Effect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;

	Template = TargetedBuff('Astartes_Rally', "img:///UILibrary_PerkIcons.UIPerk_aidprotocol", false, Effect, class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY, eCost_Single);
	AddCharges(Template, default.RALLY_CHARGES);

	InRange = new class'X2Condition_UnitProperty';
	InRange.ExcludeDead = true;
	InRange.ExcludeHostileToSource = true;
	InRange.ExcludeFriendlyToSource = false;
	InRange.RequireWithinRange = true;
	InRange.WithinRange = class'XComWorldData'.const.WORLD_StepSize * default.RALLY_RANGE_TILES * 1.5;
	Template.AbilityTargetConditions.AddItem(InRange);

	Template.ActivationSpeech = 'Inspire';
	return Template;
}

/// Inspire: shake off disorientation, panic and stun on every ally nearby. Cooldown.
static function X2AbilityTemplate Inspire()
{
	local X2AbilityTemplate Template;
	local X2Effect_RemoveEffects RemoveEffects;
	local XMBAbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;

	Template = SelfTargetActivated('Astartes_Inspire', "img:///UILibrary_PerkIcons.UIPerk_inspire", false, none, class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY, eCost_Single);
	AddCooldown(Template, default.INSPIRE_COOLDOWN);

	Radius = new class'XMBAbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.INSPIRE_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;

	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeDead = true;
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(Allies);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DazedName);
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.ActivationSpeech = 'Inspire';
	return Template;
}

/// For the Emperor: once per mission, every ally in range regains an action.
static function X2AbilityTemplate ForTheEmperor()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints Effect;
	local XMBAbilityMultiTarget_Radius Radius;
	local X2Condition_UnitProperty Allies;

	Template = SelfTargetActivated('Astartes_ForTheEmperor', "img:///UILibrary_PerkIcons.UIPerk_solace", false, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Single);
	AddCharges(Template, default.FOR_THE_EMPEROR_CHARGES);

	Radius = new class'XMBAbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.FOR_THE_EMPEROR_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;

	Allies = new class'X2Condition_UnitProperty';
	Allies.ExcludeDead = true;
	Allies.ExcludeHostileToSource = true;
	Allies.ExcludeFriendlyToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(Allies);

	Effect = new class'X2Effect_GrantActionPoints';
	Effect.NumActionPoints = 1;
	Effect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddMultiTargetEffect(Effect);

	Template.ActivationSpeech = 'Inspire';
	return Template;
}

// --- Sergeant (continued) --------------------------------------------------------------------

/// Tactical Doctrine: the sergeant's drill keeps the whole squad moving. Every Marine gains mobility.
static function X2AbilityTemplate TacticalDoctrine()
{
	local X2Effect_PersistentStatChange Effect;

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'Astartes_TacticalDoctrine_Effect';
	Effect.AddPersistentStatChange(eStat_Mobility, default.TACTICAL_DOCTRINE_MOBILITY);

	return SquadPassive('Astartes_TacticalDoctrine', "img:///UILibrary_PerkIcons.UIPerk_squadsight", false, Effect);
}

/// Hold the Line: the squad holds its ground. Every Marine in full cover is harder to hit.
static function X2AbilityTemplate HoldTheLine()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_HoldTheLine_Effect';
	Effect.AddToHitAsTargetModifier(-default.HOLD_THE_LINE_DEFENSE);
	Effect.AbilityTargetConditionsAsTarget.AddItem(default.FullCoverCondition);

	return SquadPassive('Astartes_HoldTheLine', "img:///UILibrary_PerkIcons.UIPerk_shieldwall", false, Effect);
}

/// Chapter Banner: the standard of the Chapter steels every brother's will (and steadies the Librarian: Perils of the Warp is less likely while the banner stands).
static function X2AbilityTemplate ChapterBanner()
{
	local X2Effect_PersistentStatChange Effect;

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'Astartes_ChapterBanner_Effect';
	Effect.AddPersistentStatChange(eStat_Will, default.CHAPTER_BANNER_WILL);

	return SquadPassive('Astartes_ChapterBanner', "img:///UILibrary_PerkIcons.UIPerk_inspire", false, Effect);
}

/// Combat Squads: split the squad. The sergeant and one brother each gain a free move.
static function X2AbilityTemplate CombatSquads()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints TargetMove, SelfMove;
	local X2Condition_UnitProperty NotSelf;

	TargetMove = new class'X2Effect_GrantActionPoints';
	TargetMove.NumActionPoints = 1;
	TargetMove.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;

	SelfMove = new class'X2Effect_GrantActionPoints';
	SelfMove.NumActionPoints = 1;
	SelfMove.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;

	Template = TargetedBuff('Astartes_CombatSquads', "img:///UILibrary_PerkIcons.UIPerk_runandgun", false, TargetMove, class'UIUtilities_Tactical'.const.CLASS_CAPTAIN_PRIORITY, eCost_Free);
	Template.AddShooterEffect(SelfMove);
	AddCharges(Template, default.COMBAT_SQUADS_CHARGES);

	NotSelf = new class'X2Condition_UnitProperty';
	NotSelf.ExcludeDead = true;
	NotSelf.ExcludeHostileToSource = true;
	NotSelf.ExcludeFriendlyToSource = false;
	NotSelf.RequireSquadmates = true;
	Template.AbilityTargetConditions.AddItem(NotSelf);

	Template.ActivationSpeech = 'Inspire';
	Template.bShowActivation = true;
	return Template;
}

// --- Chapter Master capstone ------------------------------------------------------------------

/// Rites of Battle: the Chapter Master's word. Every Marine within reach regains all actions and gains aim for the
/// turn. The Tactical-born Chapter Master's relic ability. Free action, once per mission.
static function X2AbilityTemplate RitesOfBattle()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Effect_RestoreActionPoints Restore;
	local XMBEffect_ConditionalBonus Aim;

	Template = SelfTargetActivated('Astartes_RitesOfBattle', "img:///UILibrary_PerkIcons.UIPerk_inspire", false, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	AddCharges(Template, 1);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.RITES_OF_BATTLE_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = false;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.AddItem(default.LivingFriendlyTargetProperty);

	Restore = new class'X2Effect_RestoreActionPoints';
	Template.AddMultiTargetEffect(Restore);

	Aim = new class'XMBEffect_ConditionalBonus';
	Aim.EffectName = 'Astartes_RitesOfBattle_Aim';
	Aim.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Aim.DuplicateResponse = eDupe_Refresh;
	Aim.AddToHitModifier(default.RITES_OF_BATTLE_AIM);
	Template.AddMultiTargetEffect(Aim);

	Template.ActivationSpeech = 'Inspire';
	Template.bShowActivation = true;
	return Template;
}
