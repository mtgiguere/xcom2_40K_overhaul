"""Runtime harness: assertions over the game's Launch.log.

The mod's console commands (exec functions in X2DownloadableContentInfo_Astartes) log lines of the form
    [Astartes] Astartes_<Command>: PASS ...   or   ... FAIL ...
Run the commands in game, then run this file. Tests are skipped when no log or no Astartes lines exist,
so the normal config suite stays green without the game. Force them with:  pytest -m runtime
"""
from __future__ import annotations

import os
import re
from pathlib import Path

import pytest

LOG_PATH = Path(
    os.environ.get(
        "XCOM2_LAUNCH_LOG",
        Path.home() / "Documents" / "My Games" / "XCOM2 War of the Chosen" / "XComGame" / "Logs" / "Launch.log",
    )
)

_LINE = re.compile(r"Astartes[_ ](\w+): (PASS|FAIL)(.*)")


def read_log() -> str:
    if not LOG_PATH.is_file():
        pytest.skip(f"no Launch.log at {LOG_PATH}")
    raw = LOG_PATH.read_bytes()
    text = raw.decode("utf-16", errors="replace") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", errors="replace")
    if "Astartes" not in text:
        pytest.skip("Launch.log has no Astartes lines; run the mod's console commands first")
    return text


@pytest.fixture(scope="module")
def results() -> dict[str, list[tuple[str, str]]]:
    """Command name -> list of (PASS|FAIL, detail), in log order."""
    out: dict[str, list[tuple[str, str]]] = {}
    for m in _LINE.finditer(read_log()):
        out.setdefault(m.group(1), []).append((m.group(2), m.group(3).strip()))
    return out


pytestmark = pytest.mark.runtime


def test_mod_loaded_without_redscreen():
    text = read_log()
    assert "Astartes: OnPostTemplatesCreated" in text, "mod entry point never ran; is Astartes enabled in AML?"
    redscreens = [l for l in text.splitlines() if "Redscreen" in l and "Astartes" in l]
    assert not redscreens, f"redscreens mentioning Astartes: {redscreens[:5]}"


def test_no_command_reported_fail(results):
    fails = {cmd: [d for s, d in runs if s == "FAIL"] for cmd, runs in results.items()}
    fails = {k: v for k, v in fails.items() if v}
    assert not fails, f"console commands reported FAIL: {fails}"


def test_dev_squad_created_every_class(results):
    if "DevSquad" not in results:
        pytest.skip("Astartes_DevSquad was not run")
    status, detail = results["DevSquad"][-1]
    m = re.search(r"created (\d+) of (\d+)", detail)
    assert status == "PASS" and m and m.group(1) == m.group(2), detail


def test_list_classes_found_all(results):
    if "ListClasses" not in results:
        pytest.skip("Astartes_ListClasses was not run")
    assert all(s == "PASS" for s, _ in results["ListClasses"]), results["ListClasses"]
    for _, detail in results["ListClasses"]:
        m = re.search(r"ranks=(\d+)", detail)
        assert m and int(m.group(1)) == 7, detail


def test_factions_assigned_and_lists_loaded(results):
    if "Factions" not in results:
        pytest.skip("Astartes_Factions was not run")
    runs = results["Factions"]
    assert all(s == "PASS" for s, _ in runs), runs
    assert len(runs) >= 6, "expected one line per continent"
    missing = [d for _, d in runs if "MISSING" in d]
    assert not missing, f"factions whose mods are not enabled: {missing}"
