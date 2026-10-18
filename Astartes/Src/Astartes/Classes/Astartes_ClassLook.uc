//---------------------------------------------------------------------------------------
//  FILE:    Astartes_ClassLook.uc
//  PURPOSE: Class-specific appearance applied on promotion (the recruit generator cannot know
//           the class). First use: Librarians get the psychic hood as head gear.
//           Registered as a Highlander event listener on the unit rank-up event.
//---------------------------------------------------------------------------------------
class Astartes_ClassLook extends X2EventListener config(Astartes);

struct ClassHelmet
{
	var name SoldierClass;
	var name Helmet;   // X2BodyPartTemplate name (PartType "Helmets")
};

var config array<ClassHelmet> ClassHelmets;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateRankUpListener());
	return Templates;
}

static function CHEventListenerTemplate CreateRankUpListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Astartes_ClassLook_RankUp');
	Template.RegisterInStrategy = true;
	Template.RegisterInTactical = true;
	Template.AddCHEvent('UnitRankUp', OnUnitRankUp, ELD_Immediate);
	return Template;
}

static function EventListenerReturn OnUnitRankUp(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local X2BodyPartTemplateManager PartMgr;
	local TAppearance Appearance;
	local name Helmet;

	// RankUpSoldier triggers 'UnitRankUp' with the unit as EventData (EventSource is empty).
	UnitState = XComGameState_Unit(EventData);
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(EventSource);
	}
	if (UnitState == none || GameState == none)
	{
		return ELR_NoInterrupt;
	}

	NewUnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (NewUnitState == none)
	{
		NewUnitState = XComGameState_Unit(GameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	}

	// Optional-mod abilities that are not loaded become their vanilla stand-ins in this soldier's tree.
	if (class'X2DownloadableContentInfo_Astartes'.default.MarineClasses.Find(NewUnitState.GetSoldierClassTemplateName()) != INDEX_NONE)
	{
		class'Astartes_AbilityVariants'.static.ApplyFallbacksToUnit(NewUnitState);
	}

	Helmet = HelmetForClass(NewUnitState.GetSoldierClassTemplateName());
	if (Helmet == '' || NewUnitState.kAppearance.nmHelmet == Helmet)
	{
		return ELR_NoInterrupt;
	}

	PartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	if (PartMgr.FindUberTemplate("Helmets", Helmet) == none)
	{
		`log("Astartes: class helmet" @ Helmet @ "is not a loaded body part; skipping",, 'Astartes');
		return ELR_NoInterrupt;
	}

	Appearance = NewUnitState.kAppearance;
	Appearance.nmHelmet = Helmet;
	NewUnitState.SetTAppearance(Appearance);
	NewUnitState.StoreAppearance();
	`log("Astartes: " $ NewUnitState.GetFullName() @ "promoted into" @ NewUnitState.GetSoldierClassTemplateName() $ "; helmet set to" @ Helmet,, 'Astartes');
	return ELR_NoInterrupt;
}

static function name HelmetForClass(name SoldierClass)
{
	local int i;

	for (i = 0; i < default.ClassHelmets.Length; i++)
	{
		if (default.ClassHelmets[i].SoldierClass == SoldierClass)
		{
			return default.ClassHelmets[i].Helmet;
		}
	}
	return '';
}
