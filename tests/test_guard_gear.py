"""The Guard's kit, lore-first (user, 2026-10-19).

* Every Guard gun is a las weapon: XCOM's rifle is the lasgun, its shotgun the hot-shot (the Storm Trooper's close-range
  hellgun), its sniper rifle the long-las. The weapon categories (and the LWOTC class abilities keyed to them) stay.
* Guardsmen never carry Astartes wargear (bolters, chainswords, narthecia...). Eldar weapons are enemy-only already.
* Gremlins are servo-skulls.
* No Shinobi: a Guardsman's first promotion is drawn from the allowed Guard classes, whatever LWOTC's deck says.
"""
from __future__ import annotations

from conftest import SRC_DIR
from x2config import struct_field, unquote


def _sec(config, file, name):
    return next(s for s in config[file] if s.name == name)


def _reskins(config):
    sec = _sec(config, "XComAstartes.ini", "Astartes.X2Item_AstartesWeapons")
    return {struct_field(v, "Target"): struct_field(v, "Donor") for v in sec.values("Reskins")}


def test_every_guard_gun_is_a_las_weapon(config):
    r = _reskins(config)
    for tier in ("CV", "MG", "BM"):
        assert r[f"AssaultRifle_{tier}"] == "Lasgun"
        assert r[f"Shotgun_{tier}"] == "HotshotLasgun", "the Storm Trooper's hot-shot"
        assert r[f"SniperRifle_{tier}"] == "Lasgun", "the long-las"


def test_gremlins_are_servo_skulls(config):
    r = _reskins(config)
    for tier in ("CV", "MG", "BM"):
        assert r[f"Gremlin_{tier}"] == f"Servoskull_{tier}"


def test_guardsmen_cannot_take_astartes_wargear(config, loc_sections):
    game = _sec(config, "XComGame.ini", "Astartes.X2DownloadableContentInfo_Astartes")
    assert [unquote(v) for v in game.values("WargearPrefixes")] == ["Astartes_"]
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "static function bool CanAddItemToInventory_CH_Improved(" in dlc
    assert "IsAstartesSoldier(UnitState)" in dlc
    sec = next(s for s in loc_sections if s.name == "X2DownloadableContentInfo_Astartes")
    assert sec.first("WargearNotForGuardText")


def test_guardsmen_are_promoted_into_allowed_guard_classes():
    src = (SRC_DIR / "Astartes_Ascension.uc").read_text(encoding="utf-8")
    assert "class'Astartes_GuardClasses'.static.RecruitClasses()" in src
    guard = (SRC_DIR / "Astartes_GuardClasses.uc").read_text(encoding="utf-8")
    assert "static function array<name> RecruitClasses()" in guard
    assert "default.NotInRecruitDeck.Find(" in guard
