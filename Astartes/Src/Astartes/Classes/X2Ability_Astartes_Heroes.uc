//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Heroes.uc
//  PURPOSE: Abilities of the Imperial heroes (design.md 9.1f): the Canoness of the Adepta Sororitas
//           and the Commissar of the Officio Prefectus. Their trees otherwise reuse Marine abilities.
//           Tuning in XComAstartes.ini under [Astartes.X2Ability_Astartes_Heroes].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Heroes extends XMBAbility config(Astartes);

var config int DIVINE_GUIDANCE_CHARGES;
var config int MARTYR_DAMAGE, MARTYR_CRIT, MARTYR_TURNS;
var config int SUMMARY_EXECUTION_CHARGES;
var config int STAND_YOUR_GROUND_DEFENSE, STAND_YOUR_GROUND_RADIUS_TILES, STAND_YOUR_GROUND_COOLDOWN;
var config int HATRED_AIM, HATRED_CRIT, HATRED_DAMAGE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(DivineGuidance());
	Templates.AddItem(SpiritOfTheMartyr());
	Templates.AddItem(AuraOfDiscipline());
	Templates.AddItem(SummaryExecution());
	Templates.AddItem(StandYourGround());
	// Each hero is the answer to one enemy (user, 2026-10-19): Commissar vs Orks, Inquisitor vs Tyranids, the Saint vs Chaos.
	Templates.AddItem(FactionHatred('Astartes_BaneOfTheGreenskin', 'Orks', "img:///UILibrary_PerkIcons.UIPerk_bulletshred"));
	Templates.AddItem(FactionHatred('Astartes_OrdoXenos', 'Tyranids', "img:///UILibrary_PerkIcons.UIPerk_tacticalsense"));
	Templates.AddItem(FactionHatred('Astartes_LightOfTheEmperor', 'Chaos', "img:///UILibrary_PerkIcons.UIPerk_inspire"));
	return Templates;
}

// --- Faction hatred -----------------------------------------------------------------------

/// Passive: more aim, crit and damage against one enemy faction (judged by that faction's spawn lists).
static function X2AbilityTemplate FactionHatred(name AbilityName, name Faction, string Icon)
{
	local XMBEffect_ConditionalBonus Effect;
	local X2Condition_Astartes_FactionTarget OfFaction;

	OfFaction = new class'X2Condition_Astartes_FactionTarget';
	OfFaction.FactionName = Faction;
	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = name(string(AbilityName) $ "_Bonus");
	Effect.AddToHitModifier(default.HATRED_AIM, eHit_Success);
	Effect.AddToHitModifier(default.HATRED_CRIT, eHit_Crit);
	Effect.AddDamageModifier(default.HATRED_DAMAGE);
	Effect.AbilityTargetConditions.AddItem(OfFaction);
	return Passive(AbilityName, Icon, false, Effect);
}

// --- Canoness ---------------------------------------------------------------------------------

/// Divine Guidance: the Emperor guides her hand. For the rest of the turn her attacks cannot miss and always crit.
static function X2AbilityTemplate DivineGuidance()
{
	local X2AbilityTemplate Template;
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_DivineGuidance_Bonus';
	Effect.AddToHitModifier(100, eHit_Success);
	Effect.AddToHitModifier(100, eHit_Crit);
	Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Effect.DuplicateResponse = eDupe_Refresh;

	Template = SelfTargetActivated('Astartes_DivineGuidance', "img:///UILibrary_PerkIcons.UIPerk_deadeye", false, Effect, class'UIUtilities_Tactical'.const.CLASS_CAPTAIN_PRIORITY, eCost_Free);
	AddCharges(Template, default.DIVINE_GUIDANCE_CHARGES);
	Template.bShowActivation = true;
	return Template;
}

/// Spirit of the Martyr: wounds feed her zeal. Whenever she takes damage she deals more and crits more for a while.
static function X2AbilityTemplate SpiritOfTheMartyr()
{
	local XMBEffect_ConditionalBonus Effect;

	Effect = new class'XMBEffect_ConditionalBonus';
	Effect.EffectName = 'Astartes_SpiritOfTheMartyr_Bonus';
	Effect.AddDamageModifier(default.MARTYR_DAMAGE);
	Effect.AddToHitModifier(default.MARTYR_CRIT, eHit_Crit);
	Effect.BuildPersistentEffect(default.MARTYR_TURNS, false, true, false, eGameRule_PlayerTurnEnd);
	Effect.DuplicateResponse = eDupe_Refresh;

	return SelfTargetTrigger('Astartes_SpiritOfTheMartyr', "img:///UILibrary_PerkIcons.UIPerk_regeneration", false, Effect, 'UnitTakeEffectDamage');
}

// --- Commissar --------------------------------------------------------------------------------

/// Aura of Discipline: no one breaks while the Commissar watches. The squad cannot panic.
static function X2AbilityTemplate AuraOfDiscipline()
{
	local X2Effect_DamageImmunity Effect;

	Effect = new class'X2Effect_DamageImmunity';
	Effect.EffectName = 'Astartes_AuraOfDiscipline_Effect';
	Effect.ImmuneTypes.AddItem('Panic');
	return SquadPassive('Astartes_AuraOfDiscipline', "img:///UILibrary_PerkIcons.UIPerk_sentinel", false, Effect);
}

/// Summary Execution: a bolt-pistol round for anyone who breaks. Kills a panicked or mind-controlled unit outright,
/// friend or foe; a Marine seized by an enemy psyker is not spared. Cannot miss.
static function X2AbilityTemplate SummaryExecution()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints Cost;
	local X2Condition_UnitProperty TargetProperty;
	local X2Condition_Visibility Visibility;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Astartes_SummaryExecution');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.Hostility = eHostility_Offensive;
	Template.bShowActivation = true;
	Template.DisplayTargetHitChance = false;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(Cost);
	AddCharges(Template, default.SUMMARY_EXECUTION_CHARGES);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	TargetProperty = new class'X2Condition_UnitProperty';
	TargetProperty.ExcludeDead = true;
	TargetProperty.ExcludeFriendlyToSource = false;
	TargetProperty.ExcludeHostileToSource = false;
	TargetProperty.ExcludeRobotic = true;
	TargetProperty.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(TargetProperty);
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_Astartes_Wavering');
	Visibility = new class'X2Condition_Visibility';
	Visibility.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(Visibility);

	Template.AddTargetEffect(new class'X2Effect_Astartes_Execute');

	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/// Stand Your Ground: the Commissar plants his feet and the line holds. Allies near him gain defence until his next turn.
static function X2AbilityTemplate StandYourGround()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Effect_PersistentStatChange Effect;

	Template = SelfTargetActivated('Astartes_StandYourGround', "img:///UILibrary_PerkIcons.UIPerk_fortress", false, none, class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY, eCost_Single);
	AddCooldown(Template, default.STAND_YOUR_GROUND_COOLDOWN);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.STAND_YOUR_GROUND_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = false;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.AddItem(default.LivingFriendlyTargetProperty);

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.EffectName = 'Astartes_StandYourGround_Effect';
	Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Effect.DuplicateResponse = eDupe_Refresh;
	Effect.AddPersistentStatChange(eStat_Defense, default.STAND_YOUR_GROUND_DEFENSE);
	Template.AddMultiTargetEffect(Effect);

	Template.ActivationSpeech = 'Inspire';
	Template.bShowActivation = true;
	return Template;
}
