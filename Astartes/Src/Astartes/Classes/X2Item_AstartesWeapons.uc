//---------------------------------------------------------------------------------------
//  FILE:    X2Item_AstartesWeapons.uc
//  PURPOSE: Imperial wargear as clones of vanilla weapon templates, renamed and retuned.
//           Cloning keeps the vanilla meshes, animations, upgrade slots and the schematic
//           upgrade chain (buying Magnetic Weapons upgrades Bolter Mk I -> Mk II, etc.) until
//           40K meshes are wired in. Runs in OnPostTemplatesCreated so the bases exist; this
//           DLC runs before Primary Secondaries, which then makes _Primary variants of our
//           pistols and swords for the Assault Marine and Librarian.
//---------------------------------------------------------------------------------------
class X2Item_AstartesWeapons extends Object config(Astartes);

struct WeaponDef
{
	var name NewName;          // e.g. Astartes_Bolter_CV
	var name BaseTemplate;     // e.g. AssaultRifle_CV
	var name BaseItem;         // our previous tier, so vanilla schematics upgrade our items ('' for tier 1)
	var int DamageBonus;       // added to the base's damage
	var int ClipSizeOverride;  // -1 = keep base
	var int AimBonus;          // added to the base's Aim
	structdefaultproperties
	{
		ClipSizeOverride = -1
	}
};

var config array<WeaponDef> Weapons;

static function CreateWeapons()
{
	local X2ItemTemplateManager ItemMgr;
	local X2WeaponTemplate Base, Clone;
	local int i, Created;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for (i = 0; i < default.Weapons.Length; i++)
	{
		if (ItemMgr.FindItemTemplate(default.Weapons[i].NewName) != none)
		{
			continue;
		}
		Base = X2WeaponTemplate(ItemMgr.FindItemTemplate(default.Weapons[i].BaseTemplate));
		if (Base == none)
		{
			`log("Astartes: weapon" @ default.Weapons[i].NewName @ "skipped: base" @ default.Weapons[i].BaseTemplate @ "not found",, 'Astartes');
			continue;
		}

		Clone = new(none, string(default.Weapons[i].NewName)) Base.Class (Base); // named: loc + PerObjectConfig load by object name
		Clone.SetTemplateName(default.Weapons[i].NewName);
		Clone.BaseItem = default.Weapons[i].BaseItem;
		Clone.BaseDamage.Damage += default.Weapons[i].DamageBonus;
		Clone.Aim += default.Weapons[i].AimBonus;
		if (default.Weapons[i].ClipSizeOverride >= 0)
		{
			Clone.iClipSize = default.Weapons[i].ClipSizeOverride;
		}
		// Keep CreatorTemplateName: the vanilla schematic that creates the base tier also creates ours,
		// and upgrades soldiers' items whose template equals our BaseItem.

		ItemMgr.AddItemTemplate(Clone, true);
		Created++;
	}
	`log("Astartes: weapons created:" @ Created @ "of" @ default.Weapons.Length,, 'Astartes');
}
