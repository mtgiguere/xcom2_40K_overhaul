"""Chapter Master (design.md 4.4) and daemons in Chaos pods."""
from __future__ import annotations

import json

from conftest import REPO, SRC_DIR
from x2config import struct_field, unquote

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))


def section(config, name):
    found = [s for s in config["XComAstartes.ini"] if s.name == name]
    assert found, f"missing [{name}]"
    return found[0]


def test_capstones_belong_to_marine_classes_and_exist(config, loc_sections):
    cm = section(config, "Astartes.Astartes_ChapterMaster")
    caps = {struct_field(v, "SoldierClass"): struct_field(v, "Ability") for v in cm.values("Capstones")}
    assert caps, "at least one capstone"
    assert set(caps) <= set(SPEC["classes"]), f"capstone for unknown class: {set(caps) - set(SPEC['classes'])}"
    src = "".join(f.read_text(encoding="utf-8", errors="replace") for f in SRC_DIR.glob("X2Ability_Astartes*.uc"))
    loc = {s.template_name for s in loc_sections if s.template_class == "X2AbilityTemplate"}
    for ability in caps.values():
        assert f"'{ability}'" in src, f"{ability} is not defined"
        assert ability in loc, f"{ability} has no localization"
    assert int(cm.first("CHAPTER_MASTER_MIN_RANK")) == len(SPEC["classes"]["Astartes_Assault"]["ranks"]), "only the top rank may be appointed"


def test_capstones_are_not_in_the_class_trees():
    """The relic ability is granted by appointment, never bought on the promotion screen."""
    tree = {s["name"] for c in SPEC["classes"].values() for rank in c["ranks"] for s in rank}
    assert "Astartes_DeathIncarnate" not in tree


def test_daemon_spawns_point_at_our_variants_and_real_lists(config):
    fc = section(config, "Astartes.Astartes_FactionConfig")
    spawns = list(fc.values("DaemonSpawns"))
    assert spawns, "expected daemon spawn entries"
    variants = {struct_field(v, "NewName") for v in section(config, "Astartes.Astartes_UnitVariants").values("Variants")}
    mgr = [s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager"][0]
    lists = {struct_field(v, "ListID") for v in mgr.values("SpawnDistributionLists")}
    for v in spawns:
        assert struct_field(v, "Template") in variants, "daemon spawns must use our variant templates (skipped safely when absent)"
        assert struct_field(v, "ListID") in lists, f"unknown spawn list {struct_field(v, 'ListID')}"
        assert int(struct_field(v, "MinForceLevel")) >= 9, "no daemons in the first months' Chaos pods"


def seats(config):
    cm = section(config, "Astartes.Astartes_ChapterMaster")
    return {struct_field(v, "Seat"): v for v in cm.values("Seats")}


def test_three_unique_seats_with_lore_rules(config, loc_sections):
    """Chapter Master, Chief Librarian and Master of Sanctity are separate seats (user rule 2026-10-18)."""
    s = seats(config)
    assert set(s) == {"ChapterMaster", "ChiefLibrarian", "MasterOfSanctity"}
    cm = s["ChapterMaster"]
    assert struct_field(cm, "bCapstoneByClass") == "true"
    assert "Astartes_Librarian" in cm and "Astartes_Chaplain" in cm, "Librarians and Chaplains never hold the Chapter Master's seat"
    assert struct_field(s["ChiefLibrarian"], "RequiredClass") == "Astartes_Librarian"
    assert struct_field(s["ChiefLibrarian"], "Ability") == "Astartes_WarpMastery"
    assert struct_field(s["MasterOfSanctity"], "RequiredClass") == "Astartes_Chaplain"
    assert struct_field(s["MasterOfSanctity"], "Ability") == "Astartes_LitanyOfTheDevout"
    src = "".join(f.read_text(encoding="utf-8", errors="replace") for f in SRC_DIR.glob("X2Ability_Astartes*.uc"))
    loc = {x.template_name for x in loc_sections if x.template_class == "X2AbilityTemplate"}
    for seat, v in s.items():
        ability = struct_field(v, "Ability")
        if ability:
            assert f"'{ability}'" in src and ability in loc, f"{seat} relic {ability} must exist and be localized"
    caps = {struct_field(v, "SoldierClass") for v in section(config, "Astartes.Astartes_ChapterMaster").values("Capstones")}
    assert "Astartes_Librarian" not in caps and "Astartes_Chaplain" not in caps


def test_reclusiarch_rank_grant(config, loc_sections):
    """Rank-7 Chaplains are Reclusiarchs: the rank name says so and Purge the Unclean is granted."""
    cl = section(config, "Astartes.Astartes_ClassLook")
    grants = {(struct_field(v, "SoldierClass"), int(struct_field(v, "Rank"))): struct_field(v, "Ability") for v in cl.values("RankGrants")}
    assert grants.get(("Astartes_Chaplain", 7)) == "Astartes_PurgeTheUnclean"
    assert SPEC["rank_names"]["reclusiam"][7] == "Reclusiarch"
    assert SPEC["classes"]["Astartes_Chaplain"]["rank_set"] == "reclusiam"
    loc = {x.template_name for x in loc_sections if x.template_class == "X2AbilityTemplate"}
    assert "Astartes_PurgeTheUnclean" in loc and "Astartes_OrbitalBombardment" in loc


def test_librarian_carries_sword_pistol_and_hood(config):
    """The hood has its own Highlander slot (eInvSlot_PsiAmp); the Librarian's powers hang off it."""
    lib = SPEC["classes"]["Astartes_Librarian"]
    assert lib["loadout"] == ["Astartes_ForceSword_CV_Primary", "Astartes_BoltPistol_CV", "Astartes_PsychicHood_CV"]
    assert ["eInvSlot_PsiAmp", "psiamp"] in lib["weapons"]
    slots = section(config, "Astartes.Astartes_ItemSlots")
    assert "Astartes_Librarian" in {unquote(v) for v in slots.values("HoodSlotClasses")}
    weapons = section(config, "Astartes.X2Item_AstartesWeapons")
    hoods = [v for v in weapons.values("Weapons") if struct_field(v, "NewName").startswith("Astartes_PsychicHood_")]
    assert hoods and all("eInvSlot_PsiAmp" in v for v in hoods)
    assert not any(s.get("slot") == "secondary" for rank in lib["ranks"] for s in rank), "Librarian powers must bind to the hood slot"
