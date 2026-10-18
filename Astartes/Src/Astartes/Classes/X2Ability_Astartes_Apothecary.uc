//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Apothecary.uc
//  PURPOSE: Apothecary abilities (docs/classes.md), built on XModBase helpers. The narthecium is
//           a gremlin-slot item, so the vanilla protocol abilities work on it unchanged.
//           Tuning values live in XComAstartes.ini under [Astartes.X2Ability_Astartes_Apothecary].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Apothecary extends XMBAbility config(Astartes);

var config int STIMM_SHOT_COOLDOWN, STIMM_SHOT_RANGE_TILES;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(StimmShot());
	Templates.AddItem(WarriorMedic());

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
