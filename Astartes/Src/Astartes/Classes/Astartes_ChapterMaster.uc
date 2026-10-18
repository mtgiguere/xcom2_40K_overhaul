//---------------------------------------------------------------------------------------
//  FILE:    Astartes_ChapterMaster.uc
//  PURPOSE: The Chapter's unique seats (design.md 4.4): Chapter Master, Chief Librarian, Master of
//           Sanctity. One holder per seat at a time, appointed from a top-rank Marine; each seat has
//           class rules and a relic ability, granted as an unlocked class-agnostic ability so it lives
//           in the soldier's own ability list. The Chapter Master's relic depends on his origin class
//           (Capstones). Lost holders are counted per seat for a later replacement cost.
//---------------------------------------------------------------------------------------
class Astartes_ChapterMaster extends Object config(Astartes);

struct CapstoneDef
{
	var name SoldierClass;   // e.g. Astartes_Assault
	var name Ability;        // e.g. Astartes_DeathIncarnate
};

struct UniqueSeat
{
	var name Seat;                   // ChapterMaster, ChiefLibrarian, MasterOfSanctity
	var string Title;                // for messages
	var name RequiredClass;          // '' = any combat class not excluded
	var array<name> ExcludedClasses; // classes that can never hold this seat
	var name Ability;                // relic ability (ignored when bCapstoneByClass)
	var bool bCapstoneByClass;       // relic ability comes from Capstones, by the holder's class
	var string Nickname;             // title given as nickname when the Marine has none ("" = leave)
};

var config array<CapstoneDef> Capstones;
var config array<UniqueSeat> Seats;
var config int CHAPTER_MASTER_MIN_RANK; // minimum rank for every seat (7 = the top rank)

static function name CapstoneFor(name SoldierClass)
{
	local int i;

	for (i = 0; i < default.Capstones.Length; i++)
	{
		if (default.Capstones[i].SoldierClass == SoldierClass)
		{
			return default.Capstones[i].Ability;
		}
	}
	return '';
}

static function bool GetSeat(name Seat, out UniqueSeat Def)
{
	local int i;

	for (i = 0; i < default.Seats.Length; i++)
	{
		if (default.Seats[i].Seat == Seat)
		{
			Def = default.Seats[i];
			return true;
		}
	}
	return false;
}

/// The living holder of a seat, or none.
static function XComGameState_Unit GetSeatHolder(name Seat)
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Unit;
	local StateObjectReference Ref;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none)
	{
		return none;
	}
	Ref = Chapter.GetSeatRef(Seat);
	if (Ref.ObjectID == 0)
	{
		return none;
	}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
	if (Unit == none || Unit.IsDead() || Unit.bCaptured)
	{
		return none;
	}
	return Unit;
}

/// Can this Marine take the seat? Reason explains a refusal.
static function bool IsEligible(name Seat, XComGameState_Unit UnitState, out string Reason)
{
	local UniqueSeat Def;
	local XComGameState_Unit Current;
	local name SoldierClass;

	if (!GetSeat(Seat, Def))
	{
		Reason = "unknown seat" @ Seat;
		return false;
	}
	if (UnitState == none || !UnitState.IsSoldier())
	{
		Reason = "not a soldier";
		return false;
	}
	SoldierClass = UnitState.GetSoldierClassTemplateName();
	if (Def.RequiredClass != '' && SoldierClass != Def.RequiredClass)
	{
		Reason = "only a" @ Def.RequiredClass @ "can be" @ Def.Title;
		return false;
	}
	if (Def.ExcludedClasses.Find(SoldierClass) != INDEX_NONE)
	{
		Reason = "a" @ SoldierClass @ "cannot be" @ Def.Title;
		return false;
	}
	if (UnitState.GetRank() < default.CHAPTER_MASTER_MIN_RANK)
	{
		Reason = "rank" @ UnitState.GetRank() @ "is below the required" @ default.CHAPTER_MASTER_MIN_RANK;
		return false;
	}
	Current = GetSeatHolder(Seat);
	if (Current != none)
	{
		Reason = Current.ObjectID == UnitState.ObjectID ? "already" @ Def.Title : Current.GetFullName() @ "is" @ Def.Title @ "and lives";
		return false;
	}
	Reason = "";
	return true;
}

/// Appoint a Marine to a seat. Modifies the unit and the Chapter state inside NewGameState; the caller submits.
static function bool AppointToSeat(name Seat, XComGameState_Unit UnitState, XComGameState NewGameState, out string Reason)
{
	local UniqueSeat Def;
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit NewUnit;
	local ClassAgnosticAbility Relic;
	local name RelicName;
	local int i;

	if (!IsEligible(Seat, UnitState, Reason))
	{
		return false;
	}
	GetSeat(Seat, Def);

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.SetSeatRef(Seat, UnitState.GetReference());

	NewUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	RelicName = Def.bCapstoneByClass ? CapstoneFor(NewUnit.GetSoldierClassTemplateName()) : Def.Ability;
	if (RelicName != '')
	{
		for (i = 0; i < NewUnit.AWCAbilities.Length; i++)
		{
			if (NewUnit.AWCAbilities[i].AbilityType.AbilityName == RelicName)
			{
				break;
			}
		}
		if (i == NewUnit.AWCAbilities.Length)
		{
			Relic.AbilityType.AbilityName = RelicName;
			Relic.AbilityType.ApplyToWeaponSlot = eInvSlot_Unknown;
			Relic.bUnlocked = true;
			Relic.iRank = 0;
			NewUnit.AWCAbilities.AddItem(Relic);
		}
	}
	else
	{
		`log("Astartes: no relic ability configured for" @ Def.Title @ "from" @ NewUnit.GetSoldierClassTemplateName() @ "yet",, 'Astartes');
	}
	if (Def.Nickname != "" && NewUnit.GetNickName(true) == "")
	{
		NewUnit.SetUnitName(NewUnit.GetFirstName(), NewUnit.GetLastName(), Def.Nickname);
	}
	`log("Astartes:" @ Def.Title @ "appointed:" @ NewUnit.GetFullName() @ "(" $ NewUnit.GetSoldierClassTemplateName() $ ") relic" @ RelicName,, 'Astartes');
	Reason = "";
	return true;
}

/// Pick the first barracks soldier eligible for the seat, or the one whose name contains NameFragment.
static function XComGameState_Unit FindCandidate(name Seat, string NameFragment)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local string Reason;
	local int i;

	XComHQ = `XCOMHQ;
	if (XComHQ == none)
	{
		return none;
	}
	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (UnitState == none || !UnitState.IsSoldier() || UnitState.IsDead())
		{
			continue;
		}
		if (NameFragment != "")
		{
			if (InStr(Caps(UnitState.GetFullName()), Caps(NameFragment)) != INDEX_NONE)
			{
				return UnitState;
			}
			continue;
		}
		if (IsEligible(Seat, UnitState, Reason))
		{
			return UnitState;
		}
	}
	return none;
}

// Compatibility names.
static function XComGameState_Unit GetChapterMaster() { return GetSeatHolder('ChapterMaster'); }
static function XComGameState_Unit GetChiefLibrarian() { return GetSeatHolder('ChiefLibrarian'); }
