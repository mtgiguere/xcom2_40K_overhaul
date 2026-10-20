//---------------------------------------------------------------------------------------
//  FILE:    Astartes_UnitVariants.uc
//  PURPOSE: Clone another mod's character template into one of ours with our own stats, so
//           early-game lists can use e.g. a weak Genestealer Cult hybrid without touching
//           The Hive's balance. Runs in OnPostTemplatesCreated because the base templates
//           belong to other mods. Stats come from [NewName X2CharacterTemplate] in
//           XComGameData_CharacterStats.ini (PerObjectConfig loads them by object name).
//---------------------------------------------------------------------------------------
class Astartes_UnitVariants extends Object config(Astartes);

struct UnitVariant
{
	var name NewName;          // our template name, e.g. Astartes_CultHybrid
	var name BaseTemplate;     // template to copy, e.g. ChrysHybrid (The Hive)
	var name LoadoutOverride;  // optional: different DefaultLoadout
	var name CharacterGroup;   // optional: different CharacterGroupName (for AI / target icons)
	var string BehaviorTree;   // optional: different AI root (XComAI.ini), e.g. Astartes_ChaosSorcerer::CharacterRoot
	var array<name> ExtraAbilities; // added to the base's abilities when their templates exist
	var array<name> RemoveAbilities; // base abilities left off the variant
	var bool bAppearanceDefinesPawn; // soldier body dressed in cosmetic parts (pawn from the appearance, not the base's archetype)
	var string CharacterGenerator;   // optional: generator class path, e.g. Astartes.Astartes_CharGen_Dressed
	var name DefaultSoldierClass;    // optional: the class this soldier is created as (faction heroes)
};

var config array<UnitVariant> Variants;

/// Create every configured variant whose base template is loaded. Safe to call once per template init.
static function CreateVariants()
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate Base, Clone;
	local UnitVariant Def;
	local int i, Created;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	for (i = 0; i < default.Variants.Length; i++)
	{
		if (CharMgr.FindCharacterTemplate(default.Variants[i].NewName) != none)
		{
			continue; // already created (template init can run more than once)
		}
		Base = CharMgr.FindCharacterTemplate(default.Variants[i].BaseTemplate);
		if (Base == none)
		{
			`log("Astartes: variant" @ default.Variants[i].NewName @ "skipped: base template" @ default.Variants[i].BaseTemplate @ "is not loaded",, 'Astartes');
			continue;
		}
		Def = default.Variants[i];
		Clone = CloneTemplate(Base, Def);
		CharMgr.AddCharacterTemplate(Clone, true);
		Created++;
		`log("Astartes: variant" @ Clone.DataName @ "created from" @ Base.DataName @ "HP=" $ Clone.CharacterBaseStats[eStat_HP] @ "appearanceDefinesPawn=" $ Clone.bAppearanceDefinesPawn @ "generator=" $ (Clone.CharacterGeneratorClass != none ? string(Clone.CharacterGeneratorClass.Name) : "none"),, 'Astartes');
	}
	`log("Astartes: unit variants created:" @ Created @ "of" @ default.Variants.Length,, 'Astartes');
}

/// New template named Def.NewName (which loads our config stats), with the base's look, loadout,
/// behaviour and flags copied over. Stats are NOT copied: ours come from config.
static function X2CharacterTemplate CloneTemplate(X2CharacterTemplate Base, const out UnitVariant Def)
{
	local X2CharacterTemplate T;
	local class<XGCharacterGenerator> GenClass;
	local int i;

	`CREATE_X2CHARACTER_TEMPLATE(T, Def.NewName);

	T.CharacterGroupName = Def.CharacterGroup != '' ? Def.CharacterGroup : Base.CharacterGroupName;
	T.DefaultLoadout = Def.LoadoutOverride != '' ? Def.LoadoutOverride : Base.DefaultLoadout;
	T.DefaultSoldierClass = Def.DefaultSoldierClass != '' ? Def.DefaultSoldierClass : Base.DefaultSoldierClass;
	T.BehaviorClass = Base.BehaviorClass;
	T.strBehaviorTree = Def.BehaviorTree != "" ? Def.BehaviorTree : Base.strBehaviorTree;
	T.strScamperBT = Base.strScamperBT;
	T.CharacterGeneratorClass = Base.CharacterGeneratorClass;
	if (Def.CharacterGenerator != "")
	{
		GenClass = class<XGCharacterGenerator>(DynamicLoadObject(Def.CharacterGenerator, class'Class'));
		if (GenClass != none)
		{
			T.CharacterGeneratorClass = GenClass;
		}
		else
		{
			`log("Astartes: variant" @ Def.NewName @ "generator" @ Def.CharacterGenerator @ "not found; using the base's",, 'Astartes');
		}
	}

	for (i = 0; i < Base.strPawnArchetypes.Length; i++)
	{
		T.strPawnArchetypes.AddItem(Base.strPawnArchetypes[i]);
	}
	for (i = 0; i < Base.Abilities.Length; i++)
	{
		if (Def.RemoveAbilities.Find(Base.Abilities[i]) == INDEX_NONE)
		{
			T.Abilities.AddItem(Base.Abilities[i]);
		}
	}
	for (i = 0; i < Def.ExtraAbilities.Length; i++)
	{
		if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Def.ExtraAbilities[i]) == none)
		{
			`log("Astartes: variant" @ Def.NewName @ "skips ability" @ Def.ExtraAbilities[i] @ "(template not loaded)",, 'Astartes');
			continue;
		}
		T.Abilities.AddItem(Def.ExtraAbilities[i]);
	}
	for (i = 0; i < Base.strMatineePackages.Length; i++)
	{
		T.strMatineePackages.AddItem(Base.strMatineePackages[i]);
	}
	T.RevealMatineePrefix = Base.RevealMatineePrefix;
	T.GetRevealMatineePrefixFn = Base.GetRevealMatineePrefixFn;
	T.strTargetingMatineePrefix = Base.strTargetingMatineePrefix;
	T.strTargetIconImage = Base.strTargetIconImage;
	T.DefaultAppearance = Base.DefaultAppearance;
	T.ForceAppearance = Base.ForceAppearance;
	T.bForceAppearance = Base.bForceAppearance;
	T.bAppearanceDefinesPawn = Base.bAppearanceDefinesPawn;
	T.bSetGenderAlways = Base.bSetGenderAlways;

	T.UnitSize = Base.UnitSize;
	T.UnitHeight = Base.UnitHeight;
	T.KillContribution = Base.KillContribution;

	T.bCanUse_eTraversal_Normal = Base.bCanUse_eTraversal_Normal;
	T.bCanUse_eTraversal_ClimbOver = Base.bCanUse_eTraversal_ClimbOver;
	T.bCanUse_eTraversal_ClimbOnto = Base.bCanUse_eTraversal_ClimbOnto;
	T.bCanUse_eTraversal_ClimbLadder = Base.bCanUse_eTraversal_ClimbLadder;
	T.bCanUse_eTraversal_DropDown = Base.bCanUse_eTraversal_DropDown;
	T.bCanUse_eTraversal_Grapple = Base.bCanUse_eTraversal_Grapple;
	T.bCanUse_eTraversal_Landing = Base.bCanUse_eTraversal_Landing;
	T.bCanUse_eTraversal_BreakWindow = Base.bCanUse_eTraversal_BreakWindow;
	T.bCanUse_eTraversal_KickDoor = Base.bCanUse_eTraversal_KickDoor;
	T.bCanUse_eTraversal_JumpUp = Base.bCanUse_eTraversal_JumpUp;
	T.bCanUse_eTraversal_WallClimb = Base.bCanUse_eTraversal_WallClimb;
	T.bCanUse_eTraversal_Phasing = Base.bCanUse_eTraversal_Phasing;
	T.bCanUse_eTraversal_BreakWall = Base.bCanUse_eTraversal_BreakWall;
	T.bCanUse_eTraversal_Launch = Base.bCanUse_eTraversal_Launch;
	T.bCanUse_eTraversal_Flying = Base.bCanUse_eTraversal_Flying;
	T.bCanUse_eTraversal_Land = Base.bCanUse_eTraversal_Land;

	T.bIsAlien = Base.bIsAlien;
	T.bIsAdvent = Base.bIsAdvent;
	T.bIsCivilian = Base.bIsCivilian;
	T.bIsHumanoid = Base.bIsHumanoid;
	T.bIsPsionic = Base.bIsPsionic;
	T.bIsRobotic = Base.bIsRobotic;
	T.bIsSoldier = Base.bIsSoldier;
	T.bIsAfraidOfFire = Base.bIsAfraidOfFire;
	T.bIsMeleeOnly = Base.bIsMeleeOnly;
	T.bCanTakeCover = Base.bCanTakeCover;
	T.bCanBeTerrorist = Base.bCanBeTerrorist;
	T.bSkipDefaultAbilities = Base.bSkipDefaultAbilities;
	T.bAllowSpawnFromATT = Base.bAllowSpawnFromATT;
	T.bDisplayUIUnitFlag = Base.bDisplayUIUnitFlag;
	T.bNeverSelectable = Base.bNeverSelectable;
	T.bImmueToFalling = Base.bImmueToFalling;
	T.bIsTurret = Base.bIsTurret;
	T.bDontClearRemovedFromPlay = Base.bDontClearRemovedFromPlay;
	T.bShouldCreateDifficultyVariants = false; // created after template init; difficulty variants are not generated
	T.bAppearanceDefinesPawn = Def.bAppearanceDefinesPawn || Base.bAppearanceDefinesPawn;
	// Soldier plumbing (heroes are clones of Soldier): barracks, staffing, will, wounds, carrying, customisation.
	T.bStaffingAllowed = Base.bStaffingAllowed;
	T.bAppearInBase = Base.bAppearInBase;
	T.bUsePoolSoldiers = Base.bUsePoolSoldiers;
	T.bUsesWillSystem = Base.bUsesWillSystem;
	T.bCanBeCriticallyWounded = Base.bCanBeCriticallyWounded;
	T.bCanBeCarried = Base.bCanBeCarried;
	T.bCanBeRevived = Base.bCanBeRevived;
	T.RequiredLoadout = Base.RequiredLoadout;
	T.XpKillscore = Base.XpKillscore;
	T.strIntroMatineeSlotPrefix = Base.strIntroMatineeSlotPrefix;
	T.strLoadingMatineeSlotPrefix = Base.strLoadingMatineeSlotPrefix;
	T.strAutoRunNonAIBT = Base.strAutoRunNonAIBT;
	T.CustomizationManagerClass = Base.CustomizationManagerClass;
	T.UICustomizationMenuClass = Base.UICustomizationMenuClass;
	T.UICustomizationInfoClass = Base.UICustomizationInfoClass;
	T.UICustomizationPropsClass = Base.UICustomizationPropsClass;
	T.UICustomizationHeadClass = Base.UICustomizationHeadClass;
	T.UICustomizationBodyClass = Base.UICustomizationBodyClass;
	T.UICustomizationWeaponClass = Base.UICustomizationWeaponClass;
	T.PhotoboothPersonality = Base.PhotoboothPersonality;

	T.ImmuneTypes = Base.ImmuneTypes;
	T.SightedEvents = Base.SightedEvents;
	T.SightedNarrativeMoments = Base.SightedNarrativeMoments;
	T.OnRevealEventFn = Base.OnRevealEventFn;
	T.strCharacterName = Base.strCharacterName; // overridden by our localization when present

	return T;
}
