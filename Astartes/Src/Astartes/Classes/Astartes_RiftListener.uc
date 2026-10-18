//---------------------------------------------------------------------------------------
//  FILE:    Astartes_RiftListener.uc
//  PURPOSE: Binds Open the Warp (X2Ability_Astartes_Chaos) to the game's reinforcement system.
//           When the activation is submitted, a reinforcement spawner is registered at the targeted
//           point with the 'PsiGate' visual and a one-turn countdown: the gate opens at once and the
//           daemon pod walks out at the start of the next enemy turn. The spawner's id is written on the
//           Sorcerer; if he dies before the countdown ends the spawner is removed and the gate closes.
//           The spawner is NOT created inside the ability's own game state: the spawner's creation code
//           casts the state's context to a ChangeContainer without a guard.
//           Also the webway: a Lost swarm spawner (an incursion, Astartes_FactionConfig) has its arrival switched
//           from the Lost run-in to the psi gate the moment it is created, before the spawner's own listener runs.
//---------------------------------------------------------------------------------------
class Astartes_RiftListener extends X2EventListener;

var localized string RiftCollapsesText;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateRiftListener());
	return Templates;
}

static function CHEventListenerTemplate CreateRiftListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Astartes_Rift_Listener');
	Template.RegisterInTactical = true;
	Template.AddCHEvent('AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted);
	Template.AddCHEvent('UnitDied', OnUnitDied, ELD_OnStateSubmitted);
	Template.AddCHEvent('ReinforcementSpawnerCreated', OnReinforcementSpawnerCreated, ELD_Immediate);
	return Template;
}

/// 'AbilityActivated': EventData is the ability state, EventSource the acting unit.
static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability Ability;
	local XComGameState_Unit Unit;
	local XComGameStateContext_Ability Context;

	Ability = XComGameState_Ability(EventData);
	Unit = XComGameState_Unit(EventSource);
	if (Ability == none || Unit == none || GameState == none || Ability.GetMyTemplateName() != 'Astartes_OpenTheWarp')
	{
		return ELR_NoInterrupt;
	}
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt || Context.InputContext.TargetLocations.Length == 0)
	{
		return ELR_NoInterrupt;
	}
	OpenRift(Unit, Context.InputContext.TargetLocations[0]);
	return ELR_NoInterrupt;
}

static function OpenRift(XComGameState_Unit Sorcerer, vector Location)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_AIReinforcementSpawner Spawner, Newest;
	local XComGameState NewGameState;
	local XComGameState_Unit NewSorcerer;
	local name EncounterID;
	local int ForceLevel;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ForceLevel = BattleData != none ? BattleData.GetForceLevel() : 1;
	EncounterID = class'X2Ability_Astartes_Chaos'.static.EncounterForForceLevel(ForceLevel);
	if (EncounterID == '')
	{
		`log("Astartes: Open the Warp has no RiftEncounters entry for force level" @ ForceLevel,, 'Astartes');
		return;
	}

	// Countdown 1: the gate shows now, the pod arrives at the start of the next alien turn. 'PsiGate' is the
	// game's own portal visual. No incoming game state (see the file header). Hazards avoided, scamper on arrival.
	if (!class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(EncounterID, 1, true, Location, 0, none, false, 'PsiGate', false, false, true, true))
	{
		`log("Astartes: Open the Warp: reinforcements refused (unit cap?) for" @ EncounterID,, 'Astartes');
		return;
	}

	foreach History.IterateByClassType(class'XComGameState_AIReinforcementSpawner', Spawner)
	{
		if (Spawner.SpawnInfo.EncounterID == EncounterID && Spawner.Countdown > 0 && Spawner.SpawnedUnitIDs.Length == 0
			&& (Newest == none || Spawner.ObjectID > Newest.ObjectID))
		{
			Newest = Spawner;
		}
	}
	if (Newest == none)
	{
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: rift bound to its Sorcerer");
	NewSorcerer = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Sorcerer.ObjectID));
	NewSorcerer.SetUnitFloatValue('Astartes_OpenRift', Newest.ObjectID, eCleanup_BeginTactical);
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("Astartes:" @ Sorcerer.GetMyTemplateName() @ "opened the Warp:" @ EncounterID @ "at" @ Newest.SpawnInfo.SpawnLocation @ "(spawner" @ Newest.ObjectID $ ")",, 'Astartes');
}

/// 'ReinforcementSpawnerCreated' (immediate, inside InitiateReinforcements' own game state): a Lost swarm that the
/// incursion rules will turn into Eldar arrives through the webway, i.e. the game's psi gate, not the Lost run-in.
/// The spawner's own creation listener runs on submission and reads this value from the submitted state.
static function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_AIReinforcementSpawner Spawner;

	Spawner = XComGameState_AIReinforcementSpawner(EventData);
	if (Spawner == none || GameState == none || !class'Astartes_FactionConfig'.default.bEnableIncursions
		|| class'Astartes_FactionConfig'.default.IncursionArrival == '' || Spawner.SpawnVisualizationType != 'TheLostSwarm'
		|| !class'Astartes_FactionConfig'.static.IsIncursionEncounter(Spawner.SpawnInfo.EncounterID))
	{
		return ELR_NoInterrupt;
	}
	Spawner = XComGameState_AIReinforcementSpawner(GameState.GetGameStateForObjectID(Spawner.ObjectID));
	if (Spawner == none)
	{
		return ELR_NoInterrupt;
	}
	Spawner.SpawnVisualizationType = class'Astartes_FactionConfig'.default.IncursionArrival;
	`log("Astartes: incursion" @ Spawner.SpawnInfo.EncounterID @ "arrives by" @ Spawner.SpawnVisualizationType @ "(webway)",, 'Astartes');
	return ELR_NoInterrupt;
}

/// 'UnitDied': EventData is the dead unit. A Sorcerer who dies with a rift still forming takes it with him.
static function EventListenerReturn OnUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit Unit;
	local XComGameState_AIReinforcementSpawner Spawner;
	local XComGameState NewGameState;
	local UnitValue Value;

	Unit = XComGameState_Unit(EventData);
	if (Unit == none || !Unit.GetUnitValue('Astartes_OpenRift', Value) || Value.fValue <= 0)
	{
		return ELR_NoInterrupt;
	}
	Spawner = XComGameState_AIReinforcementSpawner(`XCOMHISTORY.GetGameStateForObjectID(int(Value.fValue)));
	if (Spawner == none || Spawner.bRemoved || Spawner.Countdown <= 0 || Spawner.SpawnedUnitIDs.Length > 0)
	{
		return ELR_NoInterrupt; // the gate already opened: the daemons are loose
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: the rift collapses");
	NewGameState.RemoveStateObject(Spawner.ObjectID);
	`XEVENTMGR.UnRegisterFromAllEvents(Spawner);
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = RiftCollapse_BuildVisualization;
	`TACTICALRULES.SubmitGameState(NewGameState);
	`log("Astartes: the rift collapses with" @ Unit.GetMyTemplateName() @ "(spawner" @ Spawner.ObjectID $ ")",, 'Astartes');
	return ELR_NoInterrupt;
}

/// Close the gate effect where the spawner had it, and say so over the dead Sorcerer.
static function RiftCollapse_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameState_AIReinforcementSpawner Spawner;
	local XComGameState_Unit Unit;
	local VisualizationActionMetadata EmptyTrack, ActionMetadata;
	local X2Action_PlayEffect Effect;
	local X2Action_PlaySoundAndFlyOver Flyover;
	local UnitValue Value;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', Spawner)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = Spawner;
		ActionMetadata.StateObject_NewState = Spawner;
		Effect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
		Effect.EffectName = `CONTENT.PsiGateEffectPathName;
		Effect.EffectLocation = Spawner.SpawnInfo.SpawnLocation;
		Effect.bStopEffect = true;
	}
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (Unit.GetUnitValue('Astartes_OpenRift', Value) && Unit.IsDead())
		{
			break;
		}
	}
	if (Unit != none)
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = Unit;
		ActionMetadata.StateObject_NewState = Unit;
		ActionMetadata.VisualizeActor = History.GetVisualizer(Unit.ObjectID);
		Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
		Flyover.SetSoundAndFlyOverParameters(none, default.RiftCollapsesText, '', eColor_Good);
	}
}
