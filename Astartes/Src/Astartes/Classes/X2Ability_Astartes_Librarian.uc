//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Astartes_Librarian.uc
//  PURPOSE: Perils of the Warp (docs/classes.md, Librarian). Every psychic power the Librarian
//           casts rolls for Perils once it has resolved. The chance grows with the power's Warp
//           Charge and shrinks with the Psychic Hood's mark. A failed roll picks one outcome from
//           a weighted table, modelled on the tabletop one:
//             Warp Surge      - the power succeeds AND the Librarian regains an action (the silver lining)
//             Psychic Backlash- damage that ignores armour
//             Warp Shock      - stunned
//             Mental Purge    - every psychic power goes on cooldown
//             Dragged into the Warp - a daemon bursts from the Librarian; he is lost, geneseed and all
//           Tuning lives in XComAstartes.ini under [Astartes.X2Ability_Astartes_Librarian].
//---------------------------------------------------------------------------------------
class X2Ability_Astartes_Librarian extends XMBAbility config(Astartes);

struct PsychicPowerDef
{
	var name Ability;      // ability template name (our clone or a vanilla psi ability in the tree)
	var int WarpCharge;    // 1 minor, 2 major, 3 cataclysmic
};

var config array<PsychicPowerDef> PsychicPowers;
var config int PERILS_BASE_CHANCE, PERILS_CHANCE_PER_WARP_CHARGE;
var config int PERILS_HOOD_REDUCTION_MG, PERILS_HOOD_REDUCTION_BM;
var config int PERILS_WEIGHT_WARP_SURGE, PERILS_WEIGHT_BACKLASH, PERILS_WEIGHT_WARP_SHOCK, PERILS_WEIGHT_MENTAL_PURGE, PERILS_WEIGHT_POSSESSION;
var config int PERILS_BACKLASH_DAMAGE, PERILS_BACKLASH_SPREAD, PERILS_SHOCK_STUN_ACTIONS, PERILS_PURGE_COOLDOWN;
var config name PERILS_DAEMON_TEMPLATE;
var config bool bLogPerils;

// Dev only (Astartes_ForcePerils): the next psychic power suffers Perils with this outcome. '' = roll normally.
var config name ForcedPerilsOutcome; // config so the dev command may write the class default at runtime

var name WarpSurgeName, BacklashName, WarpShockName, MentalPurgeName, PossessionName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(PerilsOfTheWarp());
	Templates.AddItem(WarpSurge());
	Templates.AddItem(Backlash());
	Templates.AddItem(WarpShock());
	Templates.AddItem(MentalPurge());
	Templates.AddItem(Possession());

	return Templates;
}

// --- the watcher -----------------------------------------------------------------------------

/// Perils of the Warp: squaddie-kit passive on the Librarian. Shows the icon, carries the outcome
/// abilities, and listens for the Librarian's own psychic powers resolving.
static function X2AbilityTemplate PerilsOfTheWarp()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;

	Template = Passive('Astartes_PerilsOfTheWarp', "img:///UILibrary_PerkIcons.UIPerk_voidrift", false);

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = PerilsListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AdditionalAbilities.AddItem(default.WarpSurgeName);
	Template.AdditionalAbilities.AddItem(default.BacklashName);
	Template.AdditionalAbilities.AddItem(default.WarpShockName);
	Template.AdditionalAbilities.AddItem(default.MentalPurgeName);
	Template.AdditionalAbilities.AddItem(default.PossessionName);

	return Template;
}

/// Fires after any ability resolves on the Librarian. Rolls for Perils if it was a psychic power
/// and, on failure, triggers one outcome ability on the Librarian himself.
static function EventListenerReturn PerilsListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability ActivatedAbility, PerilsAbility, OutcomeAbility;
	local XComGameStateContext_Ability Context;
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local int WarpCharge, Chance, Roll;
	local name Outcome;
	local StateObjectReference OutcomeRef;

	ActivatedAbility = XComGameState_Ability(EventData);
	PerilsAbility = XComGameState_Ability(CallbackData);
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (ActivatedAbility == none || PerilsAbility == none || Context == none)
	{
		return ELR_NoInterrupt;
	}
	if (Context.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt; // wait for the resolved half of the activation
	}
	if (ActivatedAbility.OwnerStateObject.ObjectID != PerilsAbility.OwnerStateObject.ObjectID)
	{
		return ELR_NoInterrupt;
	}

	WarpCharge = GetWarpCharge(ActivatedAbility.GetMyTemplateName());
	if (WarpCharge <= 0)
	{
		return ELR_NoInterrupt; // not a psychic power
	}

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(PerilsAbility.OwnerStateObject.ObjectID));
	if (Unit == none || Unit.IsDead() || Unit.bRemovedFromPlay)
	{
		return ELR_NoInterrupt;
	}

	if (default.ForcedPerilsOutcome != '')
	{
		Outcome = default.ForcedPerilsOutcome;
		default.ForcedPerilsOutcome = '';
		`log("Astartes: Perils FORCED" @ Outcome @ "after" @ ActivatedAbility.GetMyTemplateName(),, 'Astartes');
	}
	else
	{
		Chance = PerilsChance(Unit, WarpCharge);
		Roll = `SYNC_RAND_STATIC(100);
		if (default.bLogPerils)
		{
			`log("Astartes: Perils roll" @ Roll @ "vs" @ Chance $ "% after" @ ActivatedAbility.GetMyTemplateName() @ "(warp charge" @ WarpCharge $ ")",, 'Astartes');
		}
		if (Roll >= Chance)
		{
			return ELR_NoInterrupt;
		}
		Outcome = RollOutcome();
		`log("Astartes: PERILS OF THE WARP ->" @ Outcome,, 'Astartes');
	}

	OutcomeRef = Unit.FindAbility(Outcome);
	OutcomeAbility = XComGameState_Ability(History.GetGameStateForObjectID(OutcomeRef.ObjectID));
	if (OutcomeAbility == none)
	{
		`log("Astartes: Perils outcome ability" @ Outcome @ "not found on unit",, 'Astartes');
		return ELR_NoInterrupt;
	}
	OutcomeAbility.AbilityTriggerAgainstSingleTarget(Unit.GetReference(), false);

	return ELR_NoInterrupt;
}

static function int GetWarpCharge(name AbilityName)
{
	local int i;

	for (i = 0; i < default.PsychicPowers.Length; i++)
	{
		if (default.PsychicPowers[i].Ability == AbilityName)
		{
			return default.PsychicPowers[i].WarpCharge;
		}
	}
	return 0;
}

/// Percent chance of Perils for this cast: base + per-charge growth, less the Psychic Hood's protection.
static function int PerilsChance(XComGameState_Unit Unit, int WarpCharge)
{
	local XComGameState_Item Hood;
	local X2WeaponTemplate HoodTemplate;
	local int Chance;

	Chance = default.PERILS_BASE_CHANCE + (WarpCharge - 1) * default.PERILS_CHANCE_PER_WARP_CHARGE;

	Hood = Unit.GetSecondaryWeapon();
	if (Hood != none)
	{
		HoodTemplate = X2WeaponTemplate(Hood.GetMyTemplate());
		if (HoodTemplate != none)
		{
			if (HoodTemplate.WeaponTech == 'magnetic')
			{
				Chance -= default.PERILS_HOOD_REDUCTION_MG;
			}
			else if (HoodTemplate.WeaponTech == 'beam')
			{
				Chance -= default.PERILS_HOOD_REDUCTION_BM;
			}
		}
	}
	return Max(Chance, 0);
}

/// Weighted pick from the outcome table.
static function name RollOutcome()
{
	local int Total, Roll;

	Total = default.PERILS_WEIGHT_WARP_SURGE + default.PERILS_WEIGHT_BACKLASH + default.PERILS_WEIGHT_WARP_SHOCK
		+ default.PERILS_WEIGHT_MENTAL_PURGE + default.PERILS_WEIGHT_POSSESSION;
	Roll = `SYNC_RAND_STATIC(Max(Total, 1));

	Roll -= default.PERILS_WEIGHT_WARP_SURGE;
	if (Roll < 0) return default.WarpSurgeName;
	Roll -= default.PERILS_WEIGHT_BACKLASH;
	if (Roll < 0) return default.BacklashName;
	Roll -= default.PERILS_WEIGHT_WARP_SHOCK;
	if (Roll < 0) return default.WarpShockName;
	Roll -= default.PERILS_WEIGHT_MENTAL_PURGE;
	if (Roll < 0) return default.MentalPurgeName;
	return default.PossessionName;
}

// --- the outcomes (hidden self-targeted abilities triggered by the listener) ------------------

static function X2AbilityTemplate HiddenSelfAbility(name DataName, string IconImage)
{
	local X2AbilityTemplate Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, DataName);
	Template.IconImage = IconImage;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.bShowActivation = true;      // flyover with the outcome's name
	Template.bSkipFireAction = true;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	return Template;
}

/// Warp Surge: the Warp answers generously. The Librarian regains an action.
static function X2AbilityTemplate WarpSurge()
{
	local X2AbilityTemplate Template;
	local X2Effect_GrantActionPoints Effect;

	Template = HiddenSelfAbility('Astartes_Perils_WarpSurge', "img:///UILibrary_PerkIcons.UIPerk_inspire");
	Effect = new class'X2Effect_GrantActionPoints';
	Effect.NumActionPoints = 1;
	Effect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddTargetEffect(Effect);
	return Template;
}

/// Psychic Backlash: warp energy earths itself through the Librarian. Damage ignores armour.
static function X2AbilityTemplate Backlash()
{
	local X2AbilityTemplate Template;
	local X2Effect_ApplyWeaponDamage Damage;

	Template = HiddenSelfAbility('Astartes_Perils_Backlash', "img:///UILibrary_PerkIcons.UIPerk_soulfire");
	Damage = new class'X2Effect_ApplyWeaponDamage';
	Damage.EffectDamageValue.Damage = default.PERILS_BACKLASH_DAMAGE;
	Damage.EffectDamageValue.Spread = default.PERILS_BACKLASH_SPREAD;
	Damage.EffectDamageValue.DamageType = 'Psi';
	Damage.bIgnoreBaseDamage = true;
	Damage.bIgnoreArmor = true;
	Damage.bBypassShields = true;
	Damage.DamageTypes.AddItem('Psi');
	Template.AddTargetEffect(Damage);
	return Template;
}

/// Warp Shock: the Librarian's mind reels. Stunned.
static function X2AbilityTemplate WarpShock()
{
	local X2AbilityTemplate Template;

	Template = HiddenSelfAbility('Astartes_Perils_WarpShock', "img:///UILibrary_PerkIcons.UIPerk_stun");
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(default.PERILS_SHOCK_STUN_ACTIONS, 100, true));
	return Template;
}

/// Mental Purge: the Librarian's powers slip from his grasp. Every psychic power goes on cooldown.
static function X2AbilityTemplate MentalPurge()
{
	local X2AbilityTemplate Template;
	local X2Effect_Astartes_MentalPurge Effect;
	local int i;

	Template = HiddenSelfAbility('Astartes_Perils_MentalPurge', "img:///UILibrary_PerkIcons.UIPerk_schism");
	Effect = new class'X2Effect_Astartes_MentalPurge';
	Effect.CooldownTurns = default.PERILS_PURGE_COOLDOWN;
	for (i = 0; i < default.PsychicPowers.Length; i++)
	{
		Effect.Powers.AddItem(default.PsychicPowers[i].Ability);
	}
	Template.AddTargetEffect(Effect);
	return Template;
}

/// Dragged into the Warp: a daemon takes the Librarian. It bursts from his body onto the field,
/// hostile; the Librarian is killed in action and his geneseed is lost with him.
static function X2AbilityTemplate Possession()
{
	local X2AbilityTemplate Template;
	local X2Effect_Astartes_SpawnDaemon Daemon;
	local X2Effect_ApplyWeaponDamage Death;

	Template = HiddenSelfAbility('Astartes_Perils_Possession', "img:///UILibrary_PerkIcons.UIPerk_voidrift");

	Daemon = new class'X2Effect_Astartes_SpawnDaemon';
	Daemon.UnitToSpawnName = default.PERILS_DAEMON_TEMPLATE;
	Daemon.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Template.AddTargetEffect(Daemon);

	Death = new class'X2Effect_ApplyWeaponDamage';
	Death.EffectDamageValue.Damage = 999;
	Death.EffectDamageValue.DamageType = 'Psi';
	Death.bIgnoreBaseDamage = true;
	Death.bIgnoreArmor = true;
	Death.bBypassShields = true;
	Death.bBypassSustainEffects = true;
	Death.DamageTypes.AddItem('Psi');
	Template.AddTargetEffect(Death);

	Template.CinescriptCameraType = "Psionic_FireAtUnit";
	return Template;
}

defaultproperties
{
	WarpSurgeName="Astartes_Perils_WarpSurge"
	BacklashName="Astartes_Perils_Backlash"
	WarpShockName="Astartes_Perils_WarpShock"
	MentalPurgeName="Astartes_Perils_MentalPurge"
	PossessionName="Astartes_Perils_Possession"
}
