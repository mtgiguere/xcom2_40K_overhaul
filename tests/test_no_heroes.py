"""No resistance faction heroes in the Chapter (docs/classes.md, decision 2026-10-18)."""
from __future__ import annotations

from conftest import REPO, SRC_DIR
from x2config import unquote

HERO_REWARDS = {"Reward_FactionSoldier", "Reward_ExtraFactionSoldier", "Reward_FindFaction", "Reward_FindFarthestFaction"}


def test_every_hero_reward_is_rewired(config):
    sec = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_NoHeroes")
    assert sec.values("bNoFactionHeroes")[0] == "true"
    assert {unquote(v) for v in sec.values("HeroRewardTemplates")} == HERO_REWARDS
    assert unquote(sec.values("RecruitCharacterTemplate")[0]) == "Soldier", "a rookie: the Marine classes take over on promotion"


def test_rewired_rewards_still_meet_the_faction_and_open_hero_slots():
    src = (SRC_DIR / "Astartes_NoHeroes.uc").read_text(encoding="utf-8")
    assert "FindDataTemplateAllDifficulties" in src, "reward templates have difficulty variants"
    assert "Reward.GenerateRewardFn = GenerateRecruitReward" in src and "Reward.GiveRewardFn = GiveRecruitReward" in src
    assert "FactionState.MeetXCom(NewGameState)" in src, "the Find Faction path must still meet the faction"
    assert "Action.Slots[j].bFactionClass = false" in src
    assert "CreatePersonnelUnit(NewGameState, default.RecruitCharacterTemplate, nmCountry, true)" in src
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "class'Astartes_NoHeroes'.static.Apply();" in dlc
    assert "Astartes_NoHeroes.uc" in (REPO / "Astartes/Astartes.x2proj").read_text(encoding="utf-8")
