"""The opening rescue (user, 2026-10-19/20): only the four Marines drop in, and the garrison's Guardsmen fight beside them.

LWOTC's own retaliation rescue is kept as it is: a rebel our soldier reaches comes under our control (and counts as
rescued). We only arm them: when a rescued rebel switches to our team they get a lasgun and its shot, overwatch and
reload abilities. (A first version replaced the rebel with a new recruit; the rebels vanished and the rescue count
stayed at zero in play, 2026-10-20.)
"""
from __future__ import annotations

from conftest import SRC_DIR
from x2config import unquote


def _sec(config, file, name):
    return next(s for s in config[file] if s.name == name)


def test_first_squad_is_only_the_strike_force(config):
    game = _sec(config, "XComGame.ini", "Astartes.X2DownloadableContentInfo_Astartes")
    assert game.first("bStrikeForceOnly").lower() == "true"
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "if (default.bStrikeForceOnly)" in dlc and "XComHQ.Squad.Length = Placed;" in dlc


def test_rescue_config(config):
    sec = _sec(config, "XComAstartes.ini", "Astartes.Astartes_GarrisonRescue")
    assert {unquote(v) for v in sec.values("Missions")} >= {"Terror_LW", "Defend_LW"}
    assert [unquote(v) for v in sec.values("RescueTemplates")] == ["Rebel"], "never a hidden Faceless"
    assert unquote(sec.first("GarrisonWeapon")) == "AssaultRifle_CV", "XCOM's rifle is the Guard's lasgun"
    for gone in ("RescueRadiusTiles", "JoinTemplate", "JoinLoadout"):
        assert sec.first(gone) is None


def test_rescued_rebels_are_armed_not_replaced():
    src = (SRC_DIR / "Astartes_GarrisonRescue.uc").read_text(encoding="utf-8")
    assert "AddCHEvent('UnitChangedTeam'" in src and "RegisterInTactical = true" in src
    assert "AddItemToInventory(" in src and "eInvSlot_PrimaryWeapon" in src
    assert "InitAbilityForUnit(" in src, "the lasgun's shot, overwatch and reload"
    assert "ApplyLoadoutFromGameState(" in src, "the gun shows in their hands"
    assert "eTeam_XCom" in src
    for gone in ("RemoveStateFromPlay()", "CreateInstanceFromTemplate(NewGameState);\n\tLook", "bSpawnedFromAvenger"):
        assert gone not in src, "LWOTC's rescue stays untouched"


def test_rescue_is_localized(loc_sections):
    sec = next(s for s in loc_sections if s.name == "Astartes_GarrisonRescue")
    assert sec.first("JoinsTheFightText")


def test_lwotc_pod_diversity_is_off(config):
    """LWOTC's diversity pass re-rolled duplicate followers from the encounter's own (ADVENT) list after our faction
    rewrite: an ADVENT trooper in a Chaos pod (playtest, 2026-10-20). Our faction lists set the mix instead."""
    sec = _sec(config, "XComLW_Overhaul.ini", "LW_Overhaul.X2DownloadableContentInfo_LongWarOfTheChosen")
    assert sec.first("bDisableDiversitySystem").lower() == "true"
