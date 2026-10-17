"""Sanity checks on the mod skeleton: identifiers agree and the Highlander dependency is declared."""
from conftest import CONFIG_DIR, LOC_DIR, MOD_NAME, SRC_DIR
from x2config import unquote


def test_dlc_identifier_matches_package_name(config):
    section_name = f"{MOD_NAME}.X2DownloadableContentInfo_{MOD_NAME}"
    sections = [s for s in config["XComGame.ini"] if s.name == section_name]
    assert sections, f"missing [{section_name}] in XComGame.ini"
    assert unquote(sections[0].first("DLCIdentifier")) == MOD_NAME


def test_script_package_is_registered(config):
    engine = {s.name: s for s in config["XComEngine.ini"]}
    editor = {s.name: s for s in config["XComEditor.ini"]}
    assert MOD_NAME in engine["Engine.ScriptPackages"].values("NonNativePackages")
    assert MOD_NAME in editor["ModPackages"].values("ModPackages")


def test_highlander_dependency_declared(config):
    dep = [s for s in config["XComGame.ini"] if s.name == f"{MOD_NAME} CHModDependency"]
    assert dep, "missing [Astartes CHModDependency] section"
    required = [unquote(v) for v in dep[0].values("RequiredMods")]
    assert "X2WOTCCommunityHighlander" in required


def test_entry_class_exists():
    assert (SRC_DIR / f"X2DownloadableContentInfo_{MOD_NAME}.uc").is_file()


def test_localization_files_are_utf8_in_repo():
    for path in LOC_DIR.glob("*.int"):
        raw = path.read_bytes()
        assert raw[:2] not in (b"\xff\xfe", b"\xfe\xff"), f"{path.name} is UTF-16; keep repo copies UTF-8"
        raw.decode("utf-8")  # raises if not valid UTF-8


def test_config_dir_has_no_stray_files():
    stray = [p.name for p in CONFIG_DIR.iterdir() if p.suffix.lower() != ".ini"]
    assert not stray, f"non-ini files in Config: {stray}"
