"""Chaos Sorcerer: the first enemy psyker (docs/design.md 9.1b)."""
from __future__ import annotations

import re

from conftest import REPO, SRC_DIR
from x2config import parse_ini, struct_field, unquote

FORCE_WEAPONS = [f"{n}_{t}" for n in ("ForceLightning", "ForceShock", "ForcePush", "ForcePushSecondary") for t in ("CV", "MG", "BM")]


def section(config, file, name):
    return next(s for s in config[file] if s.name == name)


def test_sorcerer_is_a_black_legion_captain_with_rift_and_perils(config):
    variants = section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")
    v = next(x for x in variants if struct_field(x, "NewName") == "Astartes_ChaosSorcerer")
    assert struct_field(v, "BaseTemplate") == "BLCaptainM1"
    assert struct_field(v, "BehaviorTree") == "Astartes_ChaosSorcerer::CharacterRoot"
    assert struct_field(v, "LoadoutOverride") == "Astartes_ChaosSorcerer_Loadout"
    assert "Astartes_OpenTheWarp" in v and "Astartes_PerilsOfTheWarp" in v


def test_sorcerer_loadout_and_warpfire(config):
    loadouts = section(config, "XComGameData.ini", "XComGame.X2ItemTemplateManager").values("Loadouts")
    lo = next(x for x in loadouts if struct_field(x, "LoadoutName") == "Astartes_ChaosSorcerer_Loadout")
    assert lo.index("Astartes_WarpLightning") < lo.index("BLCaptainM1_WPN"), "Warpfire first, the bolter only as fallback"
    weapons = section(config, "XComAstartes.ini", "Astartes.X2Item_AstartesWeapons")
    w = next(x for x in weapons.values("Weapons") if struct_field(x, "NewName") == "Astartes_WarpLightning")
    assert struct_field(w, "BaseTemplate") == "ForceLightning_MG" and struct_field(w, "bEnemyOnly") == "true"
    hidden = {unquote(x) for x in weapons.values("HideDonorItems")}
    assert set(FORCE_WEAPONS) <= hidden, "the Force Weapons items must not reach XCOM's armoury"
    src = (SRC_DIR / "X2Item_AstartesWeapons.uc").read_text(encoding="utf-8")
    assert "bEnemyOnly" in src and "Clone.StartingItem = false" in src


def test_rift_encounters_are_daemon_pods(config):
    enc = section(config, "XComEncounters.ini", "XComGame.XComTacticalMissionManager").values("ConfigurableEncounters")
    by_id = {struct_field(e, "EncounterID"): e for e in enc}
    assert by_id["Astartes_DaemonRift_Lesser"].count('"Astartes_Daemon"') == 3
    assert "Astartes_GreaterDaemon" in by_id["Astartes_DaemonRift_Greater"]
    for e in by_id.values():
        assert struct_field(e, "bGroupDoesNotAwardLoot") == "true"
    chaos = section(config, "XComAstartes.ini", "Astartes.X2Ability_Astartes_Chaos")
    tiers = {int(struct_field(r, "MinForceLevel")): struct_field(r, "EncounterID") for r in chaos.values("RiftEncounters")}
    assert tiers[1] == "Astartes_DaemonRift_Lesser" and tiers[15] == "Astartes_DaemonRift_Greater"
    assert int(chaos.values("RIFT_CHARGES")[0]) == 1


def test_sorcerer_ai_tree_is_complete(config):
    tree = section(config, "XComAI.ini", "XComGame.X2AIBTBehaviorTree")
    nodes = {unquote(struct_field(b, "BehaviorName")): b for b in tree.values("Behaviors")}
    assert "Astartes_ChaosSorcerer::CharacterRoot" in nodes
    rift = nodes["Astartes_TryOpenTheWarp"]
    for child in re.findall(r"Child\[\d+\]=([\w:-]+)", rift):
        assert child in nodes, f"{child} must be declared (generic AI nodes are config-declared)"
    profiles = section(config, "XComAI.ini", "XComGame.XGAIBehavior").values("AoEProfiles")
    assert any(struct_field(p, "Ability") == "Astartes_OpenTheWarp" for p in profiles)


def test_sorcerer_in_chaos_pods_and_rolls_perils(config):
    spawns = section(config, "XComAstartes.ini", "Astartes.Astartes_FactionConfig").values("DaemonSpawns")
    mine = [s for s in spawns if struct_field(s, "Template") == "Astartes_ChaosSorcerer"]
    assert mine and all(int(struct_field(s, "MinForceLevel")) >= 5 for s in mine), "no Sorcerers in the first missions"
    powers = section(config, "XComAstartes.ini", "Astartes.X2Ability_Astartes_Librarian").values("PsychicPowers")
    assert any(struct_field(p, "Ability") == "Astartes_OpenTheWarp" for p in powers)


def test_rift_listener_uses_the_reinforcement_system_safely():
    src = (SRC_DIR / "Astartes_RiftListener.uc").read_text(encoding="utf-8")
    assert "AddCHEvent('AbilityActivated'" in src and "AddCHEvent('UnitDied'" in src
    assert "InitiateReinforcements(EncounterID, 1, true, Location, 0, none, false, 'PsiGate'" in src, \
        "one-turn countdown, psi gate visual, and NO incoming ability game state (the spawner casts the context unguarded)"
    assert "RemoveStateObject(Spawner.ObjectID)" in src and "UnRegisterFromAllEvents(Spawner)" in src
    assert "Spawner.SpawnedUnitIDs.Length > 0" in src, "a gate that already opened must not be cancelled"


def test_daemon_prince_is_the_possession_form(config, loc_sections):
    variants = section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")
    v = next(x for x in variants if struct_field(x, "NewName") == "Astartes_DaemonPrince")
    assert struct_field(v, "BaseTemplate") == "Nemesis_T2"
    stats = parse_ini(REPO / "Astartes/Config/XComGameData_CharacterStats.ini")
    assert any(s.name == "Astartes_DaemonPrince X2CharacterTemplate" for s in stats)
    assert ("Astartes_DaemonPrince", "X2CharacterTemplate") in {(x.template_name, x.template_class) for x in loc_sections}


def test_sorcerer_has_stats_names_and_project_entries(config, loc_sections):
    stats = parse_ini(REPO / "Astartes/Config/XComGameData_CharacterStats.ini")
    assert any(s.name == "Astartes_ChaosSorcerer X2CharacterTemplate" for s in stats)
    names = {(x.template_name, x.template_class) for x in loc_sections}
    assert ("Astartes_OpenTheWarp", "X2AbilityTemplate") in names
    assert ("Astartes_ChaosSorcerer", "X2CharacterTemplate") in names
    assert ("Astartes_WarpLightning", "X2WeaponTemplate") in names
    proj = (REPO / "Astartes/Astartes.x2proj").read_text(encoding="utf-8")
    assert "X2Ability_Astartes_Chaos.uc" in proj and "Astartes_RiftListener.uc" in proj
