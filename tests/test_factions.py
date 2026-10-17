"""Continent faction ownership config (design.md 7.1b)."""
import re

import pytest

from conftest import SRC_DIR
from x2config import struct_field, unquote

REQUIRED_FACTIONS = {"Orks", "Chaos", "Tyranids"}
CONTINENTS = {"Continent_NorthAmerica", "Continent_SouthAmerica", "Continent_Europe", "Continent_Africa", "Continent_Asia", "Continent_Oceania"}


@pytest.fixture(scope="session")
def faction_section(config):
    sections = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_FactionConfig"]
    assert sections, "missing [Astartes.Astartes_FactionConfig] in XComAstartes.ini"
    return sections[0]


@pytest.fixture(scope="session")
def factions(faction_section):
    return {struct_field(v, "FactionName"): v for v in faction_section.values("Factions")}


def test_feature_is_enabled(faction_section):
    assert unquote(faction_section.first("bEnableContinentFactions") or "").lower() == "true"


def test_all_three_territorial_factions_defined(factions):
    assert REQUIRED_FACTIONS <= set(factions), f"missing factions: {REQUIRED_FACTIONS - set(factions)}"


@pytest.mark.parametrize("faction", sorted(REQUIRED_FACTIONS))
def test_faction_has_leader_follower_lists_and_dlc(factions, faction):
    v = factions[faction]
    for field in ("LeaderList", "FollowerList", "RequiredDLC"):
        assert struct_field(v, field), f"{faction}: {field} missing"
    assert struct_field(v, "LeaderList") != struct_field(v, "FollowerList")


def test_overrides_reference_real_continents_and_factions(faction_section, factions):
    for v in faction_section.values("ContinentFactionOverrides"):
        assert struct_field(v, "Continent") in CONTINENTS, v
        assert struct_field(v, "FactionName") in factions, v


def test_pod_rewrite_skips_special_pods():
    """Chosen / VIP / objective pods carry a StrategyUnitTag and must never be replaced; only the alien team is rewritten."""
    src = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    body = src[src.index("static function RewritePodForContinent"):]
    body = body[: body.index("\n}\n")]
    assert "StrategyUnitTag != ''" in body
    assert "Encounter.Team != eTeam_Alien" in body


def test_faction_spawn_lists_exist_in_the_faction_mods(factions):
    """The list IDs we point at must exist in the installed faction mods' XComEncounterLists.ini."""
    import os
    from pathlib import Path
    workshop = Path(os.environ.get("XCOM2_WORKSHOP", r"C:/Program Files (x86)/Steam/steamapps/workshop/content/268500"))
    if not workshop.is_dir():
        pytest.skip("workshop folder not present")
    available = set()
    from conftest import CONFIG_DIR
    for ini in list(workshop.glob("*/Config/XComEncounterLists.ini")) + [CONFIG_DIR / "XComEncounterLists.ini"]:
        available |= set(re.findall(r'ListID="(\w+)"', ini.read_text(encoding="utf-8", errors="replace")))
    missing = {struct_field(v, f) for v in factions.values() for f in ("LeaderList", "FollowerList")} - available
    assert not missing, f"spawn lists not found in any installed mod: {sorted(missing)}"


def test_our_lists_cover_every_force_level(config):
    """Our own faction lists must have at least one leader and one follower eligible at every force level 1..20."""
    mgr = [s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager"]
    assert mgr, "missing spawn lists"
    lists = {struct_field(v, "ListID"): v for v in mgr[0].values("SpawnDistributionLists")}
    ours = [k for k in lists if k.startswith("Astartes_")]
    assert len(ours) >= 4, f"expected our own faction lists, found {ours}"
    for list_id in ours:
        entries = re.findall(r'MinForceLevel=(\d+),\s*MaxForceLevel=(\d+)', lists[list_id])
        for fl in range(1, 21):
            assert any(int(lo) <= fl <= int(hi) for lo, hi in entries), f"{list_id}: nothing eligible at force level {fl}"
