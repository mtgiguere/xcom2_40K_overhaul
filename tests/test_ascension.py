"""LWOTI recruit pipeline: Guardsmen by default, Marines by ascension (docs/design.md 7.8, docs/lwotc.md)."""
from __future__ import annotations

import json

from conftest import REPO, SRC_DIR
from x2config import unquote

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))


def test_marine_classes_are_out_of_the_recruit_deck(config):
    sections = {s.template_name: s for s in config["XComClassData.ini"] if s.template_class == "X2SoldierClassTemplate"}
    for name, c in SPEC["classes"].items():
        assert sections[name].first("NumInDeck") == "0", f"{name} must not be rolled by a recruit"


def test_gifted_recruits_ascend(config):
    sec = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_Ascension")
    assert 2 <= int(sec.first("MinComInt")) <= 4
    marines = {unquote(v) for v in sec.values("AspirantMarineClasses")}
    assert marines == {k for k, v in SPEC["classes"].items() if "hero" not in v}
    src = (SRC_DIR / "Astartes_Ascension.uc").read_text(encoding="utf-8")
    assert "AddCHEvent('FirstPromotionOverrideClass', OnFirstPromotion, ELD_Immediate)" in src
    assert "Tuple.Data[0].n != ''" in src, "never override a class someone else forced"
    assert "Unit.GetMyTemplateName() != 'Soldier'" in src, "heroes keep their own class"


def test_recruits_stay_human_and_the_start_hero_is_stripped(config):
    game = next(s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes")
    assert game.first("bMarinesByAscension") == "true"
    assert {unquote(v) for v in game.values("StripStartingCharacters")} == {"ReaperSoldier", "SkirmisherSoldier", "TemplarSoldier"}
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "StripStartingHeroes(StartState);" in dlc and "|| default.bMarinesByAscension" in dlc
