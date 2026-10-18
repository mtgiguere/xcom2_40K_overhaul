//---------------------------------------------------------------------------------------
//  FILE:    Astartes_AbilityVariants.uc
//  PURPOSE: Clone an existing ability template under one of our names, so a 40K power can have
//           its own name, description and tuning while reusing a proven vanilla implementation.
//           Uses: the Librarian's disciplines (Smite = Soulfire, ...) and the Assault Marine's
//           Jump Pack (= Icarus Jump, retuned). Runs in OnPostTemplatesCreated so the bases exist.
//           Clones are created as NAMED objects so localization/PerObjectConfig load by object name.
//           Tuning replaces the relevant cost/cooldown/target objects on the clone only; the
//           base template's objects are never modified.
//---------------------------------------------------------------------------------------
class Astartes_AbilityVariants extends Object config(Astartes);

struct AbilityClone
{
	var name NewName;          // e.g. Astartes_Smite
	var name BaseAbility;      // e.g. Soulfire
	var int Cooldown;          // -1 keep the base's; 0 none; n turns
	var bool bRemoveCharges;   // drop per-mission charges (unlimited uses)
	var int ActionPoints;      // -1 keep; 0 free action; n action points
	var bool bEndsTurn;        // with ActionPoints >= 1: consume all remaining points
	var int RangeTiles;        // -1 keep; for cursor-targeted abilities: fixed range in tiles
	var bool bNoRulerReaction; // drop the 'RulerArmorAbilityActivated' post-activation event (Alien Rulers would get a free move)
	var int Charges;           // 0 keep; n = per-mission charges (a charge cost is added if the base has none)
	var bool bClearPrerequisites; // drop PrerequisiteAbilities (our trees define their own progression)
	structdefaultproperties
	{
		Cooldown = -1
		ActionPoints = -1
		RangeTiles = -1
	}
};

var config array<AbilityClone> Clones;
// Retunes change a VANILLA template in place (NewName ignored). Used where the ability must keep its vanilla
// name: perk visual effects and per-ability animations are bound to the ability name, so a clone loses them.
// The 40K name and text come from localization overrides in XComGame.int.
var config array<AbilityClone> Retunes;

static function CreateClones()
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Base, Clone;
	local AbilityClone Def;
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
		Def = default.Clones[i]; // copy: array elements cannot be passed as out parameters
		// Our trees define their own progression: a cloned Schism must not demand the vanilla Insanity.
		Clone.PrerequisiteAbilities.Length = 0;
		Tune(Clone, Def);
		AbilityMgr.AddAbilityTemplate(Clone, true);
		Created++;
	}
	`log("Astartes: ability clones created:" @ Created @ "of" @ default.Clones.Length,, 'Astartes');
	ApplyRetunes(AbilityMgr);
}

static function ApplyRetunes(X2AbilityTemplateManager AbilityMgr)
{
	local X2AbilityTemplate Template;
	local AbilityClone Def;
	local int i, Applied;

	for (i = 0; i < default.Retunes.Length; i++)
	{
		Template = AbilityMgr.FindAbilityTemplate(default.Retunes[i].BaseAbility);
		if (Template == none)
		{
			`log("Astartes: retune of" @ default.Retunes[i].BaseAbility @ "skipped: not found",, 'Astartes');
			continue;
		}
		Def = default.Retunes[i];
		Tune(Template, Def);
		Applied++;
	}
	`log("Astartes: ability retunes applied:" @ Applied @ "of" @ default.Retunes.Length,, 'Astartes');
}

/// Apply the optional tuning. Cost arrays and target styles are rebuilt with new objects so the
/// base template (which shares its objects with the clone) is untouched.
static function Tune(X2AbilityTemplate Clone, const out AbilityClone Def)
{
	local array<X2AbilityCost> Costs;
	local X2AbilityCost_ActionPoints APCost;
	local X2AbilityCooldown Cooldown;
	local X2AbilityTarget_Cursor BaseCursor, Cursor;
	local int i;

	if (Def.Cooldown >= 0)
	{
		if (Def.Cooldown == 0)
		{
			Clone.AbilityCooldown = none;
		}
		else
		{
			Cooldown = new class'X2AbilityCooldown';
			Cooldown.iNumTurns = Def.Cooldown;
			Clone.AbilityCooldown = Cooldown;
		}
	}

	if (Def.bRemoveCharges || Def.ActionPoints >= 0)
	{
		for (i = 0; i < Clone.AbilityCosts.Length; i++)
		{
			if (Def.bRemoveCharges && X2AbilityCost_Charges(Clone.AbilityCosts[i]) != none)
			{
				continue;
			}
			if (Def.ActionPoints >= 0 && X2AbilityCost_ActionPoints(Clone.AbilityCosts[i]) != none)
			{
				continue;
			}
			Costs.AddItem(Clone.AbilityCosts[i]);
		}
		if (Def.ActionPoints >= 0)
		{
			APCost = new class'X2AbilityCost_ActionPoints';
			APCost.iNumPoints = Max(Def.ActionPoints, 1);
			APCost.bFreeCost = Def.ActionPoints == 0;
			APCost.bConsumeAllPoints = Def.bEndsTurn;
			Costs.AddItem(APCost);
		}
		Clone.AbilityCosts = Costs;
		if (Def.bRemoveCharges)
		{
			Clone.AbilityCharges = none;
		}
	}

	if (Def.RangeTiles > 0)
	{
		BaseCursor = X2AbilityTarget_Cursor(Clone.AbilityTargetStyle);
		if (BaseCursor != none)
		{
			Cursor = new class'X2AbilityTarget_Cursor';
			Cursor.bRestrictToWeaponRange = BaseCursor.bRestrictToWeaponRange;
			Cursor.IncreaseWeaponRange = BaseCursor.IncreaseWeaponRange;
			Cursor.bRestrictToSquadsightRange = BaseCursor.bRestrictToSquadsightRange;
			// FixedAbilityRange is in meters; a tile is WORLD_StepSize units and a meter WORLD_METERS_TO_UNITS_MULTIPLIER units.
			Cursor.FixedAbilityRange = Def.RangeTiles * class'XComWorldData'.const.WORLD_StepSize / class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER;
			Clone.AbilityTargetStyle = Cursor;
		}
		else
		{
			`log("Astartes: ability clone" @ Def.NewName @ "RangeTiles ignored: base is not cursor-targeted",, 'Astartes');
		}
	}

	if (Def.Charges > 0)
	{
		SetCharges(Clone, Def.Charges);
	}

	if (Def.bNoRulerReaction)
	{
		Clone.PostActivationEvents.RemoveItem('RulerArmorAbilityActivated');
	}

	if (Def.bClearPrerequisites)
	{
		Clone.PrerequisiteAbilities.Length = 0;
	}
}

static function SetCharges(X2AbilityTemplate Clone, int NumCharges)
{
	local X2AbilityCharges Charges;
	local X2AbilityCost_Charges ChargeCost;
	local array<X2AbilityCost> Costs;
	local bool bHasChargeCost;
	local int i;

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = NumCharges;
	Clone.AbilityCharges = Charges;

	for (i = 0; i < Clone.AbilityCosts.Length; i++)
	{
		Costs.AddItem(Clone.AbilityCosts[i]);
		if (X2AbilityCost_Charges(Clone.AbilityCosts[i]) != none)
		{
			bHasChargeCost = true;
		}
	}
	if (!bHasChargeCost)
	{
		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Costs.AddItem(ChargeCost);
	}
	Clone.AbilityCosts = Costs;
}
