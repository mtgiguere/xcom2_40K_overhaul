//---------------------------------------------------------------------------------------
//  FILE:    Astartes_NoHeroes.uc
//  PURPOSE: No resistance faction heroes in a Space Marine Chapter (decision 2026-10-18: Skirmishers
//           are xenos hybrids, Templars unsanctioned psykers, Reapers go with them). Every reward that
//           would hand XCOM a Reaper, Skirmisher or Templar hands over a Marine recruit instead, and
//           the faction is still met when the reward came from a Find Faction action. Covert action
//           staff slots that demanded a hero class accept any soldier. The factions themselves stay as
//           the strategy layer's allies until the 40K strategy rewrite replaces them.
//           Lost and Abandoned (campaign option) still fields its two heroes: turn that option off.
//---------------------------------------------------------------------------------------
class Astartes_NoHeroes extends Object config(Astartes);

var config bool bNoFactionHeroes;
var config array<name> HeroRewardTemplates;   // reward templates that generate a faction hero
var config name RecruitCharacterTemplate;    // what they generate instead (a rookie: our Marine classes take over on promotion)

static function Apply()
{
	local X2StrategyElementTemplateManager Mgr;
	local array<X2DataTemplate> Variants;
	local array<X2StrategyElementTemplate> All;
	local X2DataTemplate DataTemplate;
	local X2StrategyElementTemplate StratTemplate;
	local X2RewardTemplate Reward;
	local X2CovertActionTemplate Action;
	local int i, j, Rewired, Slots;

	if (!default.bNoFactionHeroes)
	{
		return;
	}
	Mgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	for (i = 0; i < default.HeroRewardTemplates.Length; i++)
	{
		Variants.Length = 0;
		Mgr.FindDataTemplateAllDifficulties(default.HeroRewardTemplates[i], Variants);
		foreach Variants(DataTemplate)
		{
			Reward = X2RewardTemplate(DataTemplate);
			if (Reward == none)
			{
				continue;
			}
			Reward.GenerateRewardFn = GenerateRecruitReward;
			Reward.GiveRewardFn = GiveRecruitReward;
			Reward.RewardPopupFn = class'X2StrategyElement_DefaultRewards'.static.PersonnelRewardPopup;
			Rewired++;
		}
	}
	All = Mgr.GetAllTemplatesOfClass(class'X2CovertActionTemplate');
	foreach All(StratTemplate)
	{
		Action = X2CovertActionTemplate(StratTemplate);
		if (Action == none)
		{
			continue;
		}
		for (j = 0; j < Action.Slots.Length; j++)
		{
			if (Action.Slots[j].bFactionClass)
			{
				Action.Slots[j].bFactionClass = false;
				Slots++;
			}
		}
	}
	`log("Astartes: no faction heroes:" @ Rewired @ "hero rewards now give Marine recruits;" @ Slots @ "hero-only covert action slots opened",, 'Astartes');
}

/// A rookie from the action's (or faction's) region instead of the faction's champion.
static function GenerateRecruitReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_Unit NewUnitState;
	local name nmCountry;

	History = `XCOMHISTORY;
	ActionState = XComGameState_CovertAction(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
	if (ActionState == none)
	{
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	}
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	if (ActionState != none)
	{
		RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(ActionState.Region.ObjectID));
	}
	else if (FactionState != none)
	{
		RegionState = FactionState.GetHomeRegion();
	}
	if (RegionState != none)
	{
		nmCountry = RegionState.GetMyTemplate().GetRandomCountryInRegion();
	}
	NewUnitState = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, default.RecruitCharacterTemplate, nmCountry, true);
	RewardState.RewardObjectReference = NewUnitState.GetReference();
	`log("Astartes: hero reward" @ RewardState.GetMyTemplateName() @ "generated a Marine recruit instead:" @ NewUnitState.GetFullName(),, 'Astartes');
}

/// Hand the recruit over; if the reward belonged to a faction XCOM has not met, meet it (the Find Faction path).
static function GiveRecruitReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local XComGameState_ResistanceFaction FactionState;

	class'X2StrategyElement_DefaultRewards'.static.GivePersonnelReward(NewGameState, RewardState, AuxRef, bOrder, OrderHours);

	History = `XCOMHISTORY;
	ActionState = XComGameState_CovertAction(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
	if (ActionState == none)
	{
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	}
	if (ActionState != none)
	{
		FactionState = ActionState.GetFaction();
	}
	else
	{
		FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(AuxRef.ObjectID));
	}
	if (FactionState != none && !FactionState.bMetXCom)
	{
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', FactionState.ObjectID));
		FactionState.MeetXCom(NewGameState);
	}
}
