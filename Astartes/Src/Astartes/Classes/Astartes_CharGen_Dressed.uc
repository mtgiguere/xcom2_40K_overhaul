//---------------------------------------------------------------------------------------
//  FILE:    Astartes_CharGen_Dressed.uc
//  PURPOSE: Character generator for soldier-bodied units that must wear a fixed set of cosmetic
//           parts: the Eldar Warlock in craftworld armour today, Sisters and Guardsmen tomorrow.
//           The template's bAppearanceDefinesPawn sends spawned units here; the base generator
//           builds a random human, then the configured Looks entry for the template overwrites
//           every part it names. Parts come from cosmetic mods (EldarArmor...), by template name.
//---------------------------------------------------------------------------------------
class Astartes_CharGen_Dressed extends XGCharacterGenerator config(Astartes);

struct DressedLook
{
	var name Template;         // character template this look belongs to
	var int Gender;            // 1 male, 2 female, 0 either
	var name nmHead, nmHelmet, nmTorso, nmArms, nmLeftArm, nmRightArm, nmLeftArmDeco, nmRightArmDeco, nmLeftForearm, nmRightForearm;
	var name nmLegs, nmThighs, nmShins, nmTorsoDeco, nmFacePropLower, nmFacePropUpper;
	var name nmPawn;           // body part template of type Pawn; '' = the standard soldier body for the gender (never a random mod pawn)
	var name nmVoice;          // voice body part template; '' = silent
	var bool bKeepName;        // false: no personal name, the unit flag shows the character template's name
	var int iArmorTint, iArmorTintSecondary, iSkinColor;  // -1 = leave the generated value
	structdefaultproperties
	{
		iArmorTint = -1
		iArmorTintSecondary = -1
		iSkinColor = -1
	}
};

var config array<DressedLook> Looks;

function TSoldier CreateTSoldier(optional name CharacterTemplateName, optional EGender eForceGender, optional name nmCountry = '', optional int iRace = -1, optional name ArmorName)
{
	local int i;
	local DressedLook Look;

	i = default.Looks.Find('Template', CharacterTemplateName);
	`log("Astartes: dressing generator asked for" @ CharacterTemplateName @ "(look" @ i $ ")",, 'Astartes');
	if (i != INDEX_NONE && eForceGender == eGender_None && default.Looks[i].Gender > 0)
	{
		eForceGender = EGender(default.Looks[i].Gender);
	}
	kSoldier = super.CreateTSoldier(CharacterTemplateName, eForceGender, nmCountry, iRace, ArmorName);
	if (i != INDEX_NONE)
	{
		Look = default.Looks[i];
		Dress(kSoldier.kAppearance, Look);
		if (!Look.bKeepName)
		{
			kSoldier.strFirstName = "";
			kSoldier.strLastName = "";
			kSoldier.strNickName = "";
		}
		`log("Astartes: dressed" @ CharacterTemplateName @ "in" @ default.Looks[i].nmTorso @ default.Looks[i].nmHelmet,, 'Astartes');
	}
	return kSoldier;
}

/// Overwrite the parts the look names. A whole-arms part and separate arm parts are exclusive, so naming
/// nmArms clears the per-arm slots and vice versa.
static function Dress(out TAppearance A, const out DressedLook L)
{
	if (L.nmHead != '') A.nmHead = L.nmHead;
	if (L.nmHelmet != '') { A.nmHelmet = L.nmHelmet; A.nmHaircut = ''; }
	if (L.nmTorso != '') A.nmTorso = L.nmTorso;
	if (L.nmArms != '')
	{
		A.nmArms = L.nmArms;
		A.nmLeftArm = ''; A.nmRightArm = ''; A.nmLeftArmDeco = ''; A.nmRightArmDeco = ''; A.nmLeftForearm = ''; A.nmRightForearm = '';
	}
	else if (L.nmLeftArm != '' || L.nmRightArm != '')
	{
		A.nmArms = '';
		if (L.nmLeftArm != '') A.nmLeftArm = L.nmLeftArm;
		if (L.nmRightArm != '') A.nmRightArm = L.nmRightArm;
		if (L.nmLeftArmDeco != '') A.nmLeftArmDeco = L.nmLeftArmDeco;
		if (L.nmRightArmDeco != '') A.nmRightArmDeco = L.nmRightArmDeco;
		if (L.nmLeftForearm != '') A.nmLeftForearm = L.nmLeftForearm;
		if (L.nmRightForearm != '') A.nmRightForearm = L.nmRightForearm;
	}
	if (L.nmLegs != '') A.nmLegs = L.nmLegs;
	if (L.nmThighs != '') A.nmThighs = L.nmThighs;
	if (L.nmShins != '') A.nmShins = L.nmShins;
	if (L.nmTorsoDeco != '') A.nmTorsoDeco = L.nmTorsoDeco;
	if (L.nmFacePropLower != '') A.nmFacePropLower = L.nmFacePropLower;
	if (L.nmFacePropUpper != '') A.nmFacePropUpper = L.nmFacePropUpper;
	// The body itself: a named Pawn part, else the standard soldier body. Left empty, the game picks a random Pawn part from
	// every loaded mod (playtest 2026-10-18: the Warlock came out as a Chaos Marine).
	A.nmPawn = L.nmPawn != '' ? L.nmPawn : (A.iGender == eGender_Female ? 'XCom_Soldier_F' : 'XCom_Soldier_M');
	A.nmVoice = L.nmVoice;
	if (L.iArmorTint >= 0) A.iArmorTint = L.iArmorTint;
	if (L.iArmorTintSecondary >= 0) A.iArmorTintSecondary = L.iArmorTintSecondary;
	if (L.iSkinColor >= 0) A.iSkinColor = L.iSkinColor;
}
