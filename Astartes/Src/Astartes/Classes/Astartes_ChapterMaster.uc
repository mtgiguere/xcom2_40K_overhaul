//---------------------------------------------------------------------------------------
//  FILE:    Astartes_ChapterMaster.uc
//  PURPOSE: The Chapter Master (design.md 4.4): one at a time, appointed from a rank-7 Marine, and
//           his relic ability depends on the class he came from (config Capstones). The capstone is
//           granted as an unlocked class-agnostic ability so it lives in the soldier's own ability
//           list. Replacing a dead Chapter Master is tracked (ChapterMastersLost) for a later cost.
//---------------------------------------------------------------------------------------
class Astartes_ChapterMaster extends Object config(Astartes);

struct CapstoneDef
{
	var name SoldierClass;   // e.g. Astartes_Assault
	var name Ability;        // e.g. Astartes_DeathIncarnate
};

var config array<CapstoneDef> Capstones;
var config int CHAPTER_MASTER_MIN_RANK;
var config string CHAPTER_MASTER_NICKNAME;
// Classes that can never hold the Chapter Master's seat (the Librarius has its own head).
var config array<name> ChapterMasterExcludedClasses;
// The Chief Librarian: which class qualifies, his relic ability and title.
var config name CHIEF_LIBRARIAN_CLASS;
var config name CHIEF_LIBRARIAN_ABILITY;
var config string CHIEF_LIBRARIAN_NICKNAME;

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

/// The current Chapter Master, or none if there is none or he is dead/captured.
static function XComGameState_Unit GetChapterMaster()
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Unit;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none || Chapter.ChapterMasterRef.ObjectID == 0)
	{
		return none;
	}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Chapter.ChapterMasterRef.ObjectID));
	if (Unit == none || Unit.IsDead() || Unit.bCaptured)
	{
		return none;
	}
	return Unit;
}

/// Appoint a Marine. Returns false with a reason when the rules forbid it. Modifies the unit and the
/// Chapter state inside NewGameState; the caller submits.
static function bool Appoint(XComGameState_Unit UnitState, XComGameState NewGameState, out string Reason)
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Current, NewUnit;
	local ClassAgnosticAbility Capstone;
	local name CapstoneName;
	local int i;

	if (UnitState == none || !UnitState.IsSoldier())
	{
		Reason = "not a soldier";
		return false;
	}
	if (UnitState.GetRank() < default.CHAPTER_MASTER_MIN_RANK)
	{
		Reason = "rank" @ UnitState.GetRank() @ "is below the required" @ default.CHAPTER_MASTER_MIN_RANK;
		return false;
	}
	if (default.ChapterMasterExcludedClasses.Find(UnitState.GetSoldierClassTemplateName()) != INDEX_NONE)
	{
		Reason = "a" @ UnitState.GetSoldierClassTemplateName() @ "cannot hold the Chapter Master's seat (the Librarius has its own head)";
		return false;
	}
	Current = GetChapterMaster();
	if (Current != none && Current.ObjectID != UnitState.ObjectID)
	{
		Reason = Current.GetFullName() @ "is the Chapter Master and lives";
		return false;
	}
	if (Current != none)
	{
		Reason = "already the Chapter Master";
		return false;
	}

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	if (Chapter.ChapterMasterRef.ObjectID != 0)
	{
		Chapter.ChapterMastersLost++; // the previous one is dead or captured
	}
	Chapter.ChapterMasterRef = UnitState.GetReference();

	NewUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	CapstoneName = CapstoneFor(NewUnit.GetSoldierClassTemplateName());
	if (CapstoneName != '')
	{
		for (i = 0; i < NewUnit.AWCAbilities.Length; i++)
		{
			if (NewUnit.AWCAbilities[i].AbilityType.AbilityName == CapstoneName)
			{
				break;
			}
		}
		if (i == NewUnit.AWCAbilities.Length)
		{
			Capstone.AbilityType.AbilityName = CapstoneName;
			Capstone.AbilityType.ApplyToWeaponSlot = eInvSlot_Unknown;
			Capstone.bUnlocked = true;
			Capstone.iRank = 0;
			NewUnit.AWCAbilities.AddItem(Capstone);
		}
	}
	else
	{
		`log("Astartes: no Chapter Master capstone configured for" @ NewUnit.GetSoldierClassTemplateName() @ "yet",, 'Astartes');
	}
	if (default.CHAPTER_MASTER_NICKNAME != "" && NewUnit.GetNickName(true) == "")
	{
		NewUnit.SetUnitName(NewUnit.GetFirstName(), NewUnit.GetLastName(), default.CHAPTER_MASTER_NICKNAME);
	}
	`log("Astartes: Chapter Master appointed:" @ NewUnit.GetFullName() @ "(" $ NewUnit.GetSoldierClassTemplateName() $ ") capstone" @ CapstoneName,, 'Astartes');
	Reason = "";
	return true;
}

// --- Chief Librarian -----------------------------------------------------------------------

static function XComGameState_Unit GetChiefLibrarian()
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Unit;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none || Chapter.ChiefLibrarianRef.ObjectID == 0)
	{
		return none;
	}
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Chapter.ChiefLibrarianRef.ObjectID));
	if (Unit == none || Unit.IsDead() || Unit.bCaptured)
	{
		return none;
	}
	return Unit;
}

/// Appoint the head of the Librarius. Top-rank Librarians only; one at a time; grants CHIEF_LIBRARIAN_ABILITY.
static function bool AppointChiefLibrarian(XComGameState_Unit UnitState, XComGameState NewGameState, out string Reason)
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Unit Current, NewUnit;
	local ClassAgnosticAbility Capstone;
	local int i;

	if (UnitState == none || !UnitState.IsSoldier())
	{
		Reason = "not a soldier";
		return false;
	}
	if (UnitState.GetSoldierClassTemplateName() != default.CHIEF_LIBRARIAN_CLASS)
	{
		Reason = "only a" @ default.CHIEF_LIBRARIAN_CLASS @ "can head the Librarius";
		return false;
	}
	if (UnitState.GetRank() < default.CHAPTER_MASTER_MIN_RANK)
	{
		Reason = "rank" @ UnitState.GetRank() @ "is below the required" @ default.CHAPTER_MASTER_MIN_RANK;
		return false;
	}
	Current = GetChiefLibrarian();
	if (Current != none)
	{
		Reason = Current.ObjectID == UnitState.ObjectID ? "already the Chief Librarian" : Current.GetFullName() @ "is the Chief Librarian and lives";
		return false;
	}

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	if (Chapter.ChiefLibrarianRef.ObjectID != 0)
	{
		Chapter.ChiefLibrariansLost++;
	}
	Chapter.ChiefLibrarianRef = UnitState.GetReference();

	NewUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	for (i = 0; i < NewUnit.AWCAbilities.Length; i++)
	{
		if (NewUnit.AWCAbilities[i].AbilityType.AbilityName == default.CHIEF_LIBRARIAN_ABILITY)
		{
			break;
		}
	}
	if (i == NewUnit.AWCAbilities.Length && default.CHIEF_LIBRARIAN_ABILITY != '')
	{
		Capstone.AbilityType.AbilityName = default.CHIEF_LIBRARIAN_ABILITY;
		Capstone.AbilityType.ApplyToWeaponSlot = eInvSlot_Unknown;
		Capstone.bUnlocked = true;
		NewUnit.AWCAbilities.AddItem(Capstone);
	}
	if (default.CHIEF_LIBRARIAN_NICKNAME != "" && NewUnit.GetNickName(true) == "")
	{
		NewUnit.SetUnitName(NewUnit.GetFirstName(), NewUnit.GetLastName(), default.CHIEF_LIBRARIAN_NICKNAME);
	}
	`log("Astartes: Chief Librarian appointed:" @ NewUnit.GetFullName() @ "relic" @ default.CHIEF_LIBRARIAN_ABILITY,, 'Astartes');
	Reason = "";
	return true;
}
