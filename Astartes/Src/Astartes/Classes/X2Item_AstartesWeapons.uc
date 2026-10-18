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
	var name MeshFrom;         // optional: another mod's weapon template whose model/icon/attachments we borrow
	structdefaultproperties
	{
		ClipSizeOverride = -1
	}
};

var config array<WeaponDef> Weapons;
// Donor templates (other mods' weapons) whose looks we borrowed: hidden from the armoury and build list so
// the player sees one Bolter, ours, not theirs as well. Skipped silently when the mod is not loaded.
var config array<name> HideDonorItems;

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
		if (default.Weapons[i].MeshFrom != '')
		{
			BorrowLook(Clone, default.Weapons[i].MeshFrom, ItemMgr);
		}

		ItemMgr.AddItemTemplate(Clone, true);
		Created++;
	}
	`log("Astartes: weapons created:" @ Created @ "of" @ default.Weapons.Length,, 'Astartes');
	HideDonors(ItemMgr);
}

/// Give our clone another mod's model, icon, camera point and default attachment meshes. Stats, abilities and
/// the vanilla upgrade chain stay ours. Vanilla weapon-upgrade attachment meshes are keyed by template name,
/// so they do not apply to the clone (upgrades still work, they just show no bolt-on mesh).
static function BorrowLook(X2WeaponTemplate Clone, name DonorName, X2ItemTemplateManager ItemMgr)
{
	local X2WeaponTemplate Donor;

	Donor = X2WeaponTemplate(ItemMgr.FindItemTemplate(DonorName));
	if (Donor == none)
	{
		`log("Astartes: weapon" @ Clone.DataName @ "keeps the vanilla look: donor" @ DonorName @ "not loaded",, 'Astartes');
		return;
	}
	Clone.GameArchetype = Donor.GameArchetype;
	Clone.AltGameArchetype = Donor.AltGameArchetype;
	Clone.AltGameArchetypeArray = Donor.AltGameArchetypeArray;
	Clone.ArmorTechCatForAltArchetype = Donor.ArmorTechCatForAltArchetype;
	Clone.GenderForAltArchetype = Donor.GenderForAltArchetype;
	Clone.strImage = Donor.strImage;
	Clone.WeaponPanelImage = Donor.WeaponPanelImage;
	Clone.UIArmoryCameraPointTag = Donor.UIArmoryCameraPointTag;
	Clone.EquipSound = Donor.EquipSound;
	Clone.DefaultAttachments = Donor.DefaultAttachments;
	`log("Astartes: weapon" @ Clone.DataName @ "wears" @ Donor.GameArchetype,, 'Astartes');
}

/// Make the donor items (all difficulty variants) and the schematics that build them unobtainable.
static function HideDonors(X2ItemTemplateManager ItemMgr)
{
	local array<X2DataTemplate> Variants;
	local X2DataTemplate DataTemplate;
	local X2ItemTemplate Item;
	local X2SchematicTemplate Schematic;
	local int i, j, Hidden;

	for (i = 0; i < default.HideDonorItems.Length; i++)
	{
		ItemMgr.FindDataTemplateAllDifficulties(default.HideDonorItems[i], Variants);
		for (j = 0; j < Variants.Length; j++)
		{
			Item = X2ItemTemplate(Variants[j]);
			if (Item == none) continue;
			Item.StartingItem = false;
			Item.bInfiniteItem = false;
			Item.CanBeBuilt = false;
			Item.CreatorTemplateName = '';
			Item.RewardDecks.Length = 0;
			Hidden++;
		}
	}
	// Their schematics (Build Items entries) reference the donor item for text: hide those too.
	foreach ItemMgr.IterateTemplates(DataTemplate, none)
	{
		Schematic = X2SchematicTemplate(DataTemplate);
		if (Schematic != none && default.HideDonorItems.Find(Schematic.ReferenceItemTemplate) != INDEX_NONE)
		{
			Schematic.CanBeBuilt = false;
			Schematic.bInfiniteItem = false;
			Hidden++;
		}
	}
	if (Hidden > 0)
	{
		`log("Astartes: hid" @ Hidden @ "donor weapon templates/schematics",, 'Astartes');
	}
}
