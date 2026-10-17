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
MARINE_CLASSES = sorted(SPEC["classes"])
EXPECTED_RANKS = 7
EXPECTED_COLUMNS = 3
LIBRARIUS_RANKS = ["Lexicanium", "Codicier", "Epistolary", "Librarian"]

VANILLA_ABILITIES = set((REPO / "tests" / "data" / "vanilla_abilities.txt").read_text(encoding="utf-8").split())

_MOD_ABILITY_RE = re.compile(
    r"""(?:CreateTemplate\s*\(\s*class'X2AbilityTemplate'\s*,\s*'(\w+)'|CREATE_X2ABILITY_TEMPLATE\s*\(\s*\w+\s*,\s*'(\w+)'|PurePassive\s*\(\s*'(\w+)')"""
)


def mod_abilities() -> set[str]:
    names: set[str] = set()
    for f in SRC_DIR.glob("*.uc"):
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

def test_every_referenced_ability_exists(class_sections):
    known = VANILLA_ABILITIES | mod_abilities()
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
    assert listed == list(SPEC["classes"]), "MarineClasses in XComGame.ini must list the spec classes in order"


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
