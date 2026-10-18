"""Assault Marine Jump Pack: the vanilla Icarus Jump retuned in place (its visual effects are bound to its name)."""
from __future__ import annotations

import json

from conftest import REPO, SRC_DIR
from x2config import struct_field

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))


def retune(config, base):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_AbilityVariants"][0]
    found = {struct_field(v, "BaseAbility"): v for v in section.values("Retunes")}
    assert base in found, f"no retune for {base}"
    return found[base]


def test_jump_pack_is_the_squaddie_jump_pick():
    kit = [s["name"] for s in SPEC["classes"]["Astartes_Assault"]["ranks"][0]]
    assert "IcarusJump" in kit, "the Jump Pack is the vanilla IcarusJump (renamed by localization)"


def test_jump_pack_tuning(config):
    jp = retune(config, "IcarusJump")
    assert struct_field(jp, "ActionPoints") == "1", "the jump must cost an action (Icarus Jump is free)"
    assert struct_field(jp, "bEndsTurn") == "false", "jump then strike is the whole point"
    assert struct_field(jp, "bRemoveCharges") == "true", "no per-mission charges"
    assert struct_field(jp, "bNoRulerReaction") == "true", "ruler armour abilities give Alien Rulers a free move; the jump pack must not"
    assert 1 <= int(struct_field(jp, "Cooldown")) <= 3
    assert 8 <= int(struct_field(jp, "RangeTiles")) <= 20


def test_no_source_refers_to_the_old_clone_name():
    bad = [f.name for f in SRC_DIR.glob("*.uc") if "Astartes_JumpPack" in f.read_text(encoding="utf-8", errors="replace")]
    assert not bad, f"Astartes_JumpPack no longer exists; refer to IcarusJump: {bad}"
