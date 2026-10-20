//---------------------------------------------------------------------------------------
//  FILE:    Astartes_GarrisonRescue.uc
//  PURPOSE: The garrison takes up arms (user, 2026-10-19). On a retaliation the haven's rebels are unarmed
//           civilians. When one of our soldiers ends a move next to one, the civilian leaves play (LWOTC
//           counts a rebel removed from play as saved) and a Guard recruit with the same face and name joins
//           our team on that tile, in flak with a lasgun. The recruit is in the crew and flagged as spawned from
//           the Avenger, so the post-mission transfer moves them into the barracks.
//           Two game states per rescue: the civilian's removal (visualized with X2Action_RemoveUnit and a
//           flyover), then a UnitAdded rule for the recruit, the way LWOTC adds its rebel soldiers mid-mission.
//---------------------------------------------------------------------------------------
class Astartes_GarrisonRescue extends X2EventListener config(Astartes);

/// Mission types (sType) where the garrison can be rescued.
var config array<string> Missions;
/// Civilian templates that are rescued. Only 'Rebel': a hidden Faceless rebel uses another template.
var config array<name> RescueTemplates;
var config int RescueRadiusTiles;
/// The recruit: a normal soldier template and the loadout they pick up.
var config name JoinTemplate;
var config name JoinLoadout;

var localized string JoinsTheFightText;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListener());
	return Templates;
}

static function CHEventListenerTemplate CreateListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Astartes_GarrisonRescue_Listener');
	Template.RegisterInTactical = true;
	Template.AddCHEvent('UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted);
	return Template;
}

static function bool IsRescueMission()
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	return BattleData != none && default.Missions.Find(BattleData.MapData.ActiveMission.sType) != INDEX_NONE;
}

/// 'UnitMoveFinished': the mover is the event data (and source). Every waiting civilian in reach joins.
static function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit Mover, Civilian;
	local array<XComGameState_Unit> Rescued;
	local int i;

	Mover = XComGameState_Unit(EventData);
	if (Mover == none)
	{
		Mover = XComGameState_Unit(EventSource);
	}
	if (Mover == none || Mover.GetTeam() != eTeam_XCom || !Mover.IsAlive() || !IsRescueMission())
	{
		return ELR_NoInterrupt;
	}
	Mover = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Mover.ObjectID));
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Civilian)
	{
		if (Civilian.GetTeam() == eTeam_Neutral && Civilian.IsAlive() && !Civilian.bRemovedFromPlay
			&& default.RescueTemplates.Find(Civilian.GetMyTemplateName()) != INDEX_NONE
			&& Mover.TileDistanceBetween(Civilian) <= default.RescueRadiusTiles)
		{
			Rescued.AddItem(Civilian);
		}
	}
	for (i = 0; i < Rescued.Length; i++)
	{
		JoinTheFight(Rescued[i]);
	}
	return ELR_NoInterrupt;
}

static function JoinTheFight(XComGameState_Unit Civilian)
{
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer Change;
	local XComGameStateContext_TacticalGameRule AddContext;
	local XComGameState_Unit Gone, Recruit;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Player Player;
	local X2CharacterTemplate Template;
	local TAppearance Look;
	local TTile Tile;

	Template = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(default.JoinTemplate);
	Player = FindPlayer(eTeam_XCom);
	if (Template == none || Player == none)
	{
		return;
	}
	Tile = Civilian.TileLocation;

	// 1. The civilian leaves the map.
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Astartes: garrison trooper takes up arms");
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Change);
	Gone = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Civilian.ObjectID));
	Gone.RemoveStateFromPlay();
	Change.BuildVisualizationFn = RemoveCivilian_BuildVisualization;
	`TACTICALRULES.SubmitGameState(NewGameState);

	// 2. A Guard recruit with the same face and name joins on that tile.
	AddContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, AddContext);
	Recruit = Template.CreateInstanceFromTemplate(NewGameState);
	Look = Civilian.kAppearance;
	Look.nmPawn = EGender(Look.iGender) == eGender_Female ? 'XCom_Soldier_F' : 'XCom_Soldier_M';
	Recruit.SetTAppearance(Look);
	Recruit.SetCharacterName(Civilian.GetFirstName(), Civilian.GetLastName(), "");
	Recruit.SetCountry(Civilian.GetCountry());
	Recruit.RandomizeStats();
	Recruit.ApplyInventoryLoadout(NewGameState, default.JoinLoadout);
	Recruit.SetHQLocation(eSoldierLoc_Barracks);
	Recruit.bSpawnedFromAvenger = true;
	Recruit.SetVisibilityLocation(Tile);
	Recruit.SetControllingPlayer(Player.GetReference());
	AddToTeamGroup(NewGameState, Recruit, Player);

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.AddToCrew(NewGameState, Recruit);
	}

	`TACTICALRULES.InitializeUnitAbilities(NewGameState, Recruit);
	class'XGUnit'.static.CreateVisualizer(NewGameState, Recruit, Player, none);
	AddContext.UnitRef = Recruit.GetReference();
	`TACTICALRULES.SubmitGameState(NewGameState);
	Recruit.OnBeginTacticalPlay(NewGameState);
	`log("Astartes: garrison trooper" @ Recruit.GetFullName() @ "takes up arms and joins the squad",, 'Astartes');
}

static function RemoveCivilian_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Unit Unit;
	local VisualizationActionMetadata Metadata;
	local X2Action_PlaySoundAndFlyOver Flyover;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		Metadata.StateObject_OldState = `XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		Metadata.StateObject_NewState = Unit;
		Metadata.VisualizeActor = Unit.GetVisualizer();
		Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(Metadata, VisualizeGameState.GetContext()));
		Flyover.SetSoundAndFlyOverParameters(none, default.JoinsTheFightText, '', eColor_Good);
		class'X2Action_RemoveUnit'.static.AddToVisualizationTree(Metadata, VisualizeGameState.GetContext());
	}
}

static function XComGameState_Player FindPlayer(ETeam Team)
{
	local XComGameState_Player Player;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', Player)
	{
		if (Player.GetTeam() == Team)
		{
			return Player;
		}
	}
	return none;
}

/// Join the initiative group of a unit already on that team (as LWOTC's Helpers_LW.AddUnitToXComGroup does).
static function AddToTeamGroup(XComGameState NewGameState, XComGameState_Unit Unit, XComGameState_Player Player)
{
	local XComGameState_Unit Member;
	local XComGameState_AIGroup Group;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Member)
	{
		if (Member.ControllingPlayer.ObjectID == Player.ObjectID && Member.ObjectID != Unit.ObjectID)
		{
			Group = Member.GetGroupMembership();
			if (Group != none)
			{
				Group.AddUnitToGroup(Unit.ObjectID, NewGameState);
				return;
			}
		}
	}
}
