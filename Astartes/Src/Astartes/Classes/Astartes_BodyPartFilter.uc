//---------------------------------------------------------------------------------------
//  FILE:    Astartes_BodyPartFilter.uc
//  PURPOSE: Body-part filter that only accepts parts from the configured Marine armour packs
//           (e.g. the Space Marine 2 Tacticus set), on top of the vanilla gender / armour /
//           torso matching rules. Vanilla parts carry DLCName '' and are excluded on purpose.
//---------------------------------------------------------------------------------------
class Astartes_BodyPartFilter extends X2SimpleBodyPartFilter;

var array<name> RequiredPacks;

/// If non-empty, a part's display name must contain one of these (case-insensitive) to be eligible.
/// The armour packs label tintable pieces "(Tintable)" / "(Primary Tint)"; unlabelled ones are pre-painted
/// for a specific Chapter and would fight the campaign's livery.
var array<string> RequiredNameKeywords;

function bool IsFromRequiredPack(X2BodyPartTemplate Template)
{
	return RequiredPacks.Find(Template.DLCName) != INDEX_NONE;
}

function bool HasRequiredKeyword(X2BodyPartTemplate Template)
{
	local string Keyword;

	if (RequiredNameKeywords.Length == 0)
	{
		return true;
	}
	foreach RequiredNameKeywords(Keyword)
	{
		if (InStr(Template.DisplayName, Keyword, , true) != INDEX_NONE)
		{
			return true;
		}
	}
	return false;
}

function bool IsEligible(X2BodyPartTemplate Template)
{
	return IsFromRequiredPack(Template) && HasRequiredKeyword(Template);
}

function bool FilterMarineTorso(X2BodyPartTemplate Template)
{
	return IsEligible(Template) && FilterTorso(Template);
}

function bool FilterMarinePart(X2BodyPartTemplate Template)
{
	return IsEligible(Template) && FilterByTorsoAndArmorMatch(Template);
}

/// Pack + keyword + gender only. For parts that are not bound to an armour tier (helmets, deco), and as a fallback.
function bool FilterMarineAny(X2BodyPartTemplate Template)
{
	return IsEligible(Template) && FilterByGenderAndNonSpecialized(Template);
}
