"""Eldar Warlock and the Eldar faction (docs/design.md 9.1d)."""
from __future__ import annotations

import os
import re
from pathlib import Path

import pytest

from conftest import REPO, SRC_DIR
from x2config import parse_ini, struct_field, unquote

WORKSHOP = Path(os.environ.get("XCOM2_WORKSHOP", r"C:/Program Files (x86)/Steam/steamapps/workshop/content/268500"))


def section(config, file, name):
    return next(s for s in config[file] if s.name == name)


def test_warlock_is_a_dressed_soldier_body(config):
    variants = section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")
    v = next(x for x in variants if struct_field(x, "NewName") == "Astartes_EldarWarlock")
    assert struct_field(v, "BaseTemplate") == "BLCaptainM1"
    assert struct_field(v, "bAppearanceDefinesPawn") == "true"
    assert struct_field(v, "CharacterGenerator") == "Astartes.Astartes_CharGen_Dressed"
    assert struct_field(v, "BehaviorTree") == "Astartes_EldarWarlock::CharacterRoot"
    for power in ("Mindspin", "Stasis", "Astartes_PerilsOfTheWarp"):
        assert power in v, f"the Warlock needs {power}"


def test_warlock_look_names_real_eldar_parts(config):
    looks = section(config, "XComAstartes.ini", "Astartes.Astartes_CharGen_Dressed").values("Looks")
    look = next(x for x in looks if struct_field(x, "Template") == "Astartes_EldarWarlock")
    parts = {k: struct_field(look, k) for k in ("nmHead", "nmHelmet", "nmTorso", "nmArms", "nmLegs", "nmTorsoDeco", "nmThighs", "nmFacePropLower", "nmFacePropUpper")}
    assert all(parts.values()), parts
    assert struct_field(look, "Gender") == "1", "male parts (_M) need a male body"
    assert all(p.endswith("_M") or p == "EldarMaleHead" for p in parts.values()), parts
    content = WORKSHOP / "1872771143" / "Config" / "XComContent.ini"
    if not content.is_file():
        pytest.skip("EldarArmor mod not present")
    available = set(re.findall(r'TemplateName="(\w+)"', content.read_text(encoding="utf-8", errors="replace")))
    missing = set(parts.values()) - available
    assert not missing, f"parts not in EldarArmor: {missing}"


def test_dressing_generator_overrides_creation_and_keeps_arm_slots_exclusive():
    src = (SRC_DIR / "Astartes_CharGen_Dressed.uc").read_text(encoding="utf-8")
    assert "extends XGCharacterGenerator" in src
    assert "function TSoldier CreateTSoldier(" in src and "super.CreateTSoldier(" in src
    assert "A.nmLeftArm = ''; A.nmRightArm = '';" in src, "a whole-arms part must clear the per-arm slots"
    uv = (SRC_DIR / "Astartes_UnitVariants.uc").read_text(encoding="utf-8")
    assert "class<XGCharacterGenerator>(DynamicLoadObject(Def.CharacterGenerator, class'Class'))" in uv
    assert "T.bAppearanceDefinesPawn = Def.bAppearanceDefinesPawn || Base.bAppearanceDefinesPawn;" in uv


def test_destructor_and_loadout(config):
    weapons = section(config, "XComAstartes.ini", "Astartes.X2Item_AstartesWeapons")
    w = next(x for x in weapons.values("Weapons") if struct_field(x, "NewName") == "Astartes_Destructor")
    assert struct_field(w, "BaseTemplate") == "ForcePush_MG" and struct_field(w, "bEnemyOnly") == "true"
    extras = [x for x in weapons.values("ExtraAbilities") if struct_field(x, "Weapon") == "Astartes_Destructor"]
    assert any(struct_field(x, "Ability") == "StandardShot" for x in extras), "the AI fires StandardShot, not the mod's own shot"
    loadouts = section(config, "XComGameData.ini", "XComGame.X2ItemTemplateManager").values("Loadouts")
    lo = next(x for x in loadouts if struct_field(x, "LoadoutName") == "Astartes_EldarWarlock_Loadout")
    assert lo.index("Astartes_Destructor") < lo.index("AssaultRifle_MG")
    assert "PsiAmp_MG" in lo, "the psi amp carries the casting animations for a soldier body"


def test_eldar_hold_no_territory_but_their_lists_exist(config):
    """Eldar are incursions (the Lost mechanic reworked), never a continent's faction (decision 2026-10-18)."""
    fc = section(config, "XComAstartes.ini", "Astartes.Astartes_FactionConfig")
    assert not any(struct_field(x, "FactionName") == "Eldar" for x in fc.values("Factions"))
    mgr = section(config, "XComEncounterLists.ini", "XComGame.XComTacticalMissionManager")
    lists = {struct_field(v, "ListID"): v for v in mgr.values("SpawnDistributionLists")}
    for lid in ("Astartes_EldarLeaders", "Astartes_EldarCommanders"):
        assert "Astartes_EldarWarlock" in lists[lid]
        m = re.search(r'Template="Astartes_EldarWarlock",\s*MinForceLevel=(\d+)', lists[lid])
        assert m and int(m.group(1)) >= 4, "no Warlocks in the first missions"


def test_warlock_ai_stats_names_project(config, loc_sections):
    tree = section(config, "XComAI.ini", "XComGame.X2AIBTBehaviorTree")
    nodes = {unquote(struct_field(b, "BehaviorName")): b for b in tree.values("Behaviors")}
    assert "Astartes_Warlock_RedAlert" in nodes["Astartes_EldarWarlock::CharacterRoot"]
    sel = nodes["Astartes_Warlock_RedSelector"]
    assert "TryMindSpinOption" in sel and "TryStasis" in sel and "DarkEldarLeaderRedAbilitySelector" in sel, "powers first, then the leader's fight"
    stats = parse_ini(REPO / "Astartes/Config/XComGameData_CharacterStats.ini")
    assert any(s.name == "Astartes_EldarWarlock X2CharacterTemplate" for s in stats)
    names = {(x.template_name, x.template_class) for x in loc_sections}
    assert ("Astartes_EldarWarlock", "X2CharacterTemplate") in names and ("Astartes_Destructor", "X2WeaponTemplate") in names
    assert "Astartes_CharGen_Dressed.uc" in (REPO / "Astartes/Astartes.x2proj").read_text(encoding="utf-8")
