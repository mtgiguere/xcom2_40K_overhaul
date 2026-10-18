//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes.uc
//  PURPOSE: Abilities shared by all Marines and the Apothecary's Chapter-economy abilities.
//           Class-specific trees live in their own X2Ability_Astartes_<Class> files.
//---------------------------------------------------------------------------------------
class X2Ability_Astartes extends X2Ability config(Astartes);

var config int GENESEED_PER_RECOVERY;
var config int GENESEED_RECOVERY_RANGE_TILES;
var config int POWER_ARMOUR_HEALTH_BONUS;
var config int POWER_ARMOUR_MITIGATION;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(KnowNoFear());
	Templates.AddItem(AstartesPhysiology());
	Templates.AddItem(RecoverGeneseed());
	Templates.AddItem(PowerArmourStats());

	return Templates;
}

/// Power Armour Mk VII: the stats of the Marines' basic armour. Attached to the vanilla KevlarArmor
/// template at load (the armour packs' body parts are bound to the vanilla armour names, so the vanilla
/// tiers *are* the power armour marks). Hidden item ability, same pattern as MediumPlatedArmorStats.
static function X2AbilityTemplate PowerArmourStats()
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange StatEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Astartes_PowerArmourStats');
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_UnitPostBeginPlay');

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, false, false);
	StatEffect.AddPersistentStatChange(eStat_HP, default.POWER_ARMOUR_HEALTH_BONUS);
	StatEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.POWER_ARMOUR_MITIGATION);
	Template.AddTargetEffect(StatEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

/// Turn vanilla Kevlar into Power Armour Mk VII: grant the stat ability and show the numbers in the armoury.
static function MakeKevlarPowerArmour()
{
	local X2ItemTemplateManager ItemMgr;
	local array<X2DataTemplate> Templates;
	local X2ArmorTemplate Armor;
	local int i;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemMgr.FindDataTemplateAllDifficulties('KevlarArmor', Templates);
	for (i = 0; i < Templates.Length; i++)
	{
		Armor = X2ArmorTemplate(Templates[i]);
		if (Armor == none || Armor.Abilities.Find('Astartes_PowerArmourStats') != INDEX_NONE)
		{
			continue;
		}
		Armor.Abilities.AddItem('Astartes_PowerArmourStats');
		Armor.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, default.POWER_ARMOUR_HEALTH_BONUS, true);
		Armor.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, default.POWER_ARMOUR_MITIGATION, true);
	}
	`log("Astartes: KevlarArmor is now Power Armour Mk VII (+" $ default.POWER_ARMOUR_HEALTH_BONUS @ "HP, +" $ default.POWER_ARMOUR_MITIGATION @ "armour)",, 'Astartes');
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
