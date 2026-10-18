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


def test_chapter_country_and_liveries(config):
    import os, re
    from pathlib import Path
    section = [s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes"][0]
    chapter = unquote(section.first("ChapterCountry") or "")
    assert chapter.startswith("Country_"), "ChapterCountry must name a country template"
    assert unquote(section.first("NameFallbackCountry") or "").startswith("Country_")
    liveries = section.values("ChapterLiveries")
    from x2config import struct_field
    countries = {struct_field(v, "Country") for v in liveries}
    assert chapter in countries, "the default Chapter needs a livery entry"
    workshop = Path(os.environ.get("XCOM2_WORKSHOP", r"C:/Program Files (x86)/Steam/steamapps/workshop/content/268500"))
    if workshop.is_dir():
        defined = set()
        for ini in workshop.glob("*/Config/*.ini"):
            try:
                defined |= set(re.findall(r"\[(Country_\w+) X2CountryTemplate\]", ini.read_text(encoding="utf-8", errors="replace")))
            except OSError:
                pass
        missing = countries - defined
        assert not missing, f"livery countries not defined by any installed flag mod: {sorted(missing)}"


def test_power_armour_is_configured_and_named(config, loc_sections):
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Ability_Astartes"][0]
    assert int(section.first("POWER_ARMOUR_HEALTH_BONUS")) >= 1
    assert int(section.first("POWER_ARMOUR_MITIGATION")) >= 1
    armour_loc = {s.template_name: s for s in loc_sections if s.template_class == "X2ArmorTemplate"}
    assert "KevlarArmor" in armour_loc, "KevlarArmor must be renamed to power armour"
    assert "Power Armour" in unquote(armour_loc["KevlarArmor"].first("FriendlyName"))


def test_marine_look_uses_only_tintable_parts(config):
    section = [s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes"][0]
    keywords = [unquote(v) for v in section.values("MarinePartNameKeywords")]
    assert "Tint" in keywords, "pre-painted chapter parts must be filtered out of the random Marine look"


def test_marine_look_template_configured(config):
    """Generated Marines copy a pool soldier's armour parts (random part picking produced power fists on everyone)."""
    section = [s for s in config["XComGame.ini"] if s.name == "Astartes.X2DownloadableContentInfo_Astartes"][0]
    names = [unquote(v) for v in section.values("MarineLookTemplates")]
    assert names and all(" " in n for n in names), "list at least one pool soldier by full name"
