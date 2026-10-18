"""Perils of the Warp (docs/classes.md, Librarian).

Every psychic power in the Librarian's tree must carry a Warp Charge, the outcome table must be sane and
possession must stay the rarest outcome, and only the Librarian carries the Perils passive.
"""
from __future__ import annotations

import json
import re

import pytest

from conftest import REPO, SRC_DIR
from x2config import struct_field, unquote

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))
PERILS = "Astartes_PerilsOfTheWarp"
OUTCOMES = {
    "Astartes_Perils_WarpSurge": "PERILS_WEIGHT_WARP_SURGE",
    "Astartes_Perils_Backlash": "PERILS_WEIGHT_BACKLASH",
    "Astartes_Perils_WarpShock": "PERILS_WEIGHT_WARP_SHOCK",
    "Astartes_Perils_MentalPurge": "PERILS_WEIGHT_MENTAL_PURGE",
    "Astartes_Perils_Possession": "PERILS_WEIGHT_POSSESSION",
}


@pytest.fixture(scope="session")
def perils_cfg(config):
    sections = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Ability_Astartes_Librarian"]
    assert sections, "missing [Astartes.X2Ability_Astartes_Librarian] in XComAstartes.ini"
    return sections[0]


def librarian_abilities() -> set[str]:
    return {s.get("standin") or s["name"] for rank in SPEC["classes"]["Astartes_Librarian"]["ranks"] for s in rank}


def clone_names(config) -> set[str]:
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_AbilityVariants"][0]
    return {struct_field(v, "NewName") for v in section.values("Clones")}


def warp_charges(perils_cfg) -> dict[str, int]:
    return {struct_field(v, "Ability"): int(struct_field(v, "WarpCharge")) for v in perils_cfg.values("PsychicPowers")}


def test_only_the_librarian_knows_the_perils():
    for class_name, c in SPEC["classes"].items():
        kit = {s["name"] for s in c["ranks"][0]}
        if class_name == "Astartes_Librarian":
            assert PERILS in kit, "the Librarian must carry Perils of the Warp from squaddie"
        else:
            assert PERILS not in kit, f"{class_name} must not carry Perils of the Warp"


def test_every_psychic_power_in_the_tree_has_a_warp_charge(config, perils_cfg):
    powers = clone_names(config) & librarian_abilities()
    charges = warp_charges(perils_cfg)
    missing = sorted(powers - set(charges))
    assert not missing, f"Librarian psychic powers without a WarpCharge entry: {missing}"
    bad = {k: v for k, v in charges.items() if not 1 <= v <= 3}
    assert not bad, f"WarpCharge must be 1..3: {bad}"


def test_warp_charge_entries_point_at_tree_abilities(perils_cfg):
    stray = sorted(set(warp_charges(perils_cfg)) - librarian_abilities())
    assert not stray, f"PsychicPowers entries not in the Librarian tree: {stray}"


def test_outcome_table_is_sane(perils_cfg):
    weights = {name: int(perils_cfg.first(key) or 0) for name, key in OUTCOMES.items()}
    assert all(w > 0 for w in weights.values()), f"every outcome needs a positive weight: {weights}"
    possession = weights["Astartes_Perils_Possession"]
    assert possession <= min(weights.values()), f"possession must be the rarest outcome: {weights}"
    base = int(perils_cfg.first("PERILS_BASE_CHANCE"))
    per = int(perils_cfg.first("PERILS_CHANCE_PER_WARP_CHARGE"))
    assert 1 <= base <= 50 and 0 <= per <= 25, "Perils chance out of the sane range"


def test_daemon_tiers(perils_cfg):
    tiers = [(int(struct_field(v, "MinForceLevel")), struct_field(v, "Template")) for v in perils_cfg.values("PerilsDaemons")]
    assert tiers, "PerilsDaemons must list at least one tier"
    assert tiers[0][0] == 1, "the first daemon tier must start at force level 1 so possession always has a daemon"
    assert [t[0] for t in tiers] == sorted(t[0] for t in tiers), "tiers must be listed in ascending force level"
    assert all(t[1] for t in tiers), "every tier needs a character template"


def test_outcome_abilities_are_defined_and_carried_by_the_passive():
    src = (SRC_DIR / "X2Ability_Astartes_Librarian.uc").read_text(encoding="utf-8")
    for name in OUTCOMES:
        assert re.search(rf"HiddenSelfAbility\('{name}'", src), f"{name} is not defined"
    passive = src[src.index("static function X2AbilityTemplate PerilsOfTheWarp") : src.index("static function EventListenerReturn PerilsListener")]
    assert passive.count("AdditionalAbilities.AddItem") == len(OUTCOMES), "the passive must carry every outcome as an additional ability"


def test_lost_brothers_yield_no_geneseed():
    src = (SRC_DIR / "X2Ability_Astartes.uc").read_text(encoding="utf-8")
    assert "LostToTheWarpValueName" in src, "RecoverGeneseed must refuse a body dragged into the Warp"
