//---------------------------------------------------------------------------------------
//  FILE:    Astartes_Inquisition.uc
//  PURPOSE: The Inquisition takes notice (design.md 9.1e), first slice. Back on the Avenger the
//           Chapter's Taint is tallied from what the soldiers carry home (unit values set in tactical):
//           a Librarian lost to possession, and each soldier's exposure to opened rifts. When Taint
//           reaches the judgement threshold a dialog offers Submit (the most exposed Librarian, else
//           the most exposed brother, is taken for censure; Taint resets; the first time, an
//           Inquisitor joins the Chapter) or Refuse (the Inquisition turns hostile; the next judgement
//           comes at twice the Taint). Proving purity in the field waits for a mission of its own.
//           Tuning in XComAstartes.ini under [Astartes.Astartes_Inquisition].
//---------------------------------------------------------------------------------------
class Astartes_Inquisition extends UIScreenListener config(Astartes);

var config bool bEnableInquisition;
var config int TAINT_THRESHOLD, TAINT_POSSESSION, TAINT_PER_EXPOSURE;
var config name InquisitorCharacter;
var name ExposureValueName, ExposureCountedName, PossessionCountedName;

var localized string JudgementTitle, JudgementText, JudgementSubmit, JudgementRefuse, CensureNobody, InquisitorArrives, RefusalText;

var bool bDialogOpen;
var StateObjectReference CensureRef;

event OnInit(UIScreen Screen)
{
	if (!default.bEnableInquisition || bDialogOpen || Screen == none)
	{
		return;
	}
	if (!Screen.IsA('UIFacilityGrid') && !Screen.IsA('UIStrategyMap'))
	{
		return;
	}
	TallyTaint();
	MaybeJudge();
}

/// Read what the soldiers brought home, add it to the Chapter's Taint, and mark it counted.
static function TallyTaint()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Unit, NewUnit;
	local array<StateObjectReference> Refs;
	local UnitValue Lost, Counted, Exposure, ExposureCounted;
	local int i, Added, Fresh;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
	{
		return;
	}
	Refs = XComHQ.Crew;
	for (i = 0; i < XComHQ.DeadCrew.Length; i++)
	{
		Refs.AddItem(XComHQ.DeadCrew[i]);
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: tally Taint");
	for (i = 0; i < Refs.Length; i++)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Refs[i].ObjectID));
		if (Unit == none)
		{
			continue;
		}
		Lost.fValue = 0; Counted.fValue = 0; Exposure.fValue = 0; ExposureCounted.fValue = 0;
		Unit.GetUnitValue(class'X2Effect_Astartes_SpawnDaemon'.default.LostToTheWarpValueName, Lost);
		Unit.GetUnitValue(default.PossessionCountedName, Counted);
		Unit.GetUnitValue(default.ExposureValueName, Exposure);
		Unit.GetUnitValue(default.ExposureCountedName, ExposureCounted);
		Fresh = int(Exposure.fValue - ExposureCounted.fValue);
		if ((Lost.fValue > 0 && Counted.fValue == 0) || Fresh > 0)
		{
			NewUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
			if (Lost.fValue > 0 && Counted.fValue == 0)
			{
				Added += default.TAINT_POSSESSION;
				NewUnit.SetUnitFloatValue(default.PossessionCountedName, 1, eCleanup_Never);
				`log("Astartes: Taint +" $ default.TAINT_POSSESSION @ "(" $ Unit.GetFullName() @ "lost to the Warp)",, 'Astartes');
			}
			if (Fresh > 0)
			{
				Added += Fresh * default.TAINT_PER_EXPOSURE;
				NewUnit.SetUnitFloatValue(default.ExposureCountedName, Exposure.fValue, eCleanup_Never);
			}
		}
	}
	if (Added <= 0)
	{
		History.CleanupPendingGameState(NewGameState);
		return;
	}
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.Taint += Added;
	`log("Astartes: Taint +" $ Added @ "-> " $ Chapter.Taint @ "(judgement at" @ JudgementThreshold(Chapter) $ ")",, 'Astartes');
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function int JudgementThreshold(XComGameState_AstartesChapter Chapter)
{
	return (Chapter == none || Chapter.JudgementAt <= 0) ? default.TAINT_THRESHOLD : Chapter.JudgementAt;
}

/// The most exposed living Librarian, else the most exposed living soldier who is not the Inquisitor.
static function StateObjectReference PickCensure()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit, Best;
	local UnitValue Exposure;
	local float BestScore, Score;
	local int i;
	local StateObjectReference EmptyRef;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	BestScore = -1;
	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (Unit == none || !Unit.IsSoldier() || !Unit.IsAlive() || Unit.GetMyTemplateName() == default.InquisitorCharacter)
		{
			continue;
		}
		Exposure.fValue = 0;
		Unit.GetUnitValue(default.ExposureValueName, Exposure);
		Score = Exposure.fValue + (Unit.GetSoldierClassTemplateName() == 'Astartes_Librarian' ? 1000 : 0);
		if (Score > BestScore)
		{
			BestScore = Score;
			Best = Unit;
		}
	}
	return Best != none ? Best.GetReference() : EmptyRef;
}

function MaybeJudge()
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Censure;
	local TDialogueBoxData Data;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none || Chapter.Taint < JudgementThreshold(Chapter))
	{
		return;
	}
	CensureRef = PickCensure();
	Censure = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CensureRef.ObjectID));
	Data.eType = eDialog_Warning;
	Data.strTitle = JudgementTitle;
	Data.strText = Repl(Repl(JudgementText, "%TAINT", string(Chapter.Taint)), "%CENSURE", Censure != none ? Censure.GetFullName() : CensureNobody);
	if (!Chapter.bInquisitorJoined)
	{
		Data.strText $= "\n\n" $ InquisitorArrives;
	}
	Data.strAccept = JudgementSubmit;
	Data.strCancel = JudgementRefuse;
	Data.fnCallback = OnJudgement;
	bDialogOpen = true;
	`HQPRES.UIRaiseDialog(Data);
	`log("Astartes: the Inquisition sits in judgement (Taint" @ Chapter.Taint $ ")",, 'Astartes');
}

simulated function OnJudgement(Name eAction)
{
	bDialogOpen = false;
	if (eAction == 'eUIAction_Accept')
	{
		Submit(CensureRef);
	}
	else
	{
		Refuse();
	}
}

/// Submit: the censured brother leaves the Chapter, Taint resets, and the first time an Inquisitor joins.
static function Submit(StateObjectReference Censured)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Inquisitor;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: submit to the Inquisition");
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	if (Censured.ObjectID > 0)
	{
		XComHQ.RemoveFromCrew(Censured);
		`log("Astartes: unit" @ Censured.ObjectID @ "taken by the Inquisition for censure",, 'Astartes');
	}
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.Taint = 0;
	Chapter.JudgementAt = default.TAINT_THRESHOLD;
	if (!Chapter.bInquisitorJoined && class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(default.InquisitorCharacter) != none)
	{
		Inquisitor = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, default.InquisitorCharacter, '', false);
		XComHQ.AddToCrew(NewGameState, Inquisitor);
		Chapter.bInquisitorJoined = true;
		`log("Astartes: Inquisitor" @ Inquisitor.GetFullName() @ "joins the Chapter",, 'Astartes');
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// Refuse: the Inquisition remembers. Taint stays; the next judgement waits for twice the Taint.
static function Refuse()
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;
	local TDialogueBoxData Data;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: refuse the Inquisition");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.bInquisitionHostile = true;
	Chapter.JudgementAt = Chapter.Taint + default.TAINT_THRESHOLD;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("Astartes: the Chapter refused the Inquisition; next judgement at Taint" @ Chapter.JudgementAt,, 'Astartes');
	Data.eType = eDialog_Alert;
	Data.strTitle = default.JudgementTitle;
	Data.strText = default.RefusalText;
	Data.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
	`HQPRES.UIRaiseDialog(Data);
}

defaultproperties
{
	ScreenClass = none
	ExposureValueName = "Astartes_WarpExposure"
	ExposureCountedName = "Astartes_WarpExposureCounted"
	PossessionCountedName = "Astartes_PossessionCounted"
}
