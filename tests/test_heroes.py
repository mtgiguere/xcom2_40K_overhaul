"""Imperial heroes: the Canoness and the Commissar (docs/design.md 9.1f)."""
from __future__ import annotations

import json
import re

from conftest import REPO, SRC_DIR
from x2config import parse_ini, struct_field, unquote

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))
HEROES = {k: v for k, v in SPEC["classes"].items() if "hero" in v}


def section(config, file, name):
    return next(s for s in config[file] if s.name == name)


def test_heroes_and_their_factions():
    assert {v["hero"]["character"] for v in HEROES.values()} == {"Astartes_Canoness", "Astartes_Commissar", "Astartes_Inquisitor"}
    assert {v["hero"].get("faction") for v in HEROES.values()} == {"Faction_Templars", "Faction_Skirmishers", None}, "the Inquisitor is never a faction reward"


def test_hero_classes_stay_out_of_the_deck(class_sections_raw):
    for name, c in HEROES.items():
        sec = class_sections_raw[name]
        assert sec.first("NumInDeck") == "0" and sec.first("NumInForcedDeck") == "0" and sec.first("bAllowAWCAbilities") == "0"
        assert unquote(sec.first("RequiredCharacterClass")) == c["hero"]["character"]


def test_hero_characters_exist_dressed_and_rewarded(config, loc_sections):
    variants = {struct_field(x, "NewName"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")}
    looks = {struct_field(x, "Template"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_CharGen_Dressed").values("Looks")}
    rewards = {struct_field(x, "Faction"): struct_field(x, "Character") for x in section(config, "XComAstartes.ini", "Astartes.Astartes_NoHeroes").values("HeroCharacters")}
    stats = {s.name for s in parse_ini(REPO / "Astartes/Config/XComGameData_CharacterStats.ini")}
    names = {(x.template_name, x.template_class) for x in loc_sections}
    for cls, c in HEROES.items():
        ch = c["hero"]["character"]
        v = variants[ch]
        assert struct_field(v, "BaseTemplate") == "Soldier" and struct_field(v, "DefaultSoldierClass") == cls
        assert struct_field(looks[ch], "bKeepName") == "true" and struct_field(looks[ch], "nmVoice")
        if c["hero"].get("faction"):
            assert rewards[c["hero"]["faction"]] == ch
        else:
            assert ch not in rewards.values()
        assert f"{ch} X2CharacterTemplate" in stats and (ch, "X2CharacterTemplate") in names


def test_summary_execution_targets_the_wavering_on_either_side():
    src = (SRC_DIR / "X2Ability_Astartes_Heroes.uc").read_text(encoding="utf-8")
    body = src[src.index("static function X2AbilityTemplate SummaryExecution"):]
    body = body[: body.index("\n}\n")]
    assert "ExcludeFriendlyToSource = false" in body and "ExcludeHostileToSource = false" in body, "friend or foe (user, 2026-10-18)"
    assert "X2Condition_Astartes_Wavering" in body and "X2Effect_Executed" in body and "default.DeadEye" in body
    cond = (SRC_DIR / "X2Condition_Astartes_Wavering.uc").read_text(encoding="utf-8")
    assert "IsPanicked()" in cond and "IsMindControlled()" in cond
    comm = SPEC["classes"]["Astartes_Commissar"]["ranks"][0]
    assert {"name": "Astartes_SummaryExecution", "slot": "secondary"} in comm, "fired from the bolt pistol"


def test_clones_carry_soldier_plumbing():
    uv = (SRC_DIR / "Astartes_UnitVariants.uc").read_text(encoding="utf-8")
    for field in ("bStaffingAllowed", "bUsesWillSystem", "bCanBeCriticallyWounded", "CustomizationManagerClass", "UICustomizationMenuClass"):
        assert f"T.{field} = Base.{field};" in uv, field
