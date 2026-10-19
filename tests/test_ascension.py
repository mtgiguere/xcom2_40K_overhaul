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
    assert marines == {k for k, v in SPEC["classes"].items() if "hero" not in v and "order" not in v}
    sisters = {unquote(v) for v in sec.values("AspirantSisterClasses")}
    assert sisters == {k for k, v in SPEC["classes"].items() if v.get("order") == "sororitas"} and len(sisters) == 4
    src = (SRC_DIR / "Astartes_Ascension.uc").read_text(encoding="utf-8")
    assert "AddCHEvent('FirstPromotionOverrideClass', OnFirstPromotion, ELD_Immediate)" in src
    assert "Tuple.Data[0].n != ''" in src, "never override a class someone else forced"
    assert "Unit.GetMyTemplateName() != 'Soldier'" in src, "heroes keep their own class"


def test_recruits_stay_human_and_the_start_hero_is_stripped(config):
    game = next(s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes")
    assert game.first("bMarinesByAscension") == "true"
    assert {unquote(v) for v in game.values("StripStartingCharacters")} == {"ReaperSoldier", "SkirmisherSoldier", "TemplarSoldier"}
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "XComHQ.Squad.RemoveItem(Gone[i]);" in dlc, "the starting squad list too, or LWOTC deploys the hero"
    assert "LongWarOfTheChosen" in (REPO / "Astartes/Config/XComGame.ini").read_text(encoding="utf-8"), "run before LWOTC builds its squad"
    assert "StripStartingHeroes(StartState);" in dlc and "CharacterTemplateName == 'Soldier' && default.bMarinesByAscension" in dlc


def test_guard_classes_are_lwotcs_renamed(config, loc_sections):
    sec = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_GuardClasses")
    classes = [unquote(v) for v in sec.values("GuardClasses")]
    assert "LWS_Ranger" in classes and len(classes) == 8
    assert "LWS_Shinobi" in {unquote(v) for v in sec.values("NotInRecruitDeck")}, "no melee line Guardsmen"
    loc = next(s for s in loc_sections if s.name == "Astartes_GuardClasses")
    assert len(loc.values("GuardNames")) == len(classes) == len(loc.values("GuardSummaries"))
    assert len(loc.values("GuardRankNames")) == 8 == len(loc.values("GuardShortNames"))
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "Astartes_GuardClasses'.static.Apply();" in dlc and "ApplyReskins();" in dlc


def test_sisters_take_the_veil():
    src = (SRC_DIR / "Astartes_Ascension.uc").read_text(encoding="utf-8")
    assert "TakeTheVeil(Unit);" in src and "class'Astartes_CharGen_Dressed'.static.Dress(Look, Dress);" in src
    for name, c in SPEC["classes"].items():
        if c.get("order") == "sororitas":
            assert c["ranks"][0][0]["name"] == "Astartes_Rosarius", f"{name}: every Sister wears the rosarius"


def test_recruits_are_dressed_as_cadians(config):
    game = next(s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes")
    looks = {s for s in (unquote(game.first("RecruitLookMale")), unquote(game.first("RecruitLookFemale")))}
    dressed = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_CharGen_Dressed").values("Looks")
    for name in looks:
        look = next(v for v in dressed if f'Template="{name}"' in v)
        assert "SM2Cadian_" in look and "bKeepVoice=true" in look, f"{name}: Cadian parts, own voice"
    assert "DressRecruitAsGuard(CharGen);" in (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")

