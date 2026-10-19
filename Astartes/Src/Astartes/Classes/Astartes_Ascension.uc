//---------------------------------------------------------------------------------------
//  FILE:    Astartes_Ascension.uc
//  PURPOSE: Who becomes a Space Marine (design.md 7.8, user 2026-10-19). On LWOTC every recruit is a
//           Guardsman: at the first promotion the class comes from LWOTC's deck (its LWS_* classes are
//           the Guard regiment). Only a recruit of high Combat Intelligence ascends: a man becomes a
//           Marine (one of AspirantMarineClasses), a woman a Sister of Battle (AspirantSisterClasses,
//           empty until those classes exist). An ascended aspirant gains the Astartes physique (stats)
//           and is re-armoured in the Chapter's livery. Highlander event FirstPromotionOverrideClass.
//---------------------------------------------------------------------------------------
class Astartes_Ascension extends X2EventListener config(Astartes) dependson(Astartes_CharGen_Dressed);

var config int MinComInt;                      // ECombatIntelligence: 2 = Gifted, 3 = Genius, 4 = Savant
var config array<name> AspirantMarineClasses;
var config array<name> AspirantSisterClasses;
var config int ASCENSION_HP, ASCENSION_WILL, ASCENSION_STRENGTH;
var config int SISTER_HP, SISTER_WILL;
var config name SisterLook;                    // an Astartes_CharGen_Dressed look (parts and voice) for a new Sister
var name AscendedValueName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateAscensionListener());
	return Templates;
}

static function CHEventListenerTemplate CreateAscensionListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Astartes_Ascension_Listener');
	Template.RegisterInStrategy = true;
	Template.RegisterInTactical = true;
	Template.AddCHEvent('FirstPromotionOverrideClass', OnFirstPromotion, ELD_Immediate);
	return Template;
}

/// EventData: XComLWTuple, Data[0].n = the class chosen so far ('' = the deck decides). EventSource: the unit.
static function EventListenerReturn OnFirstPromotion(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Unit Unit;
	local array<name> Pool;
	local name Chosen;

	Tuple = XComLWTuple(EventData);
	Unit = XComGameState_Unit(EventSource);
	if (Tuple == none || Unit == none || Tuple.Data.Length == 0 || Tuple.Data[0].n != '' || Unit.GetMyTemplateName() != 'Soldier')
	{
		return ELR_NoInterrupt; // someone already chose, or not an ordinary recruit (heroes have their own class)
	}
	if (int(Unit.ComInt) < default.MinComInt)
	{
		return ELR_NoInterrupt; // a Guardsman: LWOTC's deck decides
	}
	Pool = EGender(Unit.kAppearance.iGender) == eGender_Female ? default.AspirantSisterClasses : default.AspirantMarineClasses;
	if (Pool.Length == 0)
	{
		return ELR_NoInterrupt;
	}
	Chosen = Pool[`SYNC_RAND_STATIC(Pool.Length)];
	Tuple.Data[0].n = Chosen;
	if (EGender(Unit.kAppearance.iGender) != eGender_Female)
	{
		Ascend(Unit);
	}
	else
	{
		TakeTheVeil(Unit);
	}
	`log("Astartes: aspirant" @ Unit.GetFullName() @ "(combat intelligence" @ int(Unit.ComInt) $ ") ascends as" @ Chosen,, 'Astartes');
	return ELR_NoInterrupt;
}

/// The Astartes physique and the Chapter's armour. Once per unit.
static function Ascend(XComGameState_Unit Unit)
{
	local UnitValue Done;
	local XGCharacterGenerator CharGen;
	local name Country;

	if (Unit.GetUnitValue(default.AscendedValueName, Done) && Done.fValue > 0)
	{
		return;
	}
	Unit.SetUnitFloatValue(default.AscendedValueName, 1, eCleanup_Never);
	Unit.SetBaseMaxStat(eStat_HP, Unit.GetBaseStat(eStat_HP) + default.ASCENSION_HP);
	Unit.SetCurrentStat(eStat_HP, Unit.GetMaxStat(eStat_HP));
	Unit.SetBaseMaxStat(eStat_Will, Unit.GetBaseStat(eStat_Will) + default.ASCENSION_WILL);
	Unit.SetCurrentStat(eStat_Will, Unit.GetMaxStat(eStat_Will));
	Unit.SetBaseMaxStat(eStat_Strength, Unit.GetBaseStat(eStat_Strength) + default.ASCENSION_STRENGTH);
	Unit.SetCurrentStat(eStat_Strength, Unit.GetMaxStat(eStat_Strength));

	Country = class'X2DownloadableContentInfo_Astartes'.static.GetChapterCountry();
	if (Country != '')
	{
		Unit.SetCountry(Country);
	}
	CharGen = class'Engine'.static.GetCurrentWorldInfo().Spawn(class'XGCharacterGenerator');
	if (CharGen != none)
	{
		CharGen.kSoldier.kAppearance = Unit.kAppearance;
		class'X2DownloadableContentInfo_Astartes'.static.ApplyChapterLivery(CharGen, Country);
		class'X2DownloadableContentInfo_Astartes'.static.ApplyMarineArmourLook(CharGen, 'KevlarArmor');
		Unit.SetTAppearance(CharGen.kSoldier.kAppearance);
		CharGen.Destroy();
	}
}

/// A gifted woman joins the Orders Militant: steadier and tougher, and armoured in Sister of Battle plate.
static function TakeTheVeil(XComGameState_Unit Unit)
{
	local UnitValue Done;
	local TAppearance Look;
	local Astartes_CharGen_Dressed.DressedLook Dress;
	local int i;

	if (Unit.GetUnitValue(default.AscendedValueName, Done) && Done.fValue > 0)
	{
		return;
	}
	Unit.SetUnitFloatValue(default.AscendedValueName, 1, eCleanup_Never);
	Unit.SetBaseMaxStat(eStat_HP, Unit.GetBaseStat(eStat_HP) + default.SISTER_HP);
	Unit.SetCurrentStat(eStat_HP, Unit.GetMaxStat(eStat_HP));
	Unit.SetBaseMaxStat(eStat_Will, Unit.GetBaseStat(eStat_Will) + default.SISTER_WILL);
	Unit.SetCurrentStat(eStat_Will, Unit.GetMaxStat(eStat_Will));
	i = class'Astartes_CharGen_Dressed'.default.Looks.Find('Template', default.SisterLook);
	if (i != INDEX_NONE)
	{
		Dress = class'Astartes_CharGen_Dressed'.default.Looks[i];
		Look = Unit.kAppearance;
		Look.nmHelmet = ''; // the Guard helmet comes off; Sisters go bare-headed unless their look says otherwise
		class'Astartes_CharGen_Dressed'.static.Dress(Look, Dress);
		Unit.SetTAppearance(Look);
	}
}

defaultproperties
{
	AscendedValueName = "Astartes_Ascended"
}
