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
// Jump visualization (X2Action_Astartes_JumpPack): vanilla soldier animations by default.
var config name JUMP_ANIM_START, JUMP_ANIM_LOOP, JUMP_ANIM_STOP;
var config float JUMP_START_PLAYRATE, JUMP_STOP_PLAYRATE, JUMP_START_FRACTION, JUMP_LANDING_LEAD;
var config float JUMP_ARC_HEIGHT_TILES, JUMP_SECONDS_PER_TILE, JUMP_MIN_FLIGHT_SECONDS, JUMP_MAX_FLIGHT_SECONDS;
var config string JUMP_SOUND_CUE;    // optional extra SoundCue for the ignition (empty = none)
// Jump pack sound and flame: Wwise events and particle systems, by object path. Defaults are the Alien Hunters
// Icarus Suit assets (vanilla DLC content, no other mod needed). Empty = none; missing assets are skipped.
struct JumpThruster
{
	var string FX;        // ParticleSystem path
	var vector Offset;    // from the attach bone (or the pawn), in the pawn's frame
};
var config string JUMP_TAKEOFF_SOUND, JUMP_FLIGHT_SOUND, JUMP_LAND_SOUND;
var config string JUMP_TAKEOFF_FX, JUMP_LAND_FX;
var config array<JumpThruster> JUMP_THRUSTERS;
var config name JUMP_THRUSTER_BONE;  // bone the thrusters ride on; falls back to the pawn itself if absent
var config string JUMP_ANIMSET_PATH; // optional extra AnimSet granted to Assault Marines (e.g. a jump animation pack)
var config array<name> JumpAbilities; // abilities whose visualization becomes the arc

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
	Templates.AddItem(DeathIncarnate());
	Templates.AddItem(DeathIncarnateReset());
	Templates.AddItem(JumpPackRig());

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

	return Passive('Astartes_ChainTeeth', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", false, Effect);
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

	return Passive('Astartes_Duelist', "img:///UILibrary_PerkIcons.UIPerk_bulletshred", false, Effect);
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
	JumpNames.IncludeAbilityNames.AddItem('IcarusJump');
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
	Reset.AbilityNames.AddItem('IcarusJump');
	Reset.AbilityNames.AddItem('Astartes_DeepJump');

	Template = SelfTargetTrigger('Astartes_HitAndRun', "img:///UILibrary_PerkIcons.UIPerk_implacable", false, Reset, 'KillMail');
	AddTriggerTargetCondition(Template, default.MeleeCondition); // ability-property conditions belong in the trigger's target conditions
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
	Reset.AbilityNames.AddItem('IcarusJump');
	Reset.AbilityNames.AddItem('Astartes_DeepJump');

	Mobility = new class'X2Effect_PersistentStatChange';
	Mobility.EffectName = 'Astartes_AngelOfDeath_Mobility';
	Mobility.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Mobility.DuplicateResponse = eDupe_Refresh;
	Mobility.AddPersistentStatChange(eStat_Mobility, default.ANGEL_OF_DEATH_MOBILITY);

	Template = SelfTargetActivated('Astartes_AngelOfDeath', "img:///UILibrary_DLC2Images.UIPerk_icarusjump", false, Actions, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
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

// --- Chapter Master capstone ------------------------------------------------------------------

/// Death Incarnate: for the rest of the turn every melee kill refunds the action and readies the jump pack,
/// with no cap. The Assault-born Chapter Master's relic ability. Free action, once per mission.
static function X2AbilityTemplate DeathIncarnate()
{
	local X2AbilityTemplate Template;
	local XMBEffect_AbilityCostRefund Refund;

	Refund = new class'XMBEffect_AbilityCostRefund';
	Refund.EffectName = 'Astartes_DeathIncarnate_Effect';
	Refund.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Refund.DuplicateResponse = eDupe_Refresh;
	Refund.TriggeredEvent = 'Astartes_DeathIncarnate';
	Refund.bShowFlyOver = true;
	Refund.AbilityShooterConditions.AddItem(default.MatchingWeaponCondition);
	Refund.AbilityShooterConditions.AddItem(default.MeleeCondition);
	Refund.AbilityTargetConditions.AddItem(default.DeadCondition);

	Template = SelfTargetActivated('Astartes_DeathIncarnate', "img:///UILibrary_PerkIcons.UIPerk_reaper", false, Refund, class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY, eCost_Free);
	AddCharges(Template, 1);
	Template.AdditionalAbilities.AddItem('Astartes_DeathIncarnate_Reset');
	Template.bShowActivation = true;
	return Template;
}

/// Hidden: while Death Incarnate is active, every melee kill clears the jump pack cooldown.
static function X2AbilityTemplate DeathIncarnateReset()
{
	local X2AbilityTemplate Template;
	local X2Effect_Astartes_ResetCooldown Reset;
	local X2Condition_UnitEffects Active;

	Reset = new class'X2Effect_Astartes_ResetCooldown';
	Reset.AbilityNames.AddItem('IcarusJump');
	Reset.AbilityNames.AddItem('Astartes_DeepJump');

	Template = SelfTargetTrigger('Astartes_DeathIncarnate_Reset', "img:///UILibrary_PerkIcons.UIPerk_implacable", false, Reset, 'KillMail');
	AddTriggerTargetCondition(Template, default.MeleeCondition);
	Active = new class'X2Condition_UnitEffects';
	Active.AddRequireEffect('Astartes_DeathIncarnate_Effect', 'AA_MissingRequiredEffect');
	Template.AbilityShooterConditions.AddItem(Active);
	return Template;
}

// --- Jump visualization ----------------------------------------------------------------------

/// Hidden passive carried by every Assault Marine: grants the optional extra animation set for the jump.
static function X2AbilityTemplate JumpPackRig()
{
	local X2AbilityTemplate Template;
	local X2Effect_AdditionalAnimSets AnimSets;

	Template = Passive('Astartes_JumpPackRig', "img:///UILibrary_PerkIcons.UIPerk_runandgun", false);
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	if (default.JUMP_ANIMSET_PATH != "" && AnimSet(DynamicLoadObject(default.JUMP_ANIMSET_PATH, class'AnimSet', true)) != none)
	{
		AnimSets = new class'X2Effect_AdditionalAnimSets';
		AnimSets.EffectName = 'Astartes_JumpPackRig_AnimSets';
		AnimSets.AddAnimSetWithPath("AnimSet'" $ default.JUMP_ANIMSET_PATH $ "'");
		AnimSets.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
		AnimSets.DuplicateResponse = eDupe_Ignore;
		Template.AddTargetEffect(AnimSets);
	}
	else if (default.JUMP_ANIMSET_PATH != "")
	{
		`log("Astartes: jump animation set" @ default.JUMP_ANIMSET_PATH @ "is not loaded (enable the mod that ships it); jumps fly without animations",, 'Astartes');
	}
	return Template;
}

/// After templates exist: the jump abilities visualize as an arc instead of the Icarus teleport.
static function RewireJumpVisuals()
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Template;
	local int i, Rewired;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = 0; i < default.JumpAbilities.Length; i++)
	{
		Template = AbilityMgr.FindAbilityTemplate(default.JumpAbilities[i]);
		if (Template == none)
		{
			continue;
		}
		Template.BuildVisualizationFn = JumpPack_BuildVisualization;
		if (Template.AdditionalAbilities.Find('Astartes_JumpPackRig') == INDEX_NONE)
		{
			Template.AdditionalAbilities.AddItem('Astartes_JumpPackRig');
		}
		Rewired++;
	}
	`log("Astartes: jump visualizations rewired:" @ Rewired @ "of" @ default.JumpAbilities.Length,, 'Astartes');
}

/// Icarus Jump's visualization with the path parse replaced by the jump-pack arc action.
simulated function JumpPack_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference UnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_Astartes_JumpPack JumpAction;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_EnvironmentDamage DamageEventStateObject;
	local X2VisualizerInterface TargetVisualizerInterface;
	local int i, j;

	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	UnitRef = Context.InputContext.SourceObject;
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(UnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(none, AbilityTemplate.LocFlyOverText, '', eColor_Good);

	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, Context));
	MoveTurnAction.m_vFacePoint = Context.InputContext.TargetLocations[0];

	// No ExitCover/EnterCover here: EnterCover ends by moving the pawn to Unit.RestoreLocation, which ExitCover only
	// fills when the unit stood in cover. From the open it is zero, and the pawn was teleported to the world origin
	// after every jump (playtest 2026-10-18). The vanilla Icarus visualization does not use them either.
	JumpAction = X2Action_Astartes_JumpPack(class'X2Action_Astartes_JumpPack'.static.AddToVisualizationTree(ActionMetadata, Context));
	JumpAction.DesiredLocation = Context.InputContext.TargetLocations[0];

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.VisualizeActor = none;
		ActionMetadata.StateObject_NewState = WorldDataUpdate;
		ActionMetadata.StateObject_OldState = WorldDataUpdate;
		for (i = 0; i < AbilityTemplate.AbilityTargetEffects.Length; ++i)
		{
			AbilityTemplate.AbilityTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[i]));
		}
	}

	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		UnitRef = Context.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitRef.ObjectID);
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context);
		for (j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j)
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}
		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if (TargetVisualizerInterface != none)
		{
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEventStateObject)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = DamageEventStateObject;
		ActionMetadata.StateObject_NewState = DamageEventStateObject;
		ActionMetadata.VisualizeActor = History.GetVisualizer(DamageEventStateObject.ObjectID);
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, Context);
	}
}
