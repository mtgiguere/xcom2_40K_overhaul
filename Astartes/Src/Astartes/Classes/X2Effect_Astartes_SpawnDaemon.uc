//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Astartes_SpawnDaemon.uc
//  PURPOSE: "Dragged into the Warp": a hostile daemon bursts out on the Librarian's tile. Same
//           framework as the Faceless reveal (X2Effect_SpawnFaceless). The Librarian is marked
//           lost to the Warp so the Apothecary cannot recover his geneseed; the ability kills him
//           with a separate effect so the strategy layer records a normal KIA.
//---------------------------------------------------------------------------------------
class X2Effect_Astartes_SpawnDaemon extends X2Effect_SpawnUnit dependson(X2Ability_Astartes_Librarian);

var name LostToTheWarpValueName;

static function PerilsDaemonDef CurrentTier()
{
	local XComGameState_BattleData BattleData;
	local int ForceLevel;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ForceLevel = BattleData != none ? BattleData.GetForceLevel() : 1;
	return class'X2Ability_Astartes_Librarian'.static.DaemonForForceLevel(ForceLevel);
}

function name GetUnitToSpawnName(const out EffectAppliedData ApplyEffectParameters)
{
	local PerilsDaemonDef Tier;

	Tier = CurrentTier();
	return Tier.Template;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local PerilsDaemonDef Tier;

	// A possessed husk wears the Librarian's own body; a true daemon has its own.
	Tier = CurrentTier();
	bCopyTargetAppearance = Tier.bWearsTheLibrarian;
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return eTeam_Alien;
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Librarian, Daemon;
	local XComGameState_AIGroup OldGroup, NewGroup;
	local array<name> DamageTypes;

	Librarian = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	Librarian.SetUnitFloatValue(default.LostToTheWarpValueName, 1, eCleanup_Never);
	// The daemon takes him. Direct damage: no bleed-out, no shields, no armour, a normal KIA for the strategy layer.
	// (Playtest 2026-10-17: a separate X2Effect_ApplyWeaponDamage on the same ability left him standing.)
	DamageTypes.AddItem('Psi');
	Librarian.TakeEffectDamage(self, Librarian.GetMaxStat(eStat_HP) + 100, 0, 0, ApplyEffectParameters, NewGameState, false, false, true, DamageTypes);

	// The spawn manager files units created by an XCOM-owned source under XCOM's own group.
	// A daemon fights for nobody but itself: give it a fresh alien group.
	Daemon = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	OldGroup = Daemon.GetGroupMembership(NewGameState);
	if (OldGroup != none && OldGroup.TeamName != eTeam_Alien)
	{
		OldGroup = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', OldGroup.ObjectID));
		OldGroup.RemoveUnitFromGroup(Daemon.ObjectID, NewGameState);
		NewGroup = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
		NewGroup.TeamName = eTeam_Alien;
		NewGroup.AddUnitToGroup(Daemon.ObjectID, NewGameState);
	}
	`log("Astartes: daemon" @ Daemon.GetMyTemplateName() @ "spawned from" @ Librarian.GetFullName(),, 'Astartes');
}

/// Show the newly spawned daemon (same pattern as X2Effect_SpawnSpectralArmy).
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameStateHistory History;
	local array<XComGameState_Unit> SpawnedUnits;
	local VisualizationActionMetadata EmptyTrack, DaemonTrack;
	local int i;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	if (EffectApplyResult == 'AA_Success' && XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());
	}

	History = `XCOMHISTORY;
	FindNewlySpawnedUnit(VisualizeGameState, SpawnedUnits);
	for (i = 0; i < SpawnedUnits.Length; i++)
	{
		DaemonTrack = EmptyTrack;
		DaemonTrack.StateObject_OldState = SpawnedUnits[i];
		DaemonTrack.StateObject_NewState = SpawnedUnits[i];
		DaemonTrack.VisualizeActor = History.GetVisualizer(SpawnedUnits[i].ObjectID);
		class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(DaemonTrack, VisualizeGameState.GetContext());
	}
}

defaultproperties
{
	LostToTheWarpValueName="Astartes_LostToTheWarp"
	EffectName="Astartes_SpawnDaemon"
	bClearTileBlockedByTargetUnitFlag=true
	bKnockbackAffectsSpawnLocation=false
	DuplicateResponse=eDupe_Ignore
}
