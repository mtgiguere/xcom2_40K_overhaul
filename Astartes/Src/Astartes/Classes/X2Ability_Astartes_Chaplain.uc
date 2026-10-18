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
var config int LITANY_OF_THE_DEVOUT_RADIUS_TILES;
var config int PURGE_THE_UNCLEAN_COOLDOWN;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CroziusMastery());
	Templates.AddItem(LitanyOfHate());
	Templates.AddItem(Rosarius());
	Templates.AddItem(LitanyOfTheDevout());
	Templates.AddItem(PurgeTheUnclean());

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

// --- Master of Sanctity relic -----------------------------------------------------------------

/// Litany of the Devout: for the rest of the turn, every brother within reach cannot be stunned, disoriented,
/// knocked out or mind-controlled, and his melee cannot miss. Free action, once per mission.
static function X2AbilityTemplate LitanyOfTheDevout()
{
	local X2AbilityTemplate Template;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Effect_DamageImmunity Faith;
	local XMBEffect_ChangeHitResultForAttacker SureStrike;

	Template = SelfTargetActivated('Astartes_LitanyOfTheDevout', "img:///UILibrary_PerkIcons.UIPerk_solace", false, none, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	AddCharges(Template, 1);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.LITANY_OF_THE_DEVOUT_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = false;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.AddItem(default.LivingFriendlyTargetProperty);

	Faith = new class'X2Effect_DamageImmunity';
	Faith.EffectName = 'Astartes_LitanyOfTheDevout_Faith';
	Faith.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Faith.DuplicateResponse = eDupe_Refresh;
	Faith.ImmuneTypes.AddItem('Mental');
	Faith.ImmuneTypes.AddItem('Panic');
	Faith.ImmuneTypes.AddItem('stun');
	Faith.ImmuneTypes.AddItem('Unconscious');
	Faith.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	Template.AddMultiTargetEffect(Faith);

	SureStrike = new class'XMBEffect_ChangeHitResultForAttacker';
	SureStrike.EffectName = 'Astartes_LitanyOfTheDevout_SureStrike';
	SureStrike.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	SureStrike.DuplicateResponse = eDupe_Refresh;
	SureStrike.bRequireMiss = true;
	SureStrike.NewResult = eHit_Success;
	SureStrike.AbilityShooterConditions.AddItem(default.MeleeCondition);
	Template.AddMultiTargetEffect(SureStrike);

	Template.ActivationSpeech = 'Inspire';
	Template.bShowActivation = true;
	return Template;
}

// --- Reclusiarch ------------------------------------------------------------------------------

/// Purge the Unclean: the Reclusiarch drives the Warp's touch from a brother. Removes mind control, panic, stun,
/// disorientation and unconsciousness; Chaos corruption will join that list when it exists. Cooldown.
static function X2AbilityTemplate PurgeTheUnclean()
{
	local X2AbilityTemplate Template;
	local X2Effect_RemoveEffects Cleanse;

	Cleanse = new class'X2Effect_RemoveEffects';
	Cleanse.EffectNamesToRemove.AddItem(class'X2Effect_MindControl'.default.EffectName);
	Cleanse.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
	Cleanse.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	Cleanse.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Cleanse.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	Cleanse.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BurningName);

	Template = TargetedBuff('Astartes_PurgeTheUnclean', "img:///UILibrary_PerkIcons.UIPerk_revivalprotocol", false, Cleanse, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Single);
	AddCooldown(Template, default.PURGE_THE_UNCLEAN_COOLDOWN);
	Template.ActivationSpeech = 'Inspire';
	Template.bShowActivation = true;
	return Template;
}
