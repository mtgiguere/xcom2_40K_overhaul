"""Continent faction ownership config (design.md 7.1b)."""
import re

import pytest

from conftest import SRC_DIR
from x2config import struct_field, unquote

REQUIRED_FACTIONS = {"Orks", "Chaos", "Tyranids"}
CONTINENTS = {"Continent_NorthAmerica", "Continent_SouthAmerica", "Continent_Europe", "Continent_Africa", "Continent_Asia", "Continent_Oceania"}


@pytest.fixture(scope="session")
def faction_section(config):
    sections = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_FactionConfig"]
    assert sections, "missing [Astartes.Astartes_FactionConfig] in XComAstartes.ini"
    return sections[0]


@pytest.fixture(scope="session")
def factions(faction_section):
    return {struct_field(v, "FactionName"): v for v in faction_section.values("Factions")}


def test_feature_is_enabled(faction_section):
    assert unquote(faction_section.first("bEnableContinentFactions") or "").lower() == "true"


def test_all_three_territorial_factions_defined(factions):
    assert REQUIRED_FACTIONS <= set(factions), f"missing factions: {REQUIRED_FACTIONS - set(factions)}"


@pytest.mark.parametrize("faction", sorted(REQUIRED_FACTIONS))
def test_faction_has_leader_follower_lists_and_dlc(factions, faction):
    v = factions[faction]
    for field in ("LeaderList", "FollowerList", "RequiredDLC"):
        assert struct_field(v, field), f"{faction}: {field} missing"
    assert struct_field(v, "LeaderList") != struct_field(v, "FollowerList")


def test_overrides_reference_real_continents_and_factions(faction_section, factions):
    for v in faction_section.values("ContinentFactionOverrides"):
        assert struct_field(v, "Continent") in CONTINENTS, v
        assert struct_field(v, "FactionName") in factions, v


def test_pod_rewrite_skips_special_pods():
    """Chosen / VIP / objective pods carry a StrategyUnitTag and must never be replaced; only the alien team is rewritten."""
    src = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    body = src[src.index("static function RewritePodForContinent"):]
    body = body[: body.index("\n}\n")]
    assert "StrategyUnitTag != ''" in body
    assert "Encounter.Team != eTeam_Alien" in body


def test_faction_spawn_lists_exist_in_the_faction_mods(factions):
    """The list IDs we point at must exist in the installed faction mods' XComEncounterLists.ini."""
    import os
    from pathlib import Path
    workshop = Path(os.environ.get("XCOM2_WORKSHOP", r"C:/Program Files (x86)/Steam/steamapps/workshop/content/268500"))
    if not workshop.is_dir():
        pytest.skip("workshop folder not present")
    available = set()
    from conftest import CONFIG_DIR
    for ini in list(workshop.glob("*/Config/XComEncounterLists.ini")) + [CONFIG_DIR / "XComEncounterLists.ini"]:
        available |= set(re.findall(r'ListID="(\w+)"', ini.read_text(encoding="utf-8", errors="replace")))
    missing = {struct_field(v, f) for v in factions.values() for f in ("LeaderList", "FollowerList")} - available
    assert not missing, f"spawn lists not found in any installed mod: {sorted(missing)}"


def test_our_lists_cover_every_force_level(config):
    """Our own faction lists must have at least one leader and one follower eligible at every force level 1..20."""
    mgr = [s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager"]
    assert mgr, "missing spawn lists"
    lists = {struct_field(v, "ListID"): v for v in mgr[0].values("SpawnDistributionLists")}
    ours = [k for k in lists if k.startswith("Astartes_")]
    assert len(ours) >= 4, f"expected our own faction lists, found {ours}"
    for list_id in ours:
        entries = re.findall(r'MinForceLevel=(\d+),\s*MaxForceLevel=(\d+)', lists[list_id])
        for fl in range(1, 21):
            assert any(int(lo) <= fl <= int(hi) for lo, hi in entries), f"{list_id}: nothing eligible at force level {fl}"


def test_early_game_lists_use_our_units_not_advent(config):
    """Chaos FL 1-4 must be our cultists (not ADVENT models); Tyranids FL 1-4 must be our weak hybrid variant."""
    mgr = [s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager"][0]
    lists = {struct_field(v, "ListID"): v for v in mgr[0].values("SpawnDistributionLists")} if False else {struct_field(v, "ListID"): v for v in mgr.values("SpawnDistributionLists")}
    for list_id in ("Astartes_ChaosLeaders", "Astartes_ChaosFollowers"):
        for tmpl, lo in re.findall(r'Template="(\w+)",\s*MinForceLevel=(\d+)', lists[list_id]):
            if int(lo) <= 2:
                assert not tmpl.startswith("Adv"), f"{list_id}: {tmpl} at FL{lo} is an ADVENT model; use Astartes_Cultist"
    for list_id in ("Astartes_TyranidLeaders", "Astartes_TyranidFollowers"):
        entries = re.findall(r'Template="(\w+)",\s*MinForceLevel=(\d+)', lists[list_id])
        assert ("Astartes_CultHybrid", "1") in entries, f"{list_id}: FL1 must use Astartes_CultHybrid"
        assert all(not (t == "ChrysHybrid" and int(lo) < 5) for t, lo in entries), f"{list_id}: full-strength ChrysHybrid before FL5"


def test_variant_and_cultist_have_stats_and_localization(config, loc_sections):
    stats = {s.template_name for s in config["XComGameData_CharacterStats.ini"] if s.template_class == "X2CharacterTemplate"}
    loc = {s.template_name for s in loc_sections if s.template_class == "X2CharacterTemplate"}
    section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_UnitVariants"]
    assert section, "missing [Astartes.Astartes_UnitVariants]"
    names = {"Astartes_Cultist"} | {struct_field(v, "NewName") for v in section[0].values("Variants")}
    for n in names:
        assert n in stats, f"{n} has no [X2CharacterTemplate] stats block"
        assert n in loc, f"{n} has no strCharacterName localization"


def test_lost_pods_become_eldar_incursions(faction_section):
    """The Lost are Eldar (design.md 9.2): Lost encounters are rebuilt from the incursion faction on the alien team."""
    assert unquote(faction_section.first("bEnableIncursions") or "").lower() == "true"
    inc = faction_section.first("Incursion")
    assert struct_field(inc, "FactionName") == "Eldar" and struct_field(inc, "FollowerList") == "Astartes_EldarFollowers"
    assert "TheLost" in {unquote(v) for v in faction_section.values("IncursionEncounterPrefixes")}
    assert 3 <= int(faction_section.first("IncursionMaxPodSize")) <= 8, "a Lost swarm is huge; an Eldar pod must be a pod"
    src = (SRC_DIR / "X2DownloadableContentInfo_Astartes.uc").read_text(encoding="utf-8")
    assert src.count("if (RewriteIncursion(Encounter, EncounterName, ForceLevel,") == 2, "both the pod and the reinforcement hooks"
    body = src[src.index("static function bool RewriteIncursion"):]
    assert "Encounter.Team = eTeam_Alien;" in body and "IncursionMaxPodSize" in body


def test_special_encounters_are_protected_and_commanders_defined(config, faction_section, factions):
    never = {unquote(v) for v in faction_section.values("NeverRewriteEncounters")}
    assert "SPCx1_Faceless" in never, "the hidden Faceless encounter must never be rewritten"
    assert {"Astartes_DaemonRift_Lesser", "Astartes_DaemonRift_Greater"} <= never, "a Sorcerer's rift brings daemons, not the continent's Orks (playtest 2026-10-18)"
    fc = (SRC_DIR / "Astartes_FactionConfig.uc").read_text(encoding="utf-8")
    assert '~= "Astartes_"' in fc, "every Astartes_ encounter is exempt from the rewrite in code too"
    assert {"Astartes_DaemonRift_Lesser", "Astartes_DaemonRift_Greater"} <= never, "a Sorcerer's rift brings daemons, not the continent's Orks (playtest 2026-10-18)"
    fc = (SRC_DIR / "Astartes_FactionConfig.uc").read_text(encoding="utf-8")
    assert '~= "Astartes_"' in fc, "every Astartes_ encounter is exempt from the rewrite in code too"
    prefixes = {unquote(v) for v in faction_section.values("CommanderEncounterPrefixes")}
    assert "SPCx" in prefixes
    mgr = [s for s in config["XComEncounterLists.ini"] if s.name == "XComGame.XComTacticalMissionManager"][0]
    lists = {struct_field(v, "ListID") for v in mgr.values("SpawnDistributionLists")}
    for faction, v in factions.items():
        cl = struct_field(v, "CommanderList")
        assert cl, f"{faction} has no CommanderList"
        assert cl in lists, f"{faction}: commander list {cl} not defined"


def test_cultist_has_pawn_parts_for_both_genders(config):
    """bAppearanceDefinesPawn templates need Pawn body parts tagged with their template name or they spawn invisible."""
    mgr = [s for s in config.get("XComContent.ini", []) if s.name == "XComGame.X2BodyPartTemplateManager"]
    assert mgr, "missing [XComGame.X2BodyPartTemplateManager] in XComContent.ini"
    pawns = [v for v in mgr[0].values("BodyPartTemplateConfig") if struct_field(v, "PartType") == "Pawn" and struct_field(v, "CharacterTemplate") == "Astartes_Cultist"]
    genders = {struct_field(v, "Gender") for v in pawns}
    assert genders == {"eGender_Male", "eGender_Female"}, f"cultist pawn parts: {genders}"


def test_foreign_raid_sitreps_and_run_order(config, faction_section):
    raids = {unquote(v) for v in faction_section.values("ForeignRaidSitReps")}
    assert {"OrkTeamOneRaiders", "OrkTeamTwoRaiders", "BlackLegion", "DarkEldarRaiders"} <= raids
    order = [s for s in config["XComGame.ini"] if s.name == "Astartes CHDLCRunOrder"]
    assert order, "missing [Astartes CHDLCRunOrder]"
    after = {unquote(v) for v in order[0].values("RunAfter")}
    assert {"OrkRaiders", "BlackLegion"} <= after, "we must run after the faction mods to strip their SitReps"
    assert "PrimarySecondaries" in {unquote(v) for v in order[0].values("RunBefore")}


def test_loadouts_use_our_wargear(config):
    mgr = [s for s in config["XComGameData.ini"] if s.name == "XComGame.X2ItemTemplateManager"][0]
    weapons_section = [s for s in config["XComAstartes.ini"] if s.name == "Astartes.X2Item_AstartesWeapons"][0]
    defined = {struct_field(v, "NewName") for v in weapons_section.values("Weapons")}
    for v in mgr.values("Loadouts"):
        if not struct_field(v, "LoadoutName").startswith("SquaddieAstartes_"):
            continue
        for item in re.findall(r'Item="(\w+)"', v):
            base = item[:-len("_Primary")] if item.endswith("_Primary") else item
            assert base in defined, f"loadout item {item} is not one of our weapons"
