//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Chaos.uc
//  PURPOSE: Abilities of the Chaos enemies (docs/design.md, Chaos Sorcerer). Open the Warp: the
//           Sorcerer tears a rift at a point; the game's own reinforcement system opens a psi gate
//           there and a daemon pod walks out at the start of the next enemy turn. The rift is bound
//           to the Sorcerer by Astartes_RiftListener: kill him first and it collapses.
//           Tuning in XComAstartes.ini under [Astartes.X2Ability_Astartes_Chaos].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Chaos extends XMBAbility config(Astartes);

struct RiftEncounter
{
	var int MinForceLevel;
	var name EncounterID;   // a ConfigurableEncounters entry (XComEncounters.ini)
};

var config int RIFT_RANGE_TILES, RIFT_RADIUS_TILES, RIFT_CHARGES, RIFT_COOLDOWN;
var config array<RiftEncounter> RiftEncounters;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(OpenTheWarp());
	return Templates;
}

/// Open the Warp: cursor-targeted. The radius exists for the AI (it aims the rift at a cluster of Marines);
/// the ability itself applies no effect. The gate and the daemons come from the reinforcement spawner
/// that Astartes_RiftListener registers once this activation is submitted.
static function X2AbilityTemplate OpenTheWarp()
{
	local X2AbilityTemplate Template;
	local X2AbilityTarget_Cursor Cursor;
	local X2AbilityMultiTarget_Radius Radius;
	local X2AbilityCost_ActionPoints Cost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Astartes_OpenTheWarp');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_voidrift";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.bShowActivation = true;
	Template.TargetingMethod = class'X2TargetingMethod_VoidRift';
	Template.AbilityToHitCalc = default.DeadEye;

	Cost = new class'X2AbilityCost_ActionPoints';
	Cost.iNumPoints = 1;
	Cost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(Cost);
	if (default.RIFT_CHARGES > 0)
	{
		AddCharges(Template, default.RIFT_CHARGES);
	}
	if (default.RIFT_COOLDOWN > 0)
	{
		AddCooldown(Template, default.RIFT_COOLDOWN);
	}

	Cursor = new class'X2AbilityTarget_Cursor';
	Cursor.bRestrictToSquadsightRange = true;
	Cursor.FixedAbilityRange = default.RIFT_RANGE_TILES * class'XComWorldData'.const.WORLD_StepSize / class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER;
	Template.AbilityTargetStyle = Cursor;

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.fTargetRadius = default.RIFT_RADIUS_TILES * 1.5;
	Radius.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "StandardGunFiring";
	Template.ActivationSpeech = 'PsiStorm';
	return Template;
}

/// The reinforcement encounter for this force level: the highest MinForceLevel at or below it.
static function name EncounterForForceLevel(int ForceLevel)
{
	local name Best;
	local int BestLevel, i;

	BestLevel = -1;
	for (i = 0; i < default.RiftEncounters.Length; i++)
	{
		if (default.RiftEncounters[i].MinForceLevel <= ForceLevel && default.RiftEncounters[i].MinForceLevel > BestLevel)
		{
			Best = default.RiftEncounters[i].EncounterID;
			BestLevel = default.RiftEncounters[i].MinForceLevel;
		}
	}
	return Best;
}
