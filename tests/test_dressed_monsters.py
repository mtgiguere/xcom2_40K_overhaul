"""Dressed monsters and leaders: deathclaw daemons, the Skorge champion, the Pharah Autarch (2026-10-18)."""
from __future__ import annotations

import os
import re
from pathlib import Path

import pytest

from conftest import SRC_DIR
from x2config import struct_field

WORKSHOP = Path(os.environ.get("XCOM2_WORKSHOP", r"C:/Program Files (x86)/Steam/steamapps/workshop/content/268500"))
SOURCES = {"Astartes_Daemon": "3358025333", "Astartes_ChaosChampion": "3558395254", "Astartes_EldarAutarch": "2841395404", "Astartes_Inquisitor": "2840915275"}
FRAMES = {"Astartes_Daemon": "BLBerserkerM1", "Astartes_ChaosChampion": "BLLordM1", "Astartes_EldarAutarch": "BLBerserkerM1", "Astartes_Inquisitor": "Soldier"}


def section(config, file, name):
    return next(s for s in config[file] if s.name == name)


@pytest.mark.parametrize("unit", sorted(SOURCES))
def test_unit_is_dressed_from_its_mod(config, unit):
    variants = {struct_field(x, "NewName"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")}
    looks = {struct_field(x, "Template"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_CharGen_Dressed").values("Looks")}
    assert struct_field(variants[unit], "BaseTemplate") == FRAMES[unit]
    assert struct_field(variants[unit], "CharacterGenerator") == "Astartes.Astartes_CharGen_Dressed"
    parts = set(re.findall(r'nm(?:Head|Helmet|Torso|Arms|LeftArm|RightArm|Legs|Shins|TorsoDeco)="(\w+)"', looks[unit])) - {"EldarFemaleHead"}
    assert parts
    content = WORKSHOP / SOURCES[unit] / "Config"
    if not content.is_dir():
        pytest.skip("cosmetic mod not present")
    available = set()
    for ini in content.glob("*.ini"):
        available |= set(re.findall(r'TemplateName="(\w+)"', ini.read_text(encoding="utf-8", errors="replace")))
    assert parts <= available, f"{unit}: parts not in the mod: {parts - available}"


def test_monsters_are_bare():
    src = (SRC_DIR / "Astartes_CharGen_Dressed.uc").read_text(encoding="utf-8")
    assert "if (L.bBare)" in src and "A.nmHaircut = '';" in src


def test_autarch_carries_the_psi_blade_and_leads_incursions(config):
    variants = {struct_field(x, "NewName"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")}
    for power in ("PsiSwordDeflect", "PsiSwordReflect", "PsiSwordCounterGuard", "PsiSwordPrecognition"):
        assert power in variants["Astartes_EldarAutarch"]
    loadouts = {struct_field(x, "LoadoutName"): x for x in section(config, "XComGameData.ini", "XComGame.X2ItemTemplateManager").values("Loadouts")}
    assert "PSIBlade_MG_Primary" in loadouts["Astartes_EldarAutarch_Loadout"]
    mgr = section(config, "XComEncounterLists.ini", "XComGame.XComTacticalMissionManager")
    lists = {struct_field(v, "ListID"): v for v in mgr.values("SpawnDistributionLists")}
    assert "Astartes_EldarAutarch" in lists["Astartes_EldarCommanders"] and "Astartes_EldarAutarch" in lists["Astartes_EldarLeaders"]


def test_melee_monsters_rush(config):
    """Daemons and the Autarch hid every other turn on the Black Legion tree (playtest 2026-10-18)."""
    variants = {struct_field(x, "NewName"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")}
    for unit in ("Astartes_Daemon", "Astartes_EldarAutarch"):
        assert struct_field(variants[unit], "BehaviorTree") == "Astartes_MeleeFanatic::CharacterRoot"
    tree = section(config, "XComAI.ini", "XComGame.X2AIBTBehaviorTree").values("Behaviors")
    sel = next(b for b in tree if "Astartes_MeleeFanatic_Selector" in b and "TryStandardMeleeDashFANATICUnsafe" in b)
    assert "HuntEnemyWithCover" not in sel


def test_no_axes_on_backs(config):
    loadouts = {struct_field(x, "LoadoutName"): x for x in section(config, "XComGameData.ini", "XComGame.X2ItemTemplateManager").values("Loadouts")}
    assert "ChaosAxe" not in loadouts["Astartes_Daemon_Loadout"] and "ChaosAxe" not in loadouts["Astartes_EldarAutarch_Loadout"]


def test_monster_parts_stay_off_random_recruits(config):
    """LWOTC spike 2026-10-19: a Skirmisher grew a deathclaw tail."""
    sec = section(config, "XComAstartes.ini", "Astartes.Astartes_CharGen_Dressed")
    assert {v.strip('"') for v in sec.values("MonsterPartTokens")} >= {"Deathclaw", "Skorge"}
    gen = (SRC_DIR / "Astartes_CharGen_Dressed.uc").read_text(encoding="utf-8")
    assert "Parts[i].SpecializedType = true;" in gen
    assert "HideMonsterParts();" in (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")

