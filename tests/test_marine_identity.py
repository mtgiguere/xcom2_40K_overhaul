"""Step 'soldiers are Marines': base stats, gender policy, armour look, promotion deck."""
from x2config import unquote


def _soldier_stats(config):
    sections = [s for s in config.get("XComGameData_CharacterStats.ini", []) if s.name == "Soldier X2CharacterTemplate"]
    assert sections, "missing [Soldier X2CharacterTemplate] override in XComGameData_CharacterStats.ini"
    return {k: v for _, k, v in sections[0].entries}


def test_marines_are_tougher_than_xcom_soldiers(config):
    stats = _soldier_stats(config)
    assert int(stats["CharacterBaseStats[eStat_HP]"]) >= 7, "a Marine in power armour should start with more than vanilla 5 HP"
    assert int(stats["CharacterBaseStats[eStat_Will]"]) >= 50, "Marines have high Will (Know No Fear is separate)"
    assert int(stats["CharacterBaseStats[eStat_Strength]"]) > 40


def test_gender_policy_is_configurable(config):
    section = [s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes"]
    assert section, "missing [Astartes.X2DownloadableContentInfo_Astartes] in XComGame.ini"
    assert unquote(section[0].first("bAllowFemaleMarines") or "").lower() in ("true", "false")
    packs = [unquote(v) for v in section[0].values("MarineArmorPartPacks")]
    assert "SM2Tacticus" in packs, "the Space Marine 2 Tacticus pack must be the default Marine look"
