//---------------------------------------------------------------------------------------
//  FILE:    Astartes_AbilityVariants.uc
//  PURPOSE: Clone an existing ability template under one of our names, so a 40K power can have
//           its own name, description and (later) tuning while reusing a proven vanilla
//           implementation. First use: the Librarian's disciplines (Smite = Soulfire, ...).
//           Runs in OnPostTemplatesCreated so the bases exist.
//---------------------------------------------------------------------------------------
class Astartes_AbilityVariants extends Object config(Astartes);

struct AbilityClone
{
	var name NewName;       // e.g. Astartes_Smite
	var name BaseAbility;   // e.g. Soulfire
};

var config array<AbilityClone> Clones;

static function CreateClones()
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Base, Clone;
	local int i, Created;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = 0; i < default.Clones.Length; i++)
	{
		if (AbilityMgr.FindAbilityTemplate(default.Clones[i].NewName) != none)
		{
			continue;
		}
		Base = AbilityMgr.FindAbilityTemplate(default.Clones[i].BaseAbility);
		if (Base == none)
		{
			`log("Astartes: ability clone" @ default.Clones[i].NewName @ "skipped: base" @ default.Clones[i].BaseAbility @ "not found",, 'Astartes');
			continue;
		}
		Clone = new(none, string(default.Clones[i].NewName)) Base.Class (Base); // named: loc loads by object name
		Clone.SetTemplateName(default.Clones[i].NewName);
		AbilityMgr.AddAbilityTemplate(Clone, true);
		Created++;
	}
	`log("Astartes: ability clones created:" @ Created @ "of" @ default.Clones.Length,, 'Astartes');
}
