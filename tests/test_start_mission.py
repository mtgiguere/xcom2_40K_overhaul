"""LWOTI opening mission: the strike force relieves a Guard garrison under attack (user, 2026-10-19).

LWOTC's first mission is Troop Maneuvers. We swap it for LWOTC's retaliation (Terror_LW): the starting region's
haven rebels, dressed as Guardsmen, are on the map and the aliens are killing them.
"""
from __future__ import annotations

from conftest import SRC_DIR
from x2config import struct_field, unquote

START = "MissionSource_Start"


def _start_entries(section, op):
    return [struct_field(v, "MissionFamily") for o, k, v in section.entries
            if k == "arrSourceRewardMissionTypes" and o == op and struct_field(v, "MissionSource") == START]


def test_config_offers_the_rescue_and_drops_lwotc_start_families(config):
    sec = next(s for s in config["XComMissionSources.ini"] if s.name == "XComGame.XComTacticalMissionManager")
    assert _start_entries(sec, "+") == ["Terror_LW"]
    assert {"TroopManeuvers_LW", "SabotageCC"} <= set(_start_entries(sec, "-"))


def test_start_family_is_configured(config):
    game = next(s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes")
    assert unquote(game.first("StartMissionFamily")) == "Terror_LW"


def test_campaign_start_rebuilds_the_first_mission():
    """Config merge order against LWOTC isn't guaranteed, so the start site itself excludes every other family."""
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "SetStartMission(StartState);" in dlc
    assert "ExcludeMissionFamilies" in dlc, "a later rebuild (LWOTC hybrid difficulty) must keep the exclusions"
    assert "SetMissionData(" in dlc
