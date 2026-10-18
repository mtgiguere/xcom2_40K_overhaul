"""Imperial wargear and other template clones.

Templates cloned at runtime (weapons, ability variants) must be constructed as *named* objects:
`new(none, string(NewName)) Base.Class (Base)`. UnrealScript loads PerObjectConfig and localized
properties by object name, so an unnamed clone keeps the vanilla name ("Assault Rifle" instead of
"Bolter"). Found in play 2026-10-17.
"""
from __future__ import annotations

import re

from conftest import SRC_DIR
from x2config import sections_of_class, struct_field, unquote

UNNAMED_CLONE_RE = re.compile(r"\bnew\s+\w+\.Class\s*\(")
NAMED_CLONE_RE = re.compile(r"\bnew\s*\(\s*none\s*,\s*string\(\s*[\w.\[\]]+\s*\)\s*\)\s*\w+\.Class\s*\(", re.IGNORECASE)


def mod_sources():
    return [f for f in SRC_DIR.glob("*.uc") if not f.name.startswith("XMB")]


def test_template_clones_are_named_objects():
    offenders = []
    for f in mod_sources():
        for n, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if UNNAMED_CLONE_RE.search(line) and not NAMED_CLONE_RE.search(line):
                offenders.append(f"{f.name}:{n}: {line.strip()}")
    assert not offenders, "template clones must be created as new(none, string(Name)) so loc/config load:\n" + "\n".join(offenders)


def test_every_weapon_has_a_localized_name(config, loc_sections):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Item_AstartesWeapons"][0]
    weapons = [struct_field(v, "NewName") for v in section.values("Weapons")]
    loc = {s.template_name: s for s in sections_of_class(loc_sections, "X2WeaponTemplate")}
    missing = [w for w in weapons if w not in loc or not unquote(loc[w].first("FriendlyName") or "")]
    assert not missing, f"weapons without a [Name X2WeaponTemplate] FriendlyName: {missing}"


def test_every_ability_clone_has_a_localized_name(config, loc_sections):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_AbilityVariants"][0]
    clones = [struct_field(v, "NewName") for v in section.values("Clones")]
    loc = {s.template_name: s for s in sections_of_class(loc_sections, "X2AbilityTemplate")}
    missing = [c for c in clones if c not in loc or not unquote(loc[c].first("LocFriendlyName") or "")]
    assert not missing, f"ability clones without a [Name X2AbilityTemplate] LocFriendlyName: {missing}"


def test_borrowed_looks_hide_their_donors(config):
    """A weapon that wears another mod's model must hide that mod's own item, or the armoury shows two Bolters."""
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Item_AstartesWeapons"][0]
    donors = {struct_field(v, "MeshFrom") for v in section.values("Weapons") if struct_field(v, "MeshFrom")}
    hidden = {unquote(v) for v in section.values("HideDonorItems")}
    assert donors, "expected at least the Bolter and Bolt Pistol to borrow a 40K model"
    assert donors <= hidden, f"donor items not hidden: {sorted(donors - hidden)}"


def test_recruits_carry_bolters(config):
    """New recruits must not start with XCOM rifles: the vanilla rookie loadouts are replaced."""
    mgr = [s for s in config["XComGameData.ini"] if s.name == "XComGame.X2ItemTemplateManager"][0]
    added = {struct_field(v, "LoadoutName"): v for op, k, v in mgr.entries if k == "Loadouts" and op == "+"}
    removed = {struct_field(v, "LoadoutName") for op, k, v in mgr.entries if k == "Loadouts" and op == "-"}
    for name in ("RookieSoldier", "RookieSoldierM2", "RookieSoldierM3"):
        assert name in removed, f"vanilla {name} loadout must be removed before being replaced"
        assert name in added and "Astartes_Bolter" in added[name], f"{name} must hand out a Bolter"


def test_bolt_pistols_can_be_fired(config):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Item_AstartesWeapons"][0]
    extras = {(struct_field(v, "Weapon"), struct_field(v, "Ability")) for v in section.values("ExtraAbilities")}
    for tier in ("CV", "MG", "BM"):
        assert (f"Astartes_BoltPistol_{tier}", "PistolStandardShot") in extras
