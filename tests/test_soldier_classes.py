"""Phase 1: the Marine roster.

The spec is tests/data/class_trees.json (rendered into config by tools/gen_class_config.py). These tests
check that the rendered config matches the spec, that every ability referenced exists somewhere (vanilla
or this mod's source), and that the design rules hold.
"""
from __future__ import annotations

import json
import re

import pytest

from conftest import REPO, SRC_DIR
from x2config import sections_of_class, struct_field, unquote

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))
ALL_CLASSES = sorted(SPEC["classes"])
# Faction heroes (Canoness, Commissar) are human: the Marine kit rules do not apply to them.
# Sisters of Battle ("order") are not Marines either.
MARINE_CLASSES = sorted(k for k, v in SPEC["classes"].items() if "hero" not in v and "order" not in v)
EXPECTED_RANKS = 7
EXPECTED_COLUMNS = 3
LIBRARIUS_RANKS = ["Lexicanium", "Codicier", "Epistolary", "Librarian"]

VANILLA_ABILITIES = set((REPO / "tests" / "data" / "vanilla_abilities.txt").read_text(encoding="utf-8").split())

# Vanilla creation patterns plus the XModBase helpers (Passive('Name', ...), TargetedBuff('Name', ...) ...).
_MOD_ABILITY_RE = re.compile(
    r"""(?:CreateTemplate\s*\(\s*class'X2AbilityTemplate'\s*,\s*'(\w+)'"""
    r"""|CREATE_X2ABILITY_TEMPLATE\s*\(\s*\w+\s*,\s*'(\w+)'"""
    r"""|PurePassive\s*\(\s*'(\w+)'"""
    r"""|(?:Passive|SelfTargetTrigger|SelfTargetActivated|Attack|MeleeAttack|TargetedDebuff|TargetedBuff|SquadPassive|HiddenSelfAbility)\s*\(\s*'(\w+)')"""
)


def mod_abilities() -> set[str]:
    """Ability template names defined by this mod: own sources (XModBase helper files are library code, skipped)
    plus config-declared clones of vanilla abilities (Astartes_AbilityVariants)."""
    names: set[str] = set()
    cfg = (REPO / "Astartes" / "Config" / "XComAstartes.ini").read_text(encoding="utf-8", errors="replace")
    names |= set(re.findall(r'\+Clones=\(NewName="(\w+)"', cfg))
    for f in SRC_DIR.glob("*.uc"):
        if f.name.startswith("XMB"):
            continue
        for m in _MOD_ABILITY_RE.finditer(f.read_text(encoding="utf-8", errors="replace")):
            names.add(next(g for g in m.groups() if g))
    return names


def effective_name(slot: dict) -> str:
    return slot.get("standin") or slot["name"]


def rank_abilities(section) -> list[list[str]]:
    """For each +SoldierRanks entry, the list of AbilityName values in order."""
    return [re.findall(r'AbilityName="(\w+)"', rank) for rank in section.values("SoldierRanks")]


@pytest.fixture(scope="session")
def class_sections(all_sections):
    return {s.template_name: s for s in sections_of_class(all_sections, "X2SoldierClassTemplate")}


@pytest.fixture(scope="session")
def loc_classes(loc_sections):
    return {s.template_name: s for s in sections_of_class(loc_sections, "X2SoldierClassTemplate")}


# --- existence ------------------------------------------------------------------------------------

def test_all_marine_classes_are_defined(class_sections):
    missing = set(MARINE_CLASSES) - set(class_sections)
    assert not missing, f"soldier classes not defined in XComClassData.ini: {sorted(missing)}"


def test_classes_are_registered_in_the_deck(config):
    deck = [s for s in config["XComClassData.ini"] if s.name == "XComGame.X2SoldierClass_DefaultClasses"]
    assert deck, "missing [XComGame.X2SoldierClass_DefaultClasses]"
    registered = {unquote(v) for v in deck[0].values("SoldierClasses")}
    assert set(MARINE_CLASSES) <= registered


@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_squaddie_loadout_exists(config, class_name):
    mgr = [s for s in config["XComGameData.ini"] if s.name == "XComGame.X2ItemTemplateManager"]
    assert mgr, "missing [XComGame.X2ItemTemplateManager] in XComGameData.ini"
    names = {struct_field(v, "LoadoutName") for v in mgr[0].values("Loadouts")}
    assert f"Squaddie{class_name}" in names


# --- shape ----------------------------------------------------------------------------------------

@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_class_has_full_rank_ladder(class_sections, class_name):
    ranks = rank_abilities(class_sections[class_name])
    assert len(ranks) == EXPECTED_RANKS, f"{class_name} has {len(ranks)} ranks"
    assert len(ranks[0]) >= EXPECTED_COLUMNS, f"{class_name} squaddie row has {len(ranks[0])} abilities, expected at least {EXPECTED_COLUMNS}"
    for i, abilities in enumerate(ranks[1:], 2):
        assert len(abilities) == EXPECTED_COLUMNS, f"{class_name} rank {i} has {len(abilities)} abilities, expected {EXPECTED_COLUMNS}"


@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_config_matches_spec(class_sections, class_name):
    expected = [[effective_name(s) for s in rank] for rank in SPEC["classes"][class_name]["ranks"]]
    assert rank_abilities(class_sections[class_name]) == expected, "config drifted from class_trees.json; rerun tools/gen_class_config.py"


@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_no_duplicate_abilities_within_a_class(class_sections, class_name):
    flat = [a for rank in rank_abilities(class_sections[class_name]) for a in rank]
    dupes = sorted({a for a in flat if flat.count(a) > 1})
    assert not dupes, f"{class_name} grants the same ability twice: {dupes}"


# --- every ability must exist somewhere -----------------------------------------------------------

def optional_abilities() -> set[str]:
    """Abilities another mod provides, with a vanilla fallback declared in the spec (swapped in at template init)."""
    return {s["name"] for c in SPEC["classes"].values() for rank in c["ranks"] for s in rank if "fallback" in s}


def test_every_referenced_ability_exists(class_sections):
    known = VANILLA_ABILITIES | mod_abilities() | optional_abilities()
    unknown = sorted(
        {a for c in MARINE_CLASSES for rank in rank_abilities(class_sections[c]) for a in rank if a not in known}
    )
    assert not unknown, f"abilities referenced in config but defined nowhere: {unknown}"


def test_standins_are_vanilla_abilities():
    """A stand-in must be a vanilla ability (otherwise it is not a stand-in, it is the real thing)."""
    bad = sorted(
        {s["standin"] for c in SPEC["classes"].values() for rank in c["ranks"] for s in rank if "standin" in s and s["standin"] not in VANILLA_ABILITIES}
    )
    assert not bad, f"stand-ins that are not vanilla abilities: {bad}"


def test_new_abilities_use_mod_prefix():
    bad = sorted(
        {s["name"] for c in SPEC["classes"].values() for rank in c["ranks"] for s in rank if "standin" in s and not s["name"].startswith("Astartes_")}
    )
    assert not bad, f"new abilities must be prefixed Astartes_: {bad}"


def test_implemented_abilities_have_no_standin():
    """Once an Astartes_ ability exists in source, its stand-in must be removed from the spec."""
    implemented = mod_abilities()
    stale = sorted(
        {s["name"] for c in SPEC["classes"].values() for rank in c["ranks"] for s in rank if "standin" in s and s["name"] in implemented}
    )
    assert not stale, f"abilities implemented but still carrying a stand-in in class_trees.json: {stale}"


# --- localization ---------------------------------------------------------------------------------

@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_class_has_localization(loc_classes, class_name):
    assert class_name in loc_classes, f"no [{class_name} X2SoldierClassTemplate] block in XComGame.int"
    loc = loc_classes[class_name]
    for key in ("DisplayName", "ClassSummary", "LeftAbilityTreeTitle", "RightAbilityTreeTitle"):
        assert unquote(loc.first(key) or ""), f"{class_name}: localization key {key} is empty"
    titles = [unquote(v) for k, v in [(k, v) for _, k, v in loc.entries] if k.startswith("AbilityTreeTitles")]
    assert titles[:EXPECTED_COLUMNS] == SPEC["classes"][class_name]["columns"]
    rank_names = [unquote(v) for _, k, v in loc.entries if k.startswith("RankNames")]
    assert len(rank_names) == EXPECTED_RANKS + 1, f"{class_name}: expected 8 rank names (rookie + 7), got {len(rank_names)}"


def test_librarian_uses_librarius_rank_names(loc_classes):
    rank_names = [unquote(v) for _, k, v in loc_classes["Astartes_Librarian"].entries if k.startswith("RankNames")]
    for expected in LIBRARIUS_RANKS:
        assert expected in rank_names, f"Librarius rank '{expected}' missing from {rank_names}"


def test_implemented_new_abilities_have_localization(loc_sections):
    implemented = {n for n in mod_abilities() if n.startswith("Astartes_")}
    loc_abilities = {s.template_name for s in sections_of_class(loc_sections, "X2AbilityTemplate")}
    missing = sorted(implemented - loc_abilities)
    assert not missing, f"new abilities without a [Name X2AbilityTemplate] localization block: {missing}"


# --- the dev-command roster list must match the spec -----------------------------------------------

def test_dlcinfo_marine_class_list_matches_spec(config):
    section = [s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes"][0]
    listed = [unquote(v) for v in section.values("MarineClasses")]
    assert listed == [k for k, v in SPEC["classes"].items() if "hero" not in v and "order" not in v], "MarineClasses in XComGame.ini must list the spec Marine classes in order"


# --- shared Marine kit --------------------------------------------------------------------------

@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_every_marine_class_knows_no_fear_at_squaddie(class_sections, class_name):
    """Rank 1 is the squaddie kit (all granted). Every Marine must carry Know No Fear from the start."""
    assert "Astartes_KnowNoFear" in rank_abilities(class_sections[class_name])[0]


def test_squaddie_row_is_larger_than_the_choice_rows_is_allowed(class_sections):
    """Documenting vanilla behaviour: rank 1 grants all slots, so it may hold more than the 3 choice columns."""
    for class_name in MARINE_CLASSES:
        ranks = rank_abilities(class_sections[class_name])
        assert all(len(r) == EXPECTED_COLUMNS for r in ranks[1:]), f"{class_name}: choice rows must have exactly {EXPECTED_COLUMNS} options"


@pytest.mark.parametrize("class_name", MARINE_CLASSES)
def test_every_marine_class_has_astartes_physiology_at_squaddie(class_sections, class_name):
    assert "Astartes_Physiology" in rank_abilities(class_sections[class_name])[0]


def test_assault_and_librarian_have_no_rifle_abilities(class_sections):
    """User rule: Assault and Librarian never carry a bolter, so no rifle/cannon ability may appear in their trees."""
    rifle_only = {"HailOfBullets", "RapidFire", "Suppression", "Deadeye", "Shredder", "ChainShot", "KillZone", "HoloTargeting", "Salvo", "Demolition", "SaturationFire", "Executioner", "SteadyHands", "BulletShred", "HeavyOrdnance"}
    for class_name in ("Astartes_Assault", "Astartes_Librarian"):
        flat = {a for rank in rank_abilities(class_sections[class_name]) for a in rank}
        assert not (flat & rifle_only), f"{class_name} has rifle abilities: {sorted(flat & rifle_only)}"


def test_no_stasis_or_sustain_anywhere(class_sections):
    """User rule: stasis effects and Sustain are not lore-friendly for the Adeptus Astartes."""
    banned = {"Stasis", "StasisShield", "Sustain"}
    for class_name in MARINE_CLASSES:
        flat = {a for rank in rank_abilities(class_sections[class_name]) for a in rank}
        assert not (flat & banned), f"{class_name} uses banned abilities: {sorted(flat & banned)}"


def test_vanilla_classes_are_removed_from_the_deck(config):
    """Scouts must only promote into Marine classes."""
    deck = [s for s in config["XComClassData.ini"] if s.name == "XComGame.X2SoldierClass_DefaultClasses"][0]
    removed = {unquote(v) for op, k, v in deck.entries if k == "SoldierClasses" and op == "-"}
    assert removed >= set(SPEC["remove_from_deck"]), f"vanilla classes still in the deck: {set(SPEC['remove_from_deck']) - removed}"
    assert "Rookie" not in removed, "Rookie must stay in the deck"


def test_trigger_filters_use_target_conditions():
    """XMB SelfTargetTrigger: ability-name/property filters must go through AddTriggerTargetCondition. Shooter-side
    filters are ignored for those condition types, which let Chirurgeon's Fury re-trigger on itself until the game
    crashed (playtest 2026-10-17)."""
    offenders = []
    for f in SRC_DIR.glob("X2Ability_Astartes*.uc"):
        src = f.read_text(encoding="utf-8", errors="replace")
        if "AddTriggerShooterCondition(" in src:
            offenders.append(f.name)
        for m in re.finditer(r"SelfTargetTrigger\('(\w+)'[^;]*'AbilityActivated'\);", src):
            tail = src[m.end(): m.end() + 800]
            if "AddTriggerTargetCondition(" not in tail or f"ExcludeAbilityNames.AddItem('{m.group(1)}')" not in src:
                offenders.append(f"{f.name}: {m.group(1)} listens to AbilityActivated without a self-excluding target filter")
    assert not offenders, offenders


def test_optional_abilities_have_vanilla_fallbacks_in_config(config):
    """Every optional (other-mod) ability in the spec has a vanilla fallback, mirrored in +Fallbacks and localized."""
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_AbilityVariants"][0]
    cfg = {struct_field(v, "Ability"): struct_field(v, "Fallback") for v in section.values("Fallbacks")}
    for c in SPEC["classes"].values():
        for rank in c["ranks"]:
            for slot in rank:
                if "fallback" in slot:
                    assert slot["fallback"] in VANILLA_ABILITIES, f"{slot['name']}: fallback {slot['fallback']} is not vanilla"
                    assert cfg.get(slot["name"]) == slot["fallback"], f"{slot['name']}: config Fallbacks must mirror the spec"


def test_fallbacks_are_applied_per_unit():
    """X2SoldierClassTemplate.SoldierRanks is protected; fallbacks must rewrite the soldier's own AbilityTree on rank-up."""
    av = (SRC_DIR / "Astartes_AbilityVariants.uc").read_text(encoding="utf-8")
    cl = (SRC_DIR / "Astartes_ClassLook.uc").read_text(encoding="utf-8")
    assert "ApplyFallbacksToUnit" in av and "Unit.AbilityTree" in av
    assert "ApplyFallbacksToUnit" in cl, "the UnitRankUp listener must apply fallbacks"
    assert "SoldierRanks[" not in av, "class template ranks cannot be written from outside the class"
