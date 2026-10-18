//---------------------------------------------------------------------------------------
//  FILE:    X2Character_Astartes.uc
//  PURPOSE: Enemy and ally character templates that this mod defines from scratch (no
//           dependency on another mod). Variants cloned from other mods' templates live in
//           Astartes_UnitVariants and are created after all templates exist.
//---------------------------------------------------------------------------------------
class X2Character_Astartes extends X2Character config(GameData_CharacterStats);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateCultist('Astartes_Cultist'));

	return Templates;
}

/// Chaos Cultist: an armed human in civilian clothes. Appearance is generated like the vanilla
/// civilian militia (see X2DownloadableContentInfo_Astartes.ModifyGeneratedUnitAppearance), so the
/// unit wears rags and carries a rifle without needing any new art. Stats in XComGameData_CharacterStats.ini.
static function X2CharacterTemplate CreateCultist(name TemplateName)
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);
	CharTemplate.CharacterGroupName = 'Astartes_Cultist';
	CharTemplate.DefaultLoadout = 'Astartes_Cultist_Loadout';
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.UnitSize = 1;

	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;

	// A human in civilian clothes: the appearance assembles the pawn (like the militia), it is not an alien.
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bSetGenderAlways = true;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = true;      // targeting: counts as an enemy humanoid, not a civilian
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsHumanoid = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bCanBeTerrorist = true;
	CharTemplate.bShouldCreateDifficultyVariants = true;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Advent;
	CharTemplate.strScamperBT = "GenericScamperRoot";

	return CharTemplate;
}
