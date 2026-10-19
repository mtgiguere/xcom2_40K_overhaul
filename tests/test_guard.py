"""The Imperial Guard as allies (docs/design.md 9.1g)."""
from __future__ import annotations

from conftest import SRC_DIR
from x2config import struct_field

TIERS = {"CivilianMilitia": "Astartes_Guardsman", "CivilianMilitiaM2": "Astartes_GuardsmanVeteran", "CivilianMilitiaM3": "Astartes_Kasrkin"}


def section(config, file, name):
    return next(s for s in config[file] if s.name == name)


def test_militia_tiers_become_guardsmen(config):
    fc = section(config, "XComAstartes.ini", "Astartes.Astartes_FactionConfig")
    swaps = {struct_field(v, "From"): struct_field(v, "To") for v in fc.values("AllyReplacements")}
    assert swaps == TIERS
    variants = {struct_field(x, "NewName"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_UnitVariants").values("Variants")}
    looks = {struct_field(x, "Template"): x for x in section(config, "XComAstartes.ini", "Astartes.Astartes_CharGen_Dressed").values("Looks")}
    for base, unit in TIERS.items():
        assert struct_field(variants[unit], "BaseTemplate") == base
        assert struct_field(looks[unit], "nmTorso").startswith("SM2Cadian_") and struct_field(looks[unit], "bKeepName") == "true"


def test_guard_carry_lasguns_xcom_does_not(config):
    weapons = section(config, "XComAstartes.ini", "Astartes.X2Item_AstartesWeapons")
    defs = {struct_field(v, "NewName"): v for v in weapons.values("Weapons")}
    for w in ("Astartes_Lasgun", "Astartes_LasgunMG", "Astartes_Hotshot"):
        assert struct_field(defs[w], "bEnemyOnly") == "true"
    hidden = {v.strip('"') for v in weapons.values("HideDonorItems")}
    assert {"Lasgun", "HotshotLasgun"} <= hidden


def test_only_allied_pods_are_swapped():
    src = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    body = src[src.index("static function bool RewriteAllies"):]
    body = body[: body.index("\n}\n")]
    assert "Encounter.Team != eTeam_Resistance" in body and "FindCharacterTemplate" in body
    assert src.count("RewriteAllies(Encounter,") == 2
