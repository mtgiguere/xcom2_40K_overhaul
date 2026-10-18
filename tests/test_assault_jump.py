"""Assault Marine Jump Pack: a retuned clone of the Alien Hunters Icarus Jump."""
from __future__ import annotations

import json

from conftest import REPO
from x2config import struct_field

SPEC = json.loads((REPO / "tests" / "data" / "class_trees.json").read_text(encoding="utf-8"))


def jump_pack(config):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_AbilityVariants"][0]
    clones = {struct_field(v, "NewName"): v for v in section.values("Clones")}
    assert "Astartes_JumpPack" in clones, "Astartes_JumpPack clone missing"
    return clones["Astartes_JumpPack"]


def test_jump_pack_is_the_squaddie_jump_pick():
    kit = SPEC["classes"]["Astartes_Assault"]["ranks"][0]
    jp = [s for s in kit if s["name"] == "Astartes_JumpPack"]
    assert jp, "Jump Pack must be in the Assault squaddie kit"
    assert "standin" not in jp[0], "Jump Pack is implemented; drop the stand-in"


def test_jump_pack_tuning(config):
    jp = jump_pack(config)
    assert struct_field(jp, "BaseAbility") == "IcarusJump"
    assert struct_field(jp, "ActionPoints") == "1", "the jump must cost an action (Icarus Jump is free)"
    assert struct_field(jp, "bEndsTurn") == "false", "jump then strike is the whole point"
    assert struct_field(jp, "bRemoveCharges") == "true", "no per-mission charges"
    assert struct_field(jp, "bNoRulerReaction") == "true", "ruler armour abilities give Alien Rulers a free move; the jump pack must not"
    assert 1 <= int(struct_field(jp, "Cooldown")) <= 3
    assert 8 <= int(struct_field(jp, "RangeTiles")) <= 20
