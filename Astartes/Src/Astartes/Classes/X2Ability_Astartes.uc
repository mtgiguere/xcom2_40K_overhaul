//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes.uc
//  PURPOSE: Abilities shared by all Marines and the Apothecary's Chapter-economy abilities.
//           Class-specific trees live in their own X2Ability_Astartes_<Class> files.
//---------------------------------------------------------------------------------------
class X2Ability_Astartes extends X2Ability config(Astartes);

var config int GENESEED_PER_RECOVERY;
var config int GENESEED_RECOVERY_RANGE_TILES;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(KnowNoFear());
	Templates.AddItem(AstartesPhysiology());
	Templates.AddItem(RecoverGeneseed());

	return Templates;
}

/// Astartes Physiology: the oolitic kidney and multi-lung filter toxins. Marines are immune to
/// poison. Fire and acid still burn; that is armour, not biology.
static function X2AbilityTemplate AstartesPhysiology()
{
	local X2AbilityTemplate Template;
	local X2Effect_DamageImmunity ImmunityEffect;

	Template = PurePassive('Astartes_Physiology', "img:///UILibrary_PerkIcons.UIPerk_adrenalneurosympathy", false, 'eAbilitySource_Perk', true);

	ImmunityEffect = new class'X2Effect_DamageImmunity';
	ImmunityEffect.ImmuneTypes.AddItem('Poison');
	ImmunityEffect.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	ImmunityEffect.BuildPersistentEffect(1, true, false, false);
	ImmunityEffect.EffectName = 'Astartes_Physiology_Immunity';
	Template.AddTargetEffect(ImmunityEffect);

	return Template;
}

/// Know No Fear: Space Marines are immune to panic. Will still exists and is spent elsewhere
/// (Chaos corruption, Perils of the Warp). Deliberately NOT immunity to 'Mental', so psychic
/// control and sorcery still work on Marines.
static function X2AbilityTemplate KnowNoFear()
{
	local X2AbilityTemplate Template;
	local X2Effect_DamageImmunity ImmunityEffect;

	Template = PurePassive('Astartes_KnowNoFear', "img:///UILibrary_PerkIcons.UIPerk_fortress", false, 'eAbilitySource_Perk', true);

	ImmunityEffect = new class'X2Effect_DamageImmunity';
	ImmunityEffect.ImmuneTypes.AddItem('Panic');
	ImmunityEffect.BuildPersistentEffect(1, true, false, false);
	ImmunityEffect.EffectName = 'Astartes_KnowNoFear_Immunity';
	Template.AddTargetEffect(ImmunityEffect);

	return Template;
}

/// Recover Geneseed: the Apothecary harvests the progenoid glands of a fallen battle-brother
/// standing next to the body. Costs one action, does not end the turn. Each body once.
static function X2AbilityTemplate RecoverGeneseed()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityTarget_Single SingleTarget;
	local X2Condition_UnitProperty ShooterCondition, TargetCondition;
	local X2Condition_UnitValue NotYetHarvested;
	local X2Effect_Astartes_RecoverGeneseed HarvestEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Astartes_RecoverGeneseed');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_medkit";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STABILIZE_PRIORITY + 1;
	Template.Hostility = eHostility_Neutral;
	Template.bLimitTargetIcons = true;
	Template.bShowActivation = true;
	Template.bDisplayInUITacticalText = true;
	Template.bDisplayInUITooltip = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowDestructibleObjects = false;
	Template.AbilityTargetStyle = SingleTarget;

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);
	Template.AddShooterEffectExclusions();

	// Target: a dead, organic, friendly soldier's body within reach, not yet harvested.
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeDead = false;
	TargetCondition.ExcludeAlive = true;
	TargetCondition.ExcludeRobotic = true;
	TargetCondition.ExcludeOrganic = false;
	TargetCondition.ExcludeAlien = true;
	TargetCondition.ExcludeCivilian = true;
	TargetCondition.ExcludeCosmetic = true;
	TargetCondition.ExcludeHostileToSource = true;
	TargetCondition.ExcludeFriendlyToSource = false;
	TargetCondition.RequireWithinRange = true;
	TargetCondition.WithinRange = class'XComWorldData'.const.WORLD_StepSize * default.GENESEED_RECOVERY_RANGE_TILES * 1.5;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	NotYetHarvested = new class'X2Condition_UnitValue';
	NotYetHarvested.AddCheckValue(class'X2Effect_Astartes_RecoverGeneseed'.default.HarvestedValueName, 1, eCheck_LessThan);
	Template.AbilityTargetConditions.AddItem(NotYetHarvested);

	HarvestEffect = new class'X2Effect_Astartes_RecoverGeneseed';
	HarvestEffect.GeneseedAmount = default.GENESEED_PER_RECOVERY;
	Template.AddTargetEffect(HarvestEffect);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');

	Template.ActivationSpeech = 'StabilizingAlly';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}
