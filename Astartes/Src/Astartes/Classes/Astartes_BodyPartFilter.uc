//---------------------------------------------------------------------------------------
//  FILE:    Astartes_BodyPartFilter.uc
//  PURPOSE: Body-part filter that only accepts parts from the configured Marine armour packs
//           (e.g. the Space Marine 2 Tacticus set), on top of the vanilla gender / armour /
//           torso matching rules. Vanilla parts carry DLCName '' and are excluded on purpose.
//---------------------------------------------------------------------------------------
class Astartes_BodyPartFilter extends X2SimpleBodyPartFilter;

var array<name> RequiredPacks;

function bool IsFromRequiredPack(X2BodyPartTemplate Template)
{
	return RequiredPacks.Find(Template.DLCName) != INDEX_NONE;
}

function bool FilterMarineTorso(X2BodyPartTemplate Template)
{
	return IsFromRequiredPack(Template) && FilterTorso(Template);
}

function bool FilterMarinePart(X2BodyPartTemplate Template)
{
	return IsFromRequiredPack(Template) && FilterByTorsoAndArmorMatch(Template);
}
