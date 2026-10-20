"""The opening rescue (user, 2026-10-19): only the four Marines drop in, and the garrison's Guardsmen join them.

A haven rebel on a retaliation is an unarmed civilian. When one of our soldiers reaches them, they take up a lasgun:
the civilian leaves play (LWOTC counts them as saved) and a real Guard recruit with their face and name joins the
squad under our control. Recruits that join this way are flagged as spawned from the Avenger, so the game moves
them into the barracks after the mission.
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
    assert 1 <= int(sec.first("RescueRadiusTiles")) <= 4
    assert unquote(sec.first("JoinTemplate")) == "Soldier"
    assert unquote(sec.first("JoinLoadout")) == "RookieSoldier", "lasgun and flak, the Guard's kit"


def test_rescue_listener_turns_civilians_into_recruits():
    src = (SRC_DIR / "Astartes_GarrisonRescue.uc").read_text(encoding="utf-8")
    assert "AddCHEvent('UnitMoveFinished'" in src and "RegisterInTactical = true" in src
    assert "RemoveStateFromPlay()" in src and "X2Action_RemoveUnit" in src
    assert "bSpawnedFromAvenger = true" in src, "the post-mission transfer then moves them into the barracks"
    assert "AddToCrew(" in src and "ApplyInventoryLoadout(" in src and "InitializeUnitAbilities(" in src
    assert "eTeam_Neutral" in src, "only civilians still waiting to be saved"
    proj = (SRC_DIR.parent.parent.parent / "Astartes.x2proj").read_text(encoding="utf-8")
    assert "Astartes_GarrisonRescue.uc" in proj


def test_rescue_is_localized(loc_sections):
    sec = next(s for s in loc_sections if s.name == "Astartes_GarrisonRescue")
    assert sec.first("JoinsTheFightText")
