//---------------------------------------------------------------------------------------
//  FILE:    Astartes_ItemSlots.uc
//  PURPOSE: Custom inventory slots through the Community Highlander's CHItemSlot templates.
//           The Psychic Hood slot (eInvSlot_PsiAmp, a slot the Highlander reserves for this use)
//           lets a Librarian carry force sword, bolt pistol AND hood, as the lore kit has it.
//           Only Librarians have the slot; only psi-amp weapons fit it.
//---------------------------------------------------------------------------------------
class Astartes_ItemSlots extends CHItemSlotSet config(Astartes);

var config array<name> HoodSlotClasses;      // classes that have the hood slot
var config name HoodSlotWeaponCat;           // weapon category the slot accepts (psiamp)
var config int HoodSlotPriority;             // armoury order; vanilla slots use slot index * 10 (secondary = 30)
var localized string HoodSlotName;
var localized string HoodSlotLocked;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateHoodSlot());
	return Templates;
}

static function CHItemSlot CreateHoodSlot()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'Astartes_PsychicHoodSlot');
	Template.InvSlot = eInvSlot_PsiAmp;
	Template.SlotCatMask = class'CHItemSlot'.const.SLOT_WEAPON;
	Template.IsUserEquipSlot = true;
	Template.IsEquippedSlot = true;
	Template.IsSmallSlot = false;
	Template.NeedsPresEquip = true;
	Template.ShowOnCinematicPawns = true;
	Template.BypassesUniqueRule = false;

	Template.CanAddItemToSlotFn = CanAddHood;
	Template.UnitHasSlotFn = HasHoodSlot;
	Template.GetPriorityFn = HoodPriority;
	Template.GetDisplayNameFn = HoodDisplayName;
	Template.ShowItemInLockerListFn = ShowHoodInLocker;
	Template.ValidateLoadoutFn = ValidateHood;
	Template.GetSlotUnequipBehaviorFn = HoodUnequipBehavior;
	return Template;
}

static function bool CanAddHood(CHItemSlot Slot, XComGameState_Unit Unit, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{
	local X2WeaponTemplate Weapon;
	local string Locked;

	Weapon = X2WeaponTemplate(Template);
	return Weapon != none && Weapon.WeaponCat == default.HoodSlotWeaponCat && Weapon.InventorySlot == Slot.InvSlot
		&& HasHoodSlot(Slot, Unit, Locked, CheckGameState) && Unit.GetItemInSlot(Slot.InvSlot, CheckGameState) == none;
}

static function bool HasHoodSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	if (UnitState == none || !UnitState.IsSoldier() || default.HoodSlotClasses.Find(UnitState.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		LockedReason = default.HoodSlotLocked;
		return false;
	}
	return true;
}

static function int HoodPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return default.HoodSlotPriority;
}

static function string HoodDisplayName(CHItemSlot Slot)
{
	return default.HoodSlotName;
}

static function bool ShowHoodInLocker(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	local X2WeaponTemplate Weapon;

	Weapon = X2WeaponTemplate(ItemTemplate);
	return Weapon != none && Weapon.WeaponCat == default.HoodSlotWeaponCat && Weapon.InventorySlot == Slot.InvSlot;
}

/// A Librarian without a hood gets the best one XCOM owns (infinite items preferred), so the powers always have a source.
static function ValidateHood(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item Existing, NewItem;
	local X2WeaponTemplate Best, Candidate;
	local X2ItemTemplateManager ItemMgr;
	local X2DataTemplate DataTemplate;
	local string Locked;

	if (!HasHoodSlot(Slot, Unit, Locked, NewGameState))
	{
		return;
	}
	Existing = Unit.GetItemInSlot(Slot.InvSlot, NewGameState);
	if (Existing != none)
	{
		return;
	}
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemMgr.IterateTemplates(DataTemplate, none)
	{
		Candidate = X2WeaponTemplate(DataTemplate);
		if (Candidate == none || Candidate.WeaponCat != default.HoodSlotWeaponCat || Candidate.InventorySlot != Slot.InvSlot)
		{
			continue;
		}
		if (!Candidate.bInfiniteItem && !XComHQ.HasItem(Candidate))
		{
			continue;
		}
		if (Best == none || Candidate.Tier > Best.Tier)
		{
			Best = Candidate;
		}
	}
	if (Best == none)
	{
		return;
	}
	NewItem = Best.CreateInstanceFromTemplate(NewGameState);
	if (!Unit.AddItemToInventory(NewItem, Slot.InvSlot, NewGameState))
	{
		NewGameState.RemoveStateObject(NewItem.ObjectID);
		return;
	}
	`log("Astartes: equipped" @ Best.DataName @ "in the hood slot of" @ Unit.GetFullName(),, 'Astartes');
}

static function ECHSlotUnequipBehavior HoodUnequipBehavior(CHItemSlot Slot, ECHSlotUnequipBehavior DefaultBehavior, XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	return eCHSUB_AttemptReEquip;
}
