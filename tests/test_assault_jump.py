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
    bad = [f.name for f in SRC_DIR.glob("*.uc") if "'Astartes_JumpPack'" in f.read_text(encoding="utf-8", errors="replace")]
    assert not bad, f"Astartes_JumpPack no longer exists; refer to IcarusJump: {bad}"


def test_jump_arc_is_configured(config):
    """Both jumps visualize through the arc action, with real vanilla animation names."""
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Ability_Astartes_Assault"][0]
    jumps = {v.strip().strip('"') for v in section.values("JumpAbilities")}
    assert {"IcarusJump", "Astartes_DeepJump"} <= jumps
    for key in ("JUMP_ARC_HEIGHT_TILES", "JUMP_SECONDS_PER_TILE", "JUMP_MIN_FLIGHT_SECONDS", "JUMP_MAX_FLIGHT_SECONDS"):
        assert float(section.first(key)) > 0, f"{key} must be set"
    assert "XComPrecomputedPath" not in (SRC_DIR / "X2Action_Astartes_JumpPack.uc").read_text(encoding="utf-8"), "the shared grenade path sent the jump to the world origin; compute the arc ourselves"
    for key in ("JUMP_ANIM_START", "JUMP_ANIM_LOOP", "JUMP_ANIM_STOP"):
        assert (section.first(key) or "").strip('"'), f"{key} must name an animation"
        assert not (section.first(key) or "").strip('"').startswith("MV_"), f"{key}: vanilla MV_ climb/fall animations carry root motion and drag the pawn to the origin"
    assert (SRC_DIR / "X2Action_Astartes_JumpPack.uc").exists()
    assault = (SRC_DIR / "X2Ability_Astartes_Assault.uc").read_text(encoding="utf-8")
    assert "RewireJumpVisuals" in assault and "JumpPack_BuildVisualization" in assault


def test_jump_never_enables_root_motion():
    src = (SRC_DIR / "X2Action_Astartes_JumpPack.uc").read_text(encoding="utf-8")
    assert "EnableRMA(true" not in src, "root motion on during the jump let animations drag the pawn to the world origin"
    assert "CanPlayAnimation" in src, "animations must be optional: the pack that ships them may be absent"


def test_jump_visualization_has_no_cover_bracket():
    """X2Action_EnterCover restores Unit.RestoreLocation, zero when the jumper stood in the open: world-origin teleport."""
    src = (SRC_DIR / "X2Ability_Astartes_Assault.uc").read_text(encoding="utf-8")
    start = src.index("function JumpPack_BuildVisualization")
    end = src.index("\n}\n", start)
    vis = src[start:end]
    assert "X2Action_EnterCover'.static" not in vis, "EnterCover after the jump teleports the pawn to the origin"
    assert "X2Action_ExitCover'.static" not in vis


def test_jump_effects_come_from_vanilla_alien_hunters(config):
    """Jet sounds and flames are Icarus Suit assets (DLC content everyone with WotC owns), not another mod's."""
    sec = next(x for x in config["XComAstartes.ini"] if x.name == "Astartes.X2Ability_Astartes_Assault")
    for key in ("JUMP_TAKEOFF_SOUND", "JUMP_FLIGHT_SOUND", "JUMP_LAND_SOUND"):
        assert sec.values(key)[0].strip('"').startswith("DLC_60_SoundCharacterFX."), key
    for key in ("JUMP_TAKEOFF_FX", "JUMP_LAND_FX"):
        assert sec.values(key)[0].strip('"').startswith("DLC_2_FX_Icarus_Suit."), key
    thrusters = sec.values("JUMP_THRUSTERS")
    assert len(thrusters) == 2 and all(struct_field(t, "FX").startswith("DLC_2_FX_Icarus_Suit.") for t in thrusters)
    assert sec.values("JUMP_SOUND_CUE")[0].strip('"') == "", "the Jedi ignition cue is no longer a dependency"


def test_jump_thrusters_are_guarded_and_stop_on_landing():
    src = (SRC_DIR / "X2Action_Astartes_JumpPack.uc").read_text(encoding="utf-8")
    assert "DynamicLoadObject(Path, class'AkEvent')" in src and "DynamicLoadObject(Path, class'ParticleSystem')" in src
    loaders = src[src.index("private function AkEvent LoadSound"):src.index("private function PlayJumpSound")]
    assert loaders.count("== none") >= 2, "every asset load must tolerate a missing asset"
    assert "if (Event != none)" in src and "if (System != none)" in src
    landing = src.index("// landing")
    assert "StopThrusters();" in src[landing:], "thruster flames must be switched off when the Marine lands"
    assert "DeactivateSystem()" in src
