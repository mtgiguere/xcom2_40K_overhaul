//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_Astartes.uc
//  PURPOSE: Entry point for the Warhammer 40K overhaul. Campaign-start hooks, Highlander
//           hooks (recruit appearance), and the developer console commands (exec functions)
//           that double as the runtime test harness.
//---------------------------------------------------------------------------------------
class X2DownloadableContentInfo_Astartes extends X2DownloadableContentInfo;

/// Soldier classes this mod defines, in roster order. Kept in sync with tests/data/class_trees.json.
var config array<name> MarineClasses;

/// Lore default: Space Marines are male. Set true to let the generator roll female Marines
/// (they will wear whatever female-compatible armour exists, which today is XCOM gear).
var config bool bAllowFemaleMarines;
/// LWOTI (7.8): recruits are Guardsmen; Marines are made at the first promotion (Astartes_Ascension), not generated.
var config bool bMarinesByAscension;
/// Faction heroes the campaign start hands out (WotC's starting faction soldier): removed from the crew.
var config array<name> StripStartingCharacters;
/// LWOTI: every new recruit is dressed as a Guardsman (Astartes_CharGen_Dressed looks, by gender).
var config name RecruitLookMale, RecruitLookFemale;
/// LWOTC haven rebels (and the rebel soldiers copied from them) are dressed as Guardsmen too.
var config array<name> RebelTemplates;
/// The Blood Angels strike force that arrives at campaign start (design 1b): class, rank, optional nickname.
struct StartingMarine
{
	var name SoldierClass;
	var int Rank;
	var string Nickname;
};
var config array<StartingMarine> StartingMarines;

/// Body-part packs (DLCName values) that define the Marine look. Recruits are generated from
/// these packs only, when present. Empty list = vanilla random appearance.
var config array<name> MarineArmorPartPacks;
/// Only parts whose display name contains one of these are used (e.g. "Tint": the packs label tintable
/// pieces, unlabelled ones are pre-painted for one Chapter). Empty = any part from the packs.
var config array<string> MarinePartNameKeywords;
// Character-pool soldiers whose armour parts every generated Marine copies (one is picked at random). The
// player dresses a 'standard' Marine once in the pool; tints and pattern still come from the Chapter livery.
// Empty, or none found: parts are picked at random from the packs (power fists and jump packs included).
var config array<string> MarineLookTemplates;
// The same look as explicit part names, shipped with the mod so players without the pool template get it
// (Astartes_ExportLook <pool name> prints a ready-to-paste line). Used when no pool template is found.
struct MarineLook
{
	var name nmTorso;
	var name nmArms;
	var name nmLeftArm;
	var name nmRightArm;
	var name nmLeftArmDeco;
	var name nmRightArmDeco;
	var name nmLeftForearm;
	var name nmRightForearm;
	var name nmLegs;
	var name nmThighs;
	var name nmShins;
	var name nmTorsoDeco;
	var name nmHelmet;
};
var config array<MarineLook> MarineLookParts;

struct ChapterLivery
{
	var name Country;        // X2CountryTemplate name, e.g. Country_Ultramarines (from the chapter flag mods)
	var int PrimaryTint;     // armour palette index; -1 = leave random
	var int SecondaryTint;   // armour palette index; -1 = leave random
	var name Pattern;        // armour pattern body part; '' = leave
	structdefaultproperties
	{
		PrimaryTint = -1
		SecondaryTint = -1
	}
};

/// Default Chapter (a country template) every Marine recruit belongs to. The Chapter state can override it
/// (Astartes_Chapter console command, later the campaign-start chooser). '' = vanilla random countries.
var config name ChapterCountry;
/// Country whose name lists are used when the Chapter's country has none.
var config name NameFallbackCountry;
/// Armour colours per Chapter.
var config array<ChapterLivery> ChapterLiveries;

// ---------------------------------------------------------------------------------------
// Campaign lifecycle
// ---------------------------------------------------------------------------------------

/// Called when the player starts a new campaign while this mod is installed.
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_AstartesChapter Chapter;

	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(StartState);
	Chapter.AssignContinentFactions(StartState);
	StripStartingHeroes(StartState);
	AddStrikeForce(StartState);
	`log("Astartes: new campaign started",, 'Astartes');
}

/// The strike force: Marines made the way the game makes its starting soldiers, then promoted into their class and
/// given the ascended physique and the Chapter's armour. They join the barracks and, while there is room, the first squad.
static function AddStrikeForce(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local XGCharacterGenerator CharGen;
	local TSoldier Man;
	local int i, r;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}
	if (XComHQ == none || default.StartingMarines.Length == 0)
	{
		return;
	}
	CharGen = class'Engine'.static.GetCurrentWorldInfo().Spawn(class'XGCharacterGenerator');
	for (i = 0; i < default.StartingMarines.Length; i++)
	{
		Unit = `CHARACTERPOOLMGR.CreateCharacter(StartState, eCPSM_RandomOnly);
		if (Unit == none)
		{
			continue;
		}
		if (CharGen != none && EGender(Unit.kAppearance.iGender) == eGender_Female)
		{
			Man = CharGen.CreateTSoldier('Soldier', eGender_Male);
			Unit.SetTAppearance(Man.kAppearance);
			Unit.SetCharacterName(Man.strFirstName, Man.strLastName, Man.strNickName);
		}
		Unit.RandomizeStats();
		Unit.ApplyInventoryLoadout(StartState);
		for (r = 0; r < Max(1, default.StartingMarines[i].Rank); r++)
		{
			Unit.RankUpSoldier(StartState, r == 0 ? default.StartingMarines[i].SoldierClass : '');
		}
		Unit.ApplySquaddieLoadout(StartState, XComHQ);
		class'Astartes_Ascension'.static.Ascend(Unit);
		if (default.StartingMarines[i].Nickname != "")
		{
			Unit.SetCharacterName(Unit.GetFirstName(), Unit.GetLastName(), default.StartingMarines[i].Nickname);
		}
		Unit.SetHQLocation(eSoldierLoc_Barracks);
		XComHQ.AddToCrew(StartState, Unit);
		if (XComHQ.Squad.Length < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
		{
			XComHQ.Squad.AddItem(Unit.GetReference());
		}
		`log("Astartes: strike force:" @ Unit.GetFullName() @ "joins as" @ default.StartingMarines[i].SoldierClass @ "rank" @ Unit.GetRank(),, 'Astartes');
	}
	if (CharGen != none)
	{
		CharGen.Destroy();
	}
}

/// No Reapers, Skirmishers or Templars, not even the one the campaign start hands out (LWOTC spike, 2026-10-19).
static function StripStartingHeroes(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Gone;
	local int i;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}
	if (XComHQ == none)
	{
		return;
	}
	foreach StartState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if (default.StripStartingCharacters.Find(Unit.GetMyTemplateName()) != INDEX_NONE && XComHQ.Crew.Find('ObjectID', Unit.ObjectID) != INDEX_NONE)
		{
			Gone.AddItem(Unit.GetReference());
		}
	}
	for (i = 0; i < Gone.Length; i++)
	{
		XComHQ.RemoveFromCrew(Gone[i]);
		XComHQ.Squad.RemoveItem(Gone[i]); // LWOTC builds its first mission squad from this list (spike 2: a Reaper deployed)
		`log("Astartes: starting faction hero" @ Gone[i].ObjectID @ "removed from the crew",, 'Astartes');
	}
}

// ---------------------------------------------------------------------------------------
// Continent faction ownership (Highlander hooks, issues #136 / #278)
// ---------------------------------------------------------------------------------------

/// Called per pod when a mission's encounter data is cached. SourceObject is the mission site.
static function PostEncounterCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject)
{
	if (RewriteAllies(Encounter, "pod" @ EncounterName, XComGameState_MissionSite(SourceObject)) || RewriteIncursion(Encounter, EncounterName, ForceLevel, "pod" @ EncounterName))
	{
		return;
	}
	RewritePodForContinent(Encounter, EncounterName, ForceLevel, XComGameState_MissionSite(SourceObject), "pod" @ EncounterName);
}

/// Called per reinforcement group. SourceObject is the BattleData, which knows the mission.
static function PostReinforcementCreation(out name EncounterName, out PodSpawnInfo Encounter, int ForceLevel, int AlertLevel, optional XComGameState_BaseObject SourceObject, optional XComGameState_BaseObject ReinforcementState)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSite;

	BattleData = XComGameState_BattleData(SourceObject);
	if (BattleData != none)
	{
		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(BattleData.m_iMissionID));
	}
	if (RewriteAllies(Encounter, "reinforcements" @ EncounterName, MissionSite) || RewriteIncursion(Encounter, EncounterName, ForceLevel, "reinforcements" @ EncounterName))
	{
		return;
	}
	RewritePodForContinent(Encounter, EncounterName, ForceLevel, MissionSite, "reinforcements" @ EncounterName);
}

/// Allied pods: the resistance militia are the Imperial Guard (2026-10-18). Each configured template is swapped when its
/// replacement exists (the dressed Guardsmen need no mod to exist; their look and lasgun do). True when anything changed.
static function bool RewriteAllies(out PodSpawnInfo Encounter, string Context, optional XComGameState_MissionSite MissionSite)
{
	local X2CharacterTemplateManager CharMgr;
	local XComGameState_AstartesChapter Chapter;
	local name HeldBy, To;
	local int i, j;
	local bool bChanged;

	if (Encounter.Team != eTeam_Resistance)
	{
		return false;
	}
	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter != none && MissionSite != none && MissionSite.GetContinent() != none)
	{
		HeldBy = Chapter.GetFactionForContinent(MissionSite.GetContinent().GetReference());
	}
	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	for (i = 0; i < Encounter.SelectedCharacterTemplateNames.Length; i++)
	{
		// a swap bound to the continent's faction wins over the general one
		To = '';
		for (j = 0; j < class'Astartes_FactionConfig'.default.AllyReplacements.Length; j++)
		{
			if (class'Astartes_FactionConfig'.default.AllyReplacements[j].From != Encounter.SelectedCharacterTemplateNames[i]
				|| CharMgr.FindCharacterTemplate(class'Astartes_FactionConfig'.default.AllyReplacements[j].To) == none)
			{
				continue;
			}
			if (class'Astartes_FactionConfig'.default.AllyReplacements[j].ContinentFaction == '')
			{
				if (To == '') To = class'Astartes_FactionConfig'.default.AllyReplacements[j].To;
			}
			else if (class'Astartes_FactionConfig'.default.AllyReplacements[j].ContinentFaction == HeldBy)
			{
				To = class'Astartes_FactionConfig'.default.AllyReplacements[j].To;
				break;
			}
		}
		if (To != '')
		{
			Encounter.SelectedCharacterTemplateNames[i] = To;
			bChanged = true;
		}
	}
	if (bChanged)
	{
		`log("Astartes: allies" @ Context @ "rewritten (continent held by" @ HeldBy $ ")",, 'Astartes');
	}
	return bChanged;
}

/// The Lost are Eldar (decision 2026-10-18): a Lost pod or swarm becomes a webway incursion pod on the alien team, on any
/// continent, capped at IncursionMaxPodSize. Returns true when the pod was replaced. Without the Eldar mods the Lost stay Lost.
static function bool RewriteIncursion(out PodSpawnInfo Encounter, name EncounterName, int ForceLevel, string Context)
{
	local FactionDef Def;
	local array<name> NewTemplates;
	local int Size;

	if (!class'Astartes_FactionConfig'.default.bEnableIncursions || !class'Astartes_FactionConfig'.static.IsIncursionEncounter(EncounterName))
	{
		return false;
	}
	if (Encounter.SelectedCharacterTemplateNames.Length == 0 || Encounter.StrategyUnitTag != '')
	{
		return false;
	}
	Def = class'Astartes_FactionConfig'.default.Incursion;
	if (!class'Astartes_FactionConfig'.static.IsFactionAvailable(Def))
	{
		`log("Astartes: incursion lists not loaded (is" @ Def.RequiredDLC @ "enabled?); the Lost stay the Lost for" @ Context,, 'Astartes');
		return false;
	}
	Size = Encounter.SelectedCharacterTemplateNames.Length;
	if (class'Astartes_FactionConfig'.default.IncursionMaxPodSize > 0)
	{
		Size = Min(Size, class'Astartes_FactionConfig'.default.IncursionMaxPodSize);
	}
	if (!class'Astartes_FactionConfig'.static.BuildPod(Def, ForceLevel, Size, NewTemplates, false))
	{
		`log("Astartes: incursion has no eligible units at force level" @ ForceLevel @ "for" @ Context,, 'Astartes');
		return false;
	}
	`log("Astartes: Incursion" @ Context @ "FL" $ ForceLevel @ "->" @ Def.FactionName @ "x" $ NewTemplates.Length @ "(was" @ Encounter.SelectedCharacterTemplateNames.Length @ "Lost)",, 'Astartes');
	Encounter.SelectedCharacterTemplateNames = NewTemplates;
	Encounter.Team = eTeam_Alien;
	return true;
}

/// Replace an alien-team pod with a same-sized pod from the faction that owns the mission's continent.
static function RewritePodForContinent(out PodSpawnInfo Encounter, name EncounterName, int ForceLevel, XComGameState_MissionSite MissionSite, string Context)
{
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Continent Continent;
	local FactionDef Def;
	local name FactionName;
	local array<name> NewTemplates;
	local string Before, After;
	local int i;

	if (!class'Astartes_FactionConfig'.default.bEnableContinentFactions || MissionSite == none)
	{
		return;
	}
	if (Encounter.Team != eTeam_Alien || Encounter.StrategyUnitTag != '' || Encounter.SelectedCharacterTemplateNames.Length == 0)
	{
		return;
	}
	if (class'Astartes_FactionConfig'.static.IsNeverRewritten(EncounterName))
	{
		`log("Astartes: leaving special encounter" @ EncounterName @ "untouched",, 'Astartes');
		return;
	}

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	Continent = MissionSite.GetContinent();
	if (Chapter == none || Continent == none)
	{
		return;
	}

	FactionName = Chapter.GetFactionForContinent(Continent.GetReference());
	if (FactionName == '' || !class'Astartes_FactionConfig'.static.GetFaction(FactionName, Def))
	{
		return;
	}
	if (!class'Astartes_FactionConfig'.static.IsFactionAvailable(Def))
	{
		`log("Astartes: faction" @ FactionName @ "owns" @ Continent.GetMyTemplateName() @ "but its spawn lists are not loaded (is" @ Def.RequiredDLC @ "enabled?). Leaving" @ Context @ "vanilla.",, 'Astartes');
		return;
	}

	if (!class'Astartes_FactionConfig'.static.BuildPod(Def, ForceLevel, Encounter.SelectedCharacterTemplateNames.Length, NewTemplates, class'Astartes_FactionConfig'.static.IsCommanderEncounter(EncounterName)))
	{
		`log("Astartes: faction" @ FactionName @ "has no eligible units at force level" @ ForceLevel @ "for" @ Context $ ". Leaving it vanilla.",, 'Astartes');
		return;
	}

	if (class'Astartes_FactionConfig'.default.bLogPodRewrites)
	{
		for (i = 0; i < Encounter.SelectedCharacterTemplateNames.Length; i++)
		{
			Before @= string(Encounter.SelectedCharacterTemplateNames[i]);
		}
		for (i = 0; i < NewTemplates.Length; i++)
		{
			After @= string(NewTemplates[i]);
		}
		`log("Astartes: PodRewrite" @ Context @ "on" @ Continent.GetMyTemplateName() @ "->" @ FactionName @ "FL" $ ForceLevel @ "[" $ Before @ "] => [" $ After @ "]",, 'Astartes');
	}

	Encounter.SelectedCharacterTemplateNames = NewTemplates;
}

/// Called when the player loads a saved game that was created without this mod.
static event OnLoadedSavedGame()
{
	`log("Astartes: loaded a save created without this mod",, 'Astartes');
}

/// Called when a save is loaded directly into the strategy layer. Repairs campaigns that predate the Chapter state.
static event OnLoadedSavedGameToStrategy()
{
	class'XComGameState_AstartesChapter'.static.EnsureChapterExists();
}

/// Called once all mods' templates exist. Use for edits that must run after every CreateTemplates.
static event OnPostTemplatesCreated()
{
	`log("Astartes: OnPostTemplatesCreated",, 'Astartes');
	class'Astartes_UnitVariants'.static.CreateVariants();
	// LWOTI: KevlarArmor is the Guard's flak armour again; the power armour bonus is part of the ascended physique.
	class'X2Item_AstartesWeapons'.static.CreateWeapons();
	class'Astartes_AbilityVariants'.static.CreateClones();
	class'Astartes_FactionConfig'.static.AddDaemonSpawns();
	class'X2Ability_Astartes_Assault'.static.RewireJumpVisuals();
	class'Astartes_NoHeroes'.static.Apply();
	class'Astartes_CharGen_Dressed'.static.HideMonsterParts();
	class'Astartes_GuardClasses'.static.Apply();
	class'X2Item_AstartesWeapons'.static.ApplyReskins();
}

/// Called when a mission is generated, after the faction mods have added their raid SitReps (we run after
/// them, see CHDLCRunOrder). On a continent we own, foreign raid SitReps are removed so pods stay pure.
static function PostSitRepCreation(out GeneratedMissionData GeneratedMission, optional XComGameState_BaseObject SourceObject)
{
	local XComGameState_MissionSite MissionSite;
	local XComGameState_AstartesChapter Chapter;
	local XComGameState_Continent Continent;
	local int i;

	if (!class'Astartes_FactionConfig'.default.bEnableContinentFactions)
	{
		return;
	}
	MissionSite = XComGameState_MissionSite(SourceObject);
	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (MissionSite == none || Chapter == none)
	{
		return;
	}
	Continent = MissionSite.GetContinent();
	if (Continent == none || Chapter.GetFactionForContinent(Continent.GetReference()) == '')
	{
		return;
	}

	for (i = GeneratedMission.SitReps.Length - 1; i >= 0; i--)
	{
		if (class'Astartes_FactionConfig'.default.ForeignRaidSitReps.Find(GeneratedMission.SitReps[i]) != INDEX_NONE)
		{
			`log("Astartes: removed foreign raid SitRep" @ GeneratedMission.SitReps[i] @ "from a mission on" @ Continent.GetMyTemplateName(),, 'Astartes');
			GeneratedMission.SitReps.Remove(i, 1);
		}
	}
}

// ---------------------------------------------------------------------------------------
// Recruit appearance (Highlander hook, issue #783)
// ---------------------------------------------------------------------------------------

/// Runs at the end of XGCharacterGenerator.CreateTSoldier, before it returns CharGen.kSoldier.
/// For Marines ('Soldier' template): enforce the gender policy, then dress them from the Marine armour packs.
static function ModifyGeneratedUnitAppearance(XGCharacterGenerator CharGen, const name CharacterTemplateName, const EGender eForceGender, const name nmCountry, const int iRace, const name ArmorName, XComGameState_Unit UnitState, XComGameState UseGameState)
{
	local EGender DesiredGender;
	local name DesiredCountry;

	// Chaos Cultists dress like the civilian militia: regenerate as that template. The nested call
	// re-enters this hook with 'CivilianMilitia', which falls through untouched.
	if (CharacterTemplateName == 'Astartes_Cultist')
	{
		CharGen.CreateTSoldier('CivilianMilitia', eForceGender, nmCountry, iRace, ArmorName);
		// Cultists are nameless heretics: the generated "Shane Dixon" becomes the unit label instead.
		CharGen.kSoldier.strFirstName = "";
		CharGen.kSoldier.strNickName = "";
		CharGen.kSoldier.strLastName = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Astartes_Cultist').strCharacterName;
		return;
	}

	if (default.RebelTemplates.Find(CharacterTemplateName) != INDEX_NONE)
	{
		DressRecruitAsGuard(CharGen);
		return;
	}
	if (CharacterTemplateName == 'Soldier' && default.bMarinesByAscension)
	{
		DressRecruitAsGuard(CharGen);
		return; // recruits are human Guardsmen; Marines are dressed when they ascend
	}
	if (CharacterTemplateName != 'Soldier')
	{
		return;
	}

	// Policy: Marines are male unless allowed otherwise, and belong to the campaign's Chapter (a country).
	DesiredGender = default.bAllowFemaleMarines ? EGender(CharGen.kSoldier.kAppearance.iGender) : eGender_Male;
	DesiredCountry = GetChapterCountry();
	if (DesiredCountry == '')
	{
		DesiredCountry = nmCountry;
	}

	if (CharGen.kSoldier.kAppearance.iGender != DesiredGender || nmCountry != DesiredCountry)
	{
		// Regenerate with the desired gender and country. The nested call re-enters this hook with
		// matching values, so it cannot recurse, and it applies livery + armour look itself.
		// CreateTSoldier returns kSoldier after this hook, so the regenerated soldier is what the caller gets.
		CharGen.CreateTSoldier(CharacterTemplateName, DesiredGender, DesiredCountry, iRace, ArmorName);
		return;
	}

	// Chapter-flag countries ship no name lists; fall back so Marines are not nameless.
	if (CharGen.kSoldier.strFirstName == "" && CharGen.kSoldier.strLastName == "" && default.NameFallbackCountry != '')
	{
		CharGen.GenerateName(CharGen.kSoldier.kAppearance.iGender, default.NameFallbackCountry, CharGen.kSoldier.strFirstName, CharGen.kSoldier.strLastName, CharGen.kSoldier.kAppearance.iRace);
	}

	ApplyChapterLivery(CharGen, DesiredCountry);
	ApplyMarineArmourLook(CharGen, ArmorName);
}

/// New recruits wear the Guard's armour (Cadian), whatever cosmetic packs are installed.
static function DressRecruitAsGuard(XGCharacterGenerator CharGen)
{
	local Astartes_CharGen_Dressed.DressedLook Look;
	local name LookName;
	local int i;

	LookName = EGender(CharGen.kSoldier.kAppearance.iGender) == eGender_Female ? default.RecruitLookFemale : default.RecruitLookMale;
	i = class'Astartes_CharGen_Dressed'.default.Looks.Find('Template', LookName);
	if (i == INDEX_NONE)
	{
		return;
	}
	Look = class'Astartes_CharGen_Dressed'.default.Looks[i];
	class'Astartes_CharGen_Dressed'.static.Dress(CharGen.kSoldier.kAppearance, Look);
}

/// The Chapter this campaign fights as: the Chapter state's choice if set, else the config default.
/// Returns '' if neither names a loaded country template (flag mod not installed).
static function name GetChapterCountry()
{
	local XComGameState_AstartesChapter Chapter;
	local name Country;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	Country = (Chapter != none && Chapter.ChapterCountry != '') ? Chapter.ChapterCountry : default.ChapterCountry;
	if (Country != '' && class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(Country) == none)
	{
		`log("Astartes: Chapter country" @ Country @ "is not a loaded country template (flag mod missing?). Using vanilla countries.",, 'Astartes');
		return '';
	}
	return Country;
}

/// Armour tints and pattern for a Chapter, from the ChapterLiveries config. No entry = leave the generator's colours.
static function ApplyChapterLivery(XGCharacterGenerator CharGen, name Country)
{
	local int i;

	for (i = 0; i < default.ChapterLiveries.Length; i++)
	{
		if (default.ChapterLiveries[i].Country == Country)
		{
			if (default.ChapterLiveries[i].PrimaryTint >= 0)
			{
				CharGen.kSoldier.kAppearance.iArmorTint = default.ChapterLiveries[i].PrimaryTint;
			}
			if (default.ChapterLiveries[i].SecondaryTint >= 0)
			{
				CharGen.kSoldier.kAppearance.iArmorTintSecondary = default.ChapterLiveries[i].SecondaryTint;
			}
			if (default.ChapterLiveries[i].Pattern != '')
			{
				CharGen.kSoldier.kAppearance.nmPatterns = default.ChapterLiveries[i].Pattern;
			}
			return;
		}
	}
}

/// Replace torso, arms, legs, deco and helmet with random parts from the configured Marine packs.
/// Leaves the vanilla look untouched when no pack is installed.
static function ApplyMarineArmourLook(XGCharacterGenerator CharGen, name ArmorName)
{
	local X2BodyPartTemplateManager PartMgr;
	local Astartes_BodyPartFilter Filter;
	local X2BodyPartTemplate Torso;
	local EGender Gender;
	local ECharacterRace Race;
	local name Helmet;

	if (default.MarineArmorPartPacks.Length == 0)
	{
		return;
	}

	if (ApplyTemplateLook(CharGen))
	{
		return;
	}

	PartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	Gender = EGender(CharGen.kSoldier.kAppearance.iGender);
	Race = ECharacterRace(CharGen.kSoldier.kAppearance.iRace);

	Filter = new class'Astartes_BodyPartFilter';
	Filter.RequiredPacks = default.MarineArmorPartPacks;
	Filter.RequiredNameKeywords = default.MarinePartNameKeywords;
	Filter.Set(Gender, Race, '', , , default.MarineArmorPartPacks);
	Filter.SetTorsoSelection('NoCharacterTemplateName', ArmorName == '' ? 'KevlarArmor' : ArmorName);

	Torso = PartMgr.GetRandomUberTemplate("Torso", Filter, Filter.FilterMarineTorso);
	if (Torso == none)
	{
		`log("Astartes: no Marine torso found for armour" @ ArmorName @ "- is the armour pack installed? Keeping vanilla look.",, 'Astartes');
		return;
	}
	CharGen.kSoldier.kAppearance.nmTorso = Torso.DataName;

	// Everything else must match the chosen torso's armour.
	Filter.Set(Gender, Race, Torso.DataName, false, false, default.MarineArmorPartPacks);

	CharGen.kSoldier.kAppearance.nmArms = PickMarinePart(PartMgr, Filter, "Arms");
	if (CharGen.kSoldier.kAppearance.nmArms == '')
	{
		CharGen.kSoldier.kAppearance.nmLeftArm = PickMarinePart(PartMgr, Filter, "LeftArm");
		CharGen.kSoldier.kAppearance.nmRightArm = PickMarinePart(PartMgr, Filter, "RightArm");
		CharGen.kSoldier.kAppearance.nmLeftArmDeco = PickMarinePart(PartMgr, Filter, "LeftArmDeco");
		CharGen.kSoldier.kAppearance.nmRightArmDeco = PickMarinePart(PartMgr, Filter, "RightArmDeco");
	}
	else
	{
		CharGen.kSoldier.kAppearance.nmLeftArm = '';
		CharGen.kSoldier.kAppearance.nmRightArm = '';
		CharGen.kSoldier.kAppearance.nmLeftArmDeco = '';
		CharGen.kSoldier.kAppearance.nmRightArmDeco = '';
	}
	CharGen.kSoldier.kAppearance.nmLegs = PickMarinePart(PartMgr, Filter, "Legs");
	CharGen.kSoldier.kAppearance.nmThighs = PickMarinePart(PartMgr, Filter, "Thighs");
	CharGen.kSoldier.kAppearance.nmShins = PickMarinePart(PartMgr, Filter, "Shins");
	CharGen.kSoldier.kAppearance.nmTorsoDeco = PickMarinePart(PartMgr, Filter, "TorsoDeco");
	CharGen.kSoldier.kAppearance.nmLeftForearm = PickMarinePart(PartMgr, Filter, "LeftForearm");
	CharGen.kSoldier.kAppearance.nmRightForearm = PickMarinePart(PartMgr, Filter, "RightForearm");

	// Marines fight helmeted. Helmets are not bound to an armour tier, so match on pack + gender only.
	Helmet = PickMarineAnyPart(PartMgr, Filter, "Helmets");
	if (Helmet != '')
	{
		CharGen.kSoldier.kAppearance.nmHelmet = Helmet;
	}
}

/// Copy the armour parts of a character-pool template Marine (MarineLookTemplates). Tints, pattern, head, hair and
/// everything personal stay as generated. Returns false when no template is configured or found.
static function bool ApplyTemplateLook(XGCharacterGenerator CharGen)
{
	local CharacterPoolManager Pool;
	local XComGameState_Unit Model;
	local array<string> Names;
	local string Picked;
	local TAppearance T;

	if (default.MarineLookTemplates.Length == 0)
	{
		return false;
	}
	Pool = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	if (Pool == none)
	{
		return false;
	}
	Names = default.MarineLookTemplates;
	while (Names.Length > 0 && Model == none)
	{
		Picked = Names[`SYNC_RAND_STATIC(Names.Length)];
		Model = Pool.GetCharacter(Picked);
		Names.RemoveItem(Picked);
	}
	if (Model == none)
	{
		return ApplyConfiguredLook(CharGen);
	}
	T = Model.kAppearance;
	CharGen.kSoldier.kAppearance.nmTorso = T.nmTorso;
	CharGen.kSoldier.kAppearance.nmArms = T.nmArms;
	CharGen.kSoldier.kAppearance.nmLeftArm = T.nmLeftArm;
	CharGen.kSoldier.kAppearance.nmRightArm = T.nmRightArm;
	CharGen.kSoldier.kAppearance.nmLeftArmDeco = T.nmLeftArmDeco;
	CharGen.kSoldier.kAppearance.nmRightArmDeco = T.nmRightArmDeco;
	CharGen.kSoldier.kAppearance.nmLeftForearm = T.nmLeftForearm;
	CharGen.kSoldier.kAppearance.nmRightForearm = T.nmRightForearm;
	CharGen.kSoldier.kAppearance.nmLegs = T.nmLegs;
	CharGen.kSoldier.kAppearance.nmThighs = T.nmThighs;
	CharGen.kSoldier.kAppearance.nmShins = T.nmShins;
	CharGen.kSoldier.kAppearance.nmTorsoDeco = T.nmTorsoDeco;
	CharGen.kSoldier.kAppearance.nmHelmet = T.nmHelmet;
	`log("Astartes: Marine look copied from pool template" @ Picked,, 'Astartes');
	return true;
}

/// The shipped look (MarineLookParts): used when the pool template is absent. Returns false if none is configured.
static function bool ApplyConfiguredLook(XGCharacterGenerator CharGen)
{
	local MarineLook L;

	if (default.MarineLookParts.Length == 0 || default.MarineLookParts[0].nmTorso == '')
	{
		`log("Astartes: no pool template and no MarineLookParts; picking parts at random",, 'Astartes');
		return false;
	}
	L = default.MarineLookParts[`SYNC_RAND_STATIC(default.MarineLookParts.Length)];
	CharGen.kSoldier.kAppearance.nmTorso = L.nmTorso;
	CharGen.kSoldier.kAppearance.nmArms = L.nmArms;
	CharGen.kSoldier.kAppearance.nmLeftArm = L.nmLeftArm;
	CharGen.kSoldier.kAppearance.nmRightArm = L.nmRightArm;
	CharGen.kSoldier.kAppearance.nmLeftArmDeco = L.nmLeftArmDeco;
	CharGen.kSoldier.kAppearance.nmRightArmDeco = L.nmRightArmDeco;
	CharGen.kSoldier.kAppearance.nmLeftForearm = L.nmLeftForearm;
	CharGen.kSoldier.kAppearance.nmRightForearm = L.nmRightForearm;
	CharGen.kSoldier.kAppearance.nmLegs = L.nmLegs;
	CharGen.kSoldier.kAppearance.nmThighs = L.nmThighs;
	CharGen.kSoldier.kAppearance.nmShins = L.nmShins;
	CharGen.kSoldier.kAppearance.nmTorsoDeco = L.nmTorsoDeco;
	CharGen.kSoldier.kAppearance.nmHelmet = L.nmHelmet;
	`log("Astartes: Marine look applied from MarineLookParts",, 'Astartes');
	return true;
}

/// A part matching the chosen torso's armour tier; falls back to any part from the Marine packs.
static function name PickMarinePart(X2BodyPartTemplateManager PartMgr, Astartes_BodyPartFilter Filter, string PartType)
{
	local X2BodyPartTemplate Part;

	Part = PartMgr.GetRandomUberTemplate(PartType, Filter, Filter.FilterMarinePart);
	if (Part == none)
	{
		Part = PartMgr.GetRandomUberTemplate(PartType, Filter, Filter.FilterMarineAny);
	}
	return Part == none ? '' : Part.DataName;
}

static function name PickMarineAnyPart(X2BodyPartTemplateManager PartMgr, Astartes_BodyPartFilter Filter, string PartType)
{
	local X2BodyPartTemplate Part;

	Part = PartMgr.GetRandomUberTemplate(PartType, Filter, Filter.FilterMarineAny);
	return Part == none ? '' : Part.DataName;
}


/// Log a line and echo it to the in-game console, so dev commands give visible feedback.
static function Say(string Msg)
{
	local Engine Eng;

	`log(Msg,, 'Astartes');
	Eng = class'Engine'.static.GetEngine();
	if (Eng != none && Eng.GameViewport != none && Eng.GameViewport.ViewportConsole != none)
	{
		Eng.GameViewport.ViewportConsole.OutputText(Msg);
	}
}

// ---------------------------------------------------------------------------------------
// Developer console commands. Require -allowConsole. Strategy layer only unless noted.
// Each logs a line starting "Astartes_<Command>: PASS" or "FAIL" so a log parser can assert on it.
// ---------------------------------------------------------------------------------------

/// Astartes_DevSquad [Ranks]
/// Adds one soldier of every Marine class to the barracks, promoted to the given rank (default: max),
/// with squaddie loadout and the best gear available. Nicknames them after their class.
exec function Astartes_DevSquad(optional int Ranks = -1)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassName;
	local int MaxRank, i, Created;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ == none)
	{
		Say("Astartes_DevSquad: FAIL no XComHQ (strategy layer only)");
		return;
	}

	MaxRank = class'X2ExperienceConfig'.static.GetMaxRank();
	if (Ranks < 1 || Ranks > MaxRank)
	{
		Ranks = MaxRank;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: DevSquad");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	foreach default.MarineClasses(ClassName)
	{
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
		if (ClassTemplate == none)
		{
			Say("Astartes_DevSquad: FAIL unknown class" @ ClassName);
			continue;
		}

		UnitState = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, 'Soldier', '', true);
		UnitState.ResetSoldierRank();
		UnitState.ResetSoldierAbilities();

		for (i = 0; i < Ranks; i++)
		{
			UnitState.RankUpSoldier(NewGameState, i == 0 ? ClassName : '');
			if (UnitState.GetRank() == 1)
			{
				UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
			}
		}
		UnitState.ApplyBestGearLoadout(NewGameState);
		UnitState.SetCharacterName(UnitState.GetFirstName(), UnitState.GetLastName(), ClassTemplate.DisplayName);
		UnitState.SetStatus(eStatus_Active);

		XComHQ.AddToCrew(NewGameState, UnitState);
		Created++;
		Say("Astartes_DevSquad: created" @ UnitState.GetFullName() @ "as" @ ClassName @ "rank" @ UnitState.GetRank());
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	Say("Astartes_DevSquad: PASS created" @ Created @ "of" @ default.MarineClasses.Length);
}

/// Astartes_ListClasses
/// Logs every soldier class template this mod registered and how many ranks it has.
exec function Astartes_ListClasses()
{
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassName;

	foreach default.MarineClasses(ClassName)
	{
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
		if (ClassTemplate == none)
		{
			Say("Astartes_ListClasses: FAIL missing" @ ClassName);
		}
		else
		{
			Say("Astartes_ListClasses: PASS" @ ClassName @ "ranks=" $ ClassTemplate.GetMaxConfiguredRank() @ "display=" $ ClassTemplate.DisplayName);
		}
	}
}

/// Astartes_Geneseed [NewAmount]
/// Logs the Chapter's geneseed pool; with an argument, sets it. Works in strategy and tactical.
exec function Astartes_Geneseed(optional int NewAmount = -1)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none)
	{
		Say("Astartes_Geneseed: FAIL no Chapter state in this campaign");
		return;
	}

	if (NewAmount >= 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set geneseed");
		Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
		Chapter.Geneseed = NewAmount;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	Say("Astartes_Geneseed: PASS geneseed=" $ Chapter.Geneseed @ "recovered_total=" $ Chapter.GeneseedRecoveredTotal @ "fallen=" $ Chapter.BrothersFallen);
}

/// Astartes_Factions
/// Logs which faction owns each continent and whether that faction's spawn lists are loaded.
exec function Astartes_Factions()
{
	local XComGameState_AstartesChapter Chapter;
	local FactionDef Def;
	local int i;
	local string Status;

	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none || Chapter.ContinentFactions.Length == 0)
	{
		// Campaign predates this feature (or the strategy-load repair did not run): deal factions now.
		class'XComGameState_AstartesChapter'.static.EnsureChapterExists();
		Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	}
	if (Chapter == none || Chapter.ContinentFactions.Length == 0)
	{
		Say("Astartes_Factions: FAIL could not assign continent factions (are any factions configured?)");
		return;
	}
	for (i = 0; i < Chapter.ContinentFactions.Length; i++)
	{
		Status = "unknown faction";
		if (class'Astartes_FactionConfig'.static.GetFaction(Chapter.ContinentFactions[i].FactionName, Def))
		{
			Status = class'Astartes_FactionConfig'.static.IsFactionAvailable(Def) ? "lists loaded" : ("lists MISSING - enable" @ Def.RequiredDLC);
		}
		Say("Astartes_Factions: PASS" @ Chapter.ContinentFactions[i].ContinentTemplate @ "->" @ Chapter.ContinentFactions[i].FactionName @ "(" $ Status $ ")");
	}
}

/// Astartes_AssignFactions
/// (Re)deals factions to continents. Use on a campaign that predates this feature, or to re-roll.
exec function Astartes_AssignFactions()
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: assign factions");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.AssignContinentFactions(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_AssignFactions: PASS assigned" @ Chapter.ContinentFactions.Length @ "continents");
}

/// Astartes_SetContinentFaction <ContinentTemplate> <FactionName>
/// e.g. Astartes_SetContinentFaction Continent_NorthAmerica Orks
exec function Astartes_SetContinentFaction(string ContinentTemplateStr, string FactionNameStr)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;
	local FactionDef Def;
	local name ContinentTemplate, FactionName;

	// The console cannot parse 'name' parameters; take strings and convert.
	ContinentTemplate = name(ContinentTemplateStr);
	FactionName = name(FactionNameStr);

	if (!class'Astartes_FactionConfig'.static.GetFaction(FactionName, Def))
	{
		Say("Astartes_SetContinentFaction: FAIL unknown faction" @ FactionName);
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set continent faction");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	if (!Chapter.SetFactionForContinent(ContinentTemplate, FactionName))
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		Say("Astartes_SetContinentFaction: FAIL unknown continent" @ ContinentTemplate);
		return;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_SetContinentFaction: PASS" @ ContinentTemplate @ "->" @ FactionName);
}

/// Astartes_Variants
/// Logs every configured unit variant: created (with HP) or skipped because its base mod is off.
exec function Astartes_Variants()
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate T;
	local int i;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	T = CharMgr.FindCharacterTemplate('Astartes_Cultist');
	Say("Astartes_Variants:" @ (T != none ? "PASS" : "FAIL") @ "Astartes_Cultist" @ (T != none ? ("HP=" $ T.CharacterBaseStats[eStat_HP]) : "missing"));
	for (i = 0; i < class'Astartes_UnitVariants'.default.Variants.Length; i++)
	{
		T = CharMgr.FindCharacterTemplate(class'Astartes_UnitVariants'.default.Variants[i].NewName);
		if (T == none)
		{
			Say("Astartes_Variants: FAIL" @ class'Astartes_UnitVariants'.default.Variants[i].NewName @ "not created (base" @ class'Astartes_UnitVariants'.default.Variants[i].BaseTemplate @ "loaded?)");
		}
		else
		{
			Say("Astartes_Variants: PASS" @ T.DataName @ "from" @ class'Astartes_UnitVariants'.default.Variants[i].BaseTemplate @ "HP=" $ T.CharacterBaseStats[eStat_HP] @ "armor=" $ T.CharacterBaseStats[eStat_ArmorMitigation] @ "appearanceDefinesPawn=" $ T.bAppearanceDefinesPawn @ "generator=" $ (T.CharacterGeneratorClass != none ? string(T.CharacterGeneratorClass.Name) : "none") @ "pawns=" $ T.strPawnArchetypes.Length);
		}
	}
}

/// Astartes_PartPacks
/// Lists the body-part packs the game knows about and how many male Kevlar-tier torsos each has.
/// Use to check that an armour pack (e.g. SM2Tacticus) is actually loaded.
exec function Astartes_PartPacks()
{
	local X2BodyPartTemplateManager PartMgr;
	local array<name> Packs;
	local array<X2BodyPartTemplate> Torsos;
	local name Pack;
	local int i, Count, Configured;

	PartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	Packs = PartMgr.GetPartPackNames();
	PartMgr.GetUberTemplates("Torso", Torsos);
	Say("Astartes_PartPacks: PASS" @ Packs.Length @ "packs," @ Torsos.Length @ "torsos total");
	foreach Packs(Pack)
	{
		Count = 0;
		for (i = 0; i < Torsos.Length; i++)
		{
			if (Torsos[i].DLCName == Pack && Torsos[i].Gender == eGender_Male && Torsos[i].ArmorTemplate == 'KevlarArmor')
			{
				Count++;
			}
		}
		Configured = default.MarineArmorPartPacks.Find(Pack) != INDEX_NONE ? 1 : 0;
		Say("Astartes_PartPacks:   " $ Pack @ "male kevlar torsos=" $ Count @ (Configured == 1 ? "<- Marine look pack" : ""));
	}
	foreach default.MarineArmorPartPacks(Pack)
	{
		if (Packs.Find(Pack) == INDEX_NONE)
		{
			Say("Astartes_PartPacks: FAIL configured Marine pack" @ Pack @ "is not loaded (enable its mod in AML)");
		}
	}
}

/// Astartes_Chapter <Country_Name>
/// Sets the campaign's Chapter (e.g. Astartes_Chapter Country_BloodAngels) and redresses the barracks.
exec function Astartes_Chapter(string CountryStr)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;
	local name Country;

	Country = name(CountryStr);
	if (class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(Country) == none)
	{
		Say("Astartes_Chapter: FAIL unknown country template" @ Country @ "(is its flag mod enabled?)");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set Chapter");
	Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
	Chapter.ChapterCountry = Country;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_Chapter: PASS Chapter is now" @ Country);
	Astartes_Redress();
}

/// Astartes_Livery <PrimaryTint> <SecondaryTint> [Pattern]
/// Applies armour tints to every barracks soldier right now, for tuning ChapterLiveries values by eye.
exec function Astartes_Livery(int PrimaryTint, optional int SecondaryTint = -1, optional string PatternStr)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local TAppearance Appearance;
	local int idx, Count;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ == none)
	{
		Say("Astartes_Livery: FAIL no XComHQ");
		return;
	}
	if (SecondaryTint < 0)
	{
		SecondaryTint = PrimaryTint; // one colour on both channels = uniform Chapter livery
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: Livery");
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
		if (UnitState == none || !UnitState.IsSoldier() || UnitState.GetMyTemplateName() != 'Soldier')
		{
			continue;
		}
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		Appearance = UnitState.kAppearance;
		Appearance.iArmorTint = PrimaryTint;
		Appearance.iArmorTintSecondary = SecondaryTint;
		if (PatternStr != "")
		{
			Appearance.nmPatterns = name(PatternStr);
		}
		UnitState.SetTAppearance(Appearance);
		UnitState.StoreAppearance();
		Count++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_Livery: PASS tints" @ PrimaryTint $ "/" $ SecondaryTint @ "applied to" @ Count @ "soldiers");
}

/// Astartes_Redress
/// Re-rolls every barracks soldier's appearance through the Marine generator (gender policy + armour packs).
/// Use after enabling an armour pack mid-campaign.
exec function Astartes_Redress()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XGCharacterGenerator CharGen;
	local TSoldier Generated;
	local int idx, Count;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ == none)
	{
		Say("Astartes_Redress: FAIL no XComHQ");
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: Redress");
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
		if (UnitState == none || !UnitState.IsSoldier() || UnitState.GetMyTemplateName() != 'Soldier')
		{
			continue;
		}
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		CharGen = `XCOMGRI.Spawn(UnitState.GetMyTemplate().CharacterGeneratorClass);
		Generated = CharGen.CreateTSoldierFromUnit(UnitState, NewGameState);
		UnitState.SetTAppearance(Generated.kAppearance);
		if (Generated.nmCountry != '')
		{
			UnitState.SetCountry(Generated.nmCountry); // the Chapter: flag follows the livery
		}
		UnitState.StoreAppearance();
		CharGen.Destroy();
		Count++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_Redress: PASS redressed" @ Count @ "soldiers");
}

/// Astartes_ForcePerils [WarpSurge|Backlash|WarpShock|MentalPurge|Possession]
/// The next psychic power any Librarian casts suffers Perils of the Warp with this outcome. No argument = normal rolls.
exec function Astartes_ForcePerils(optional string Outcome)
{
	local name OutcomeName;

	if (Outcome == "")
	{
		class'X2Ability_Astartes_Librarian'.default.ForcedPerilsOutcome = '';
		Say("Astartes_ForcePerils: PASS back to normal Perils rolls");
		return;
	}
	OutcomeName = name("Astartes_Perils_" $ Outcome);
	if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(OutcomeName) == none)
	{
		Say("Astartes_ForcePerils: FAIL unknown outcome" @ Outcome @ "(WarpSurge, Backlash, WarpShock, MentalPurge, Possession)");
		return;
	}
	class'X2Ability_Astartes_Librarian'.default.ForcedPerilsOutcome = OutcomeName;
	Say("Astartes_ForcePerils: PASS the next psychic power triggers" @ OutcomeName);
}

/// Astartes_AP [Points]: give every barracks soldier this many unspent ability points (default 100), so every
/// promotion choice can be bought for testing. Also tops up the shared XCOM pool.
exec function Astartes_AP(optional int Points = 100)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local int i, Count;

	XComHQ = `XCOMHQ;
	if (XComHQ == none)
	{
		Say("Astartes_AP: FAIL no XComHQ (strategy layer only)");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: ability points");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.AddResource(NewGameState, 'AbilityPoint', Points); // the shared pool is a resource item
	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (UnitState == none || !UnitState.IsSoldier())
		{
			continue;
		}
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		UnitState.AbilityPoints = Max(UnitState.AbilityPoints, Points);
		Count++;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_AP: PASS" @ Count @ "soldiers have at least" @ Points @ "ability points; XCOM pool now" @ XComHQ.GetAbilityPoints());
}

/// Astartes_SquadSize <4|5|6>: set the squad cap by granting or removing the Guerrilla Tactics School squad-size unlocks.
exec function Astartes_SquadSize(int Size)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local X2SoldierUnlockTemplate Unlock;

	XComHQ = `XCOMHQ;
	if (XComHQ == none)
	{
		Say("Astartes_SquadSize: FAIL no XComHQ (strategy layer only)");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: squad size");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	XComHQ.RemoveSoldierUnlockTemplate('SquadSizeIUnlock');
	XComHQ.RemoveSoldierUnlockTemplate('SquadSizeIIUnlock');
	if (Size >= 5)
	{
		Unlock = X2SoldierUnlockTemplate(StratMgr.FindStrategyElementTemplate('SquadSizeIUnlock'));
		XComHQ.AddSoldierUnlockTemplate(NewGameState, Unlock, true);
	}
	if (Size >= 6)
	{
		Unlock = X2SoldierUnlockTemplate(StratMgr.FindStrategyElementTemplate('SquadSizeIIUnlock'));
		XComHQ.AddSoldierUnlockTemplate(NewGameState, Unlock, true);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_SquadSize: PASS squad cap is now" @ Clamp(Size, 4, 6) @ "(takes effect at the next squad select)");
}

/// Astartes_Appoint <Seat> [NameFragment]: appoint a Marine to a unique seat (ChapterMaster, ChiefLibrarian,
/// MasterOfSanctity). Picks the soldier whose name contains the fragment, or the first eligible one.
exec function Astartes_Appoint(string Seat, optional string NameFragment)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Pick;
	local string Reason;
	local name SeatName;

	SeatName = name(Seat);
	if (`XCOMHQ == none)
	{
		Say("Astartes_Appoint: FAIL no XComHQ (strategy layer only)");
		return;
	}
	Pick = class'Astartes_ChapterMaster'.static.FindCandidate(SeatName, NameFragment);
	if (Pick == none)
	{
		Say("Astartes_Appoint: FAIL no eligible soldier for" @ Seat @ (NameFragment != "" ? "named like" @ NameFragment : ""));
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: appoint" @ Seat);
	if (!class'Astartes_ChapterMaster'.static.AppointToSeat(SeatName, Pick, NewGameState, Reason))
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		Say("Astartes_Appoint: FAIL" @ Pick.GetFullName() $ ":" @ Reason);
		return;
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_Appoint: PASS" @ Pick.GetFullName() @ "is now" @ Seat);
}

exec function Astartes_AppointCommander(optional string NameFragment) { Astartes_Appoint("ChapterMaster", NameFragment); }
exec function Astartes_AppointChiefLibrarian(optional string NameFragment) { Astartes_Appoint("ChiefLibrarian", NameFragment); }
exec function Astartes_AppointMasterOfSanctity(optional string NameFragment) { Astartes_Appoint("MasterOfSanctity", NameFragment); }

/// Astartes_ExportLook <Pool soldier name>: prints that character's armour parts as a +MarineLookParts config line,
/// ready to paste into XComGame.ini so the look ships with the mod.
exec function Astartes_ExportLook(string PoolName)
{
	local CharacterPoolManager Pool;
	local XComGameState_Unit Model;
	local TAppearance T;

	Pool = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	Model = Pool == none ? none : Pool.GetCharacter(PoolName);
	if (Model == none)
	{
		Say("Astartes_ExportLook: FAIL no pool character named" @ PoolName);
		return;
	}
	T = Model.kAppearance;
	Say("Astartes_ExportLook: PASS paste into [Astartes.X2DownloadableContentInfo_Astartes]:");
	Say("+MarineLookParts=(" $ "nmTorso=\"" $ T.nmTorso $ "\"" $ ", " $ "nmArms=\"" $ T.nmArms $ "\"" $ ", " $ "nmLeftArm=\"" $ T.nmLeftArm $ "\"" $ ", " $ "nmRightArm=\"" $ T.nmRightArm $ "\"" $ ", " $ "nmLeftArmDeco=\"" $ T.nmLeftArmDeco $ "\"" $ ", " $ "nmRightArmDeco=\"" $ T.nmRightArmDeco $ "\"" $ ", " $ "nmLeftForearm=\"" $ T.nmLeftForearm $ "\"" $ ", " $ "nmRightForearm=\"" $ T.nmRightForearm $ "\"" $ ", " $ "nmLegs=\"" $ T.nmLegs $ "\"" $ ", " $ "nmThighs=\"" $ T.nmThighs $ "\"" $ ", " $ "nmShins=\"" $ T.nmShins $ "\"" $ ", " $ "nmTorsoDeco=\"" $ T.nmTorsoDeco $ "\"" $ ", " $ "nmHelmet=\"" $ T.nmHelmet $ "\"" $ ")");
}

/// Astartes_JumpThrusters <back> <side> <up> [bone]: moves the jump-pack flames live for tuning (no restart). Offsets
/// are in the bone's frame; the two thrusters mirror on <side>. With a bone name, that bone is tried first. Prints the
/// config lines to paste once the flames sit right. Astartes_JumpThrusters with no numbers prints the current values.
exec function Astartes_JumpThrusters(optional float Back = 0, optional float Side = 0, optional float Up = 0, optional string Bone = "")
{
	local int i;
	local vector Offset;

	for (i = 0; i < class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS.Length; i++)
	{
		if (Back != 0 || Side != 0 || Up != 0)
		{
			Offset.X = Back;
			Offset.Y = (i % 2 == 0 ? -1 : 1) * Side;
			Offset.Z = Up;
			class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].Offset = Offset;
		}
		Say("+JUMP_THRUSTERS=(FX=\"" $ class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].FX $ "\", Offset=(X=" $ class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].Offset.X
			$ ", Y=" $ class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].Offset.Y $ ", Z=" $ class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].Offset.Z $ "))");
	}
	if (Bone != "")
	{
		class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTER_BONES.InsertItem(0, name(Bone));
	}
	for (i = 0; i < class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTER_BONES.Length; i++)
	{
		Say("+JUMP_THRUSTER_BONES=\"" $ class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTER_BONES[i] $ "\"");
	}
	Say("Astartes_JumpThrusters: PASS jump again to see the flames there");
}

/// Astartes_Taint [Amount]: prints the Chapter's Taint and judgement state; with an amount, sets Taint (testing the
/// Inquisition: set it to the threshold, then open the geoscape or the Avenger view to be judged).
exec function Astartes_Taint(optional int Amount = -1)
{
	local XComGameState NewGameState;
	local XComGameState_AstartesChapter Chapter;

	if (Amount >= 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: set Taint");
		Chapter = class'XComGameState_AstartesChapter'.static.GetOrCreateChapter(NewGameState);
		Chapter.Taint = Amount;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	Chapter = class'XComGameState_AstartesChapter'.static.GetChapter(true);
	if (Chapter == none)
	{
		Say("Astartes_Taint: FAIL no Chapter state");
		return;
	}
	Say("Astartes_Taint: PASS Taint" @ Chapter.Taint @ "judgement at" @ class'Astartes_Inquisition'.static.JudgementThreshold(Chapter)
		@ "Inquisitor joined=" $ Chapter.bInquisitorJoined @ "hostile=" $ Chapter.bInquisitionHostile);
}

/// Astartes_GiveHero <Canoness|Commissar>: in the Avenger, adds that Imperial hero to the barracks at a rank fit for the
/// campaign's progress, as a faction contact would. For testing the hero classes without waiting for the reward.
exec function Astartes_GiveHero(string Which)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local name CharName;

	CharName = name("Astartes_" $ Which);
	if (class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharName) == none)
	{
		Say("Astartes_GiveHero: FAIL no character" @ CharName @ "(try Canoness or Commissar)");
		return;
	}
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astartes: give hero");
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	Unit = class'X2StrategyElement_DefaultRewards'.static.CreatePersonnelUnit(NewGameState, CharName, '', false);
	XComHQ.AddToCrew(NewGameState, Unit);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	Say("Astartes_GiveHero: PASS" @ Unit.GetFullName() @ "joins as" @ Unit.GetSoldierClassTemplateName() @ "rank" @ Unit.GetRank());
}
