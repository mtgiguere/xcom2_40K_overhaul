"""Phase 1: the Marine roster. These start RED and go green as classes are added.

Design source: docs/design.md §4.2 (classes), §4.3 (Librarius ranks), §4.4 (uniques).
"""
import pytest

from x2config import sections_of_class, unquote

# Template names for the five player classes (design.md §4.2).
MARINE_CLASSES = {
    "Astartes_Tactical",
    "Astartes_Assault",
    "Astartes_Devastator",
    "Astartes_Apothecary",
    "Astartes_Librarian",
}

# Vanilla WotC soldier classes have 7 promotable ranks (Squaddie..Colonel); hero classes have 7 too.
EXPECTED_RANKS = 7

# Librarius rank names, in order (design.md §4.3).
LIBRARIUS_RANKS = ["Lexicanium", "Codicier", "Epistolary", "Librarian", "Chief Librarian"]


@pytest.fixture(scope="session")
def class_sections(all_sections):
    return {s.template_name: s for s in sections_of_class(all_sections, "X2SoldierClassTemplate")}


def test_all_marine_classes_are_defined(class_sections):
    missing = MARINE_CLASSES - set(class_sections)
    assert not missing, f"soldier classes not defined in XComClassData.ini: {sorted(missing)}"


@pytest.mark.parametrize("class_name", sorted(MARINE_CLASSES))
def test_class_has_full_rank_ladder(class_sections, class_name):
    section = class_sections.get(class_name)
    assert section is not None, f"{class_name} not defined"
    ranks = section.values("SoldierRanks")
    assert len(ranks) == EXPECTED_RANKS, f"{class_name} has {len(ranks)} ranks, expected {EXPECTED_RANKS}"


@pytest.mark.parametrize("class_name", sorted(MARINE_CLASSES))
def test_class_has_localization(loc_sections, class_name):
    loc = {s.template_name: s for s in sections_of_class(loc_sections, "X2SoldierClassTemplate")}
    assert class_name in loc, f"no [{class_name} X2SoldierClassTemplate] block in XComGame.int"
    for key in ("DisplayName", "ClassSummary", "LeftAbilityTreeTitle", "RightAbilityTreeTitle"):
        value = loc[class_name].first(key)
        assert value and unquote(value), f"{class_name}: localization key {key} is empty"


def test_librarian_uses_librarius_rank_names(loc_sections):
    loc = {s.template_name: s for s in sections_of_class(loc_sections, "X2SoldierClassTemplate")}
    assert "Astartes_Librarian" in loc, "Librarian localization missing"
    rank_names = [unquote(v) for v in loc["Astartes_Librarian"].values("RankNames")]
    for expected in LIBRARIUS_RANKS[:-1]:  # Chief Librarian is a unique, not a rank
        assert expected in rank_names, f"Librarius rank '{expected}' missing from RankNames {rank_names}"
