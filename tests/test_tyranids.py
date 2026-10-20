"""Tyranids: the Ripper swarm (user, 2026-10-19). It burrows like a Chryssalid and bursts out under the Guard.

Built on the vanilla Chryssalid, which already has the burrow abilities, animations and AI. Its bite does
damage only: no parthenogenic poison, so no cocoons. Art: the worm model as a swarm (3D_models/worm_monster.glb).
"""
from __future__ import annotations

from conftest import SRC_DIR
from x2config import struct_field, unquote


def _variant(config, name):
    sec = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_UnitVariants")
    return next(v for v in sec.values("Variants") if struct_field(v, "NewName") == name)


def test_ripper_swarm_is_a_burrowing_chryssalid_without_cocoons(config):
    v = _variant(config, "Astartes_RipperSwarm")
    assert struct_field(v, "BaseTemplate") == "Chryssalid", "the Chryssalid brings burrow, ambush and its AI"
    assert struct_field(v, "RemoveAbilities[0]") == "ChyssalidPoison", "the poison passive's icon goes"
    tyr = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_Tyranids")
    assert "Astartes_RipperSwarm" in [unquote(x) for x in tyr.values("NoCocoonAttackers")]


def test_ripper_swarm_is_fast_and_fragile(config):
    stats = next(s for s in config["XComGameData_CharacterStats.ini"] if s.name == "Astartes_RipperSwarm X2CharacterTemplate")
    assert int(stats.first("CharacterBaseStats[eStat_HP]")) <= 4
    assert int(stats.first("CharacterBaseStats[eStat_Mobility]")) >= 14


def test_ripper_swarm_spawns_early_on_tyranid_worlds(config):
    lists = next(s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager")
    followers = next(v for v in lists.values("SpawnDistributionLists") if struct_field(v, "ListID") == "Astartes_TyranidFollowers")
    i = followers.index('Template="Astartes_RipperSwarm"')
    entry = followers[i:followers.index(")", i)]
    assert struct_field(entry, "MinForceLevel") == "1"


def test_ripper_swarm_is_named(loc_sections):
    sec = next(s for s in loc_sections if s.name == "Astartes_RipperSwarm X2CharacterTemplate")
    assert unquote(sec.first("strCharacterName")) == "Ripper Swarm"


def test_cocoon_poison_skips_listed_attackers():
    variants = (SRC_DIR / "Astartes_UnitVariants.uc").read_text(encoding="utf-8")
    assert "var array<name> RemoveAbilities;" in variants
    tyr = (SRC_DIR / "Astartes_Tyranids.uc").read_text(encoding="utf-8")
    assert "X2Effect_ParthenogenicPoison" in tyr and "TargetConditions.AddItem(" in tyr
    cond = (SRC_DIR / "X2Condition_Astartes_SourceNotTemplate.uc").read_text(encoding="utf-8")
    assert "CallMeetsConditionWithSource" in cond
    dlc = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert "class'Astartes_Tyranids'.static.Apply();" in dlc
