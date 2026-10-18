from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parent.parent
MOD_NAME = "Astartes"
MOD_DIR = REPO / MOD_NAME
CONFIG_DIR = MOD_DIR / "Config"
LOC_DIR = MOD_DIR / "Localization"
SRC_DIR = MOD_DIR / "Src" / MOD_NAME / "Classes"

sys.path.insert(0, str(Path(__file__).resolve().parent))

from x2config import Section, parse_ini  # noqa: E402


@pytest.fixture(scope="session")
def config() -> dict[str, list[Section]]:
    """All mod config files, keyed by file name."""
    return {p.name: parse_ini(p) for p in sorted(CONFIG_DIR.glob("*.ini"))}


@pytest.fixture(scope="session")
def all_sections(config) -> list[Section]:
    return [s for sections in config.values() for s in sections]


@pytest.fixture(scope="session")
def localization() -> dict[str, list[Section]]:
    return {p.name: parse_ini(p) for p in sorted(LOC_DIR.glob("*.int"))}


@pytest.fixture(scope="session")
def loc_sections(localization) -> list[Section]:
    return [s for sections in localization.values() for s in sections]


@pytest.fixture(scope="session")
def class_sections_raw(config):
    """X2SoldierClassTemplate sections of XComClassData.ini by class name."""
    return {s.template_name: s for s in config["XComClassData.ini"] if s.template_class == "X2SoldierClassTemplate"}
