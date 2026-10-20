//---------------------------------------------------------------------------------------
//  FILE:    Astartes_GarrisonRescue.uc
//  PURPOSE: The garrison takes up arms (user, 2026-10-19/20). LWOTC's retaliation rescue is left exactly as it is:
//           a haven rebel our soldier reaches is swapped to our team (LWOTC's SeqAct_ControlCivilian) and counts as
//           rescued. We only arm them: when a rescued rebel joins our team ('UnitChangedTeam') they get the Guard's
//           lasgun in the primary slot, its abilities (shot, overwatch, reload...) and the gun on their pawn.
//           Rebels wear the Guard's armour on a soldier pawn (our RebelTemplates dressing), so they can hold it.
//---------------------------------------------------------------------------------------
class Astartes_GarrisonRescue extends X2EventListener config(Astartes);

/// Mission types (sType) where rescued rebels are armed.
var config array<string> Missions;
/// Civilian templates that are armed. Only 'Rebel': a Faceless rebel proxy uses another template.
var config array<name> RescueTemplates;
/// The weapon they take up: XCOM's rifle, which this mod reskins as the lasgun.
var config name GarrisonWeapon;

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
	Template.AddCHEvent('UnitChangedTeam', OnUnitChangedTeam, ELD_OnStateSubmitted);
	return Template;
}

static function bool IsRescueMission()
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	return BattleData != none && default.Missions.Find(BattleData.MapData.ActiveMission.sType) != INDEX_NONE;
}

/// 'UnitChangedTeam': the unit is the event data and source.
static function EventListenerReturn OnUnitChangedTeam(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(EventData);
	if (Unit == none)
	{
		Unit = XComGameState_Unit(EventSource);
	}
	if (Unit == none || !IsRescueMission())
	{
		return ELR_NoInterrupt;
	}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));
	if (Unit == none || Unit.GetTeam() != eTeam_XCom || !Unit.IsAlive()
		|| default.RescueTemplates.Find(Unit.GetMyTemplateName()) == INDEX_NONE
		|| Unit.GetItemInSlot(eInvSlot_PrimaryWeapon) != none)
	{
		return ELR_NoInterrupt;
	}
	TakeUpArms(Unit);
	return ELR_NoInterrupt;
}

static function TakeUpArms(XComGameState_Unit Rebel)
{
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer Change;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;
	local XGUnit Visualizer;
	local int i;

	WeaponTemplate = X2WeaponTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(default.GarrisonWeapon));
	if (WeaponTemplate == none)
	{
		`log("Astartes: garrison weapon" @ default.GarrisonWeapon @ "not found; rebel left unarmed",, 'Astartes');
		return;
	}
	Change = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Astartes: garrison trooper takes up arms");
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Change);
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Rebel.ObjectID));
	Weapon = WeaponTemplate.CreateInstanceFromTemplate(NewGameState);
	if (!Unit.AddItemToInventory(Weapon, eInvSlot_PrimaryWeapon, NewGameState))
	{
		`log("Astartes: could not hand" @ Unit.GetFullName() @ "a" @ default.GarrisonWeapon,, 'Astartes');
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		return;
	}
	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = 0; i < WeaponTemplate.Abilities.Length; i++)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(WeaponTemplate.Abilities[i]);
		if (AbilityTemplate != none && Unit.FindAbility(AbilityTemplate.DataName, Weapon.GetReference()).ObjectID == 0)
		{
			class'X2TacticalGameRuleset'.static.InitAbilityForUnit(AbilityTemplate, Unit, NewGameState, Weapon.GetReference());
		}
	}
	Change.BuildVisualizationFn = TakeUpArms_BuildVisualization;
	`TACTICALRULES.SubmitGameState(NewGameState);

	Visualizer = XGUnit(Unit.GetVisualizer());
	if (Visualizer != none)
	{
		Visualizer.ApplyLoadoutFromGameState(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)), NewGameState);
	}
	`log("Astartes: garrison trooper" @ Unit.GetFullName() @ "takes up a" @ default.GarrisonWeapon,, 'Astartes');
}

static function TakeUpArms_BuildVisualization(XComGameState VisualizeGameState)
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
	}
}
