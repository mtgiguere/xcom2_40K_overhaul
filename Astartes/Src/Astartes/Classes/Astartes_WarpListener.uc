//---------------------------------------------------------------------------------------
//  FILE:    Astartes_WarpListener.uc
//  PURPOSE: Tactical event listener for Perils of the Warp. Every resolved ability activation
//           is checked: if the acting unit carries Astartes_PerilsOfTheWarp and the ability is a
//           psychic power, X2Ability_Astartes_Librarian rolls for Perils. Built on the Highlander
//           event-listener template (same pattern as Astartes_ClassLook), which is the one
//           listener mechanism proven in this mod.
//---------------------------------------------------------------------------------------
class Astartes_WarpListener extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreatePerilsListener());
	return Templates;
}

static function CHEventListenerTemplate CreatePerilsListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Astartes_PerilsOfTheWarp_Listener');
	Template.RegisterInTactical = true;
	Template.AddCHEvent('AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted);
	return Template;
}

/// 'AbilityActivated': EventData is the ability state, EventSource the acting unit.
static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability ActivatedAbility;
	local XComGameState_Unit Unit;
	local XComGameStateContext_Ability Context;
	local StateObjectReference PerilsRef;

	ActivatedAbility = XComGameState_Ability(EventData);
	Unit = XComGameState_Unit(EventSource);
	if (ActivatedAbility == none || Unit == none || GameState == none)
	{
		return ELR_NoInterrupt;
	}
	Context = XComGameStateContext_Ability(GameState.GetContext());
	if (Context == none || Context.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt; // wait for the resolved half of the activation
	}
	PerilsRef = Unit.FindAbility('Astartes_PerilsOfTheWarp');
	if (PerilsRef.ObjectID == 0)
	{
		return ELR_NoInterrupt; // not a Librarian
	}
	class'X2Ability_Astartes_Librarian'.static.RollPerils(ActivatedAbility, Unit);
	return ELR_NoInterrupt;
}
