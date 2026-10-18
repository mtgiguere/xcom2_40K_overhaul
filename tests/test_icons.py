"""Every ability icon path we use must be one the game actually ships.

tests/data/vanilla_icons.txt is every img:///UILibrary_* path referenced by the vanilla and DLC source
(tools: grep over the SDK SrcOrig). A path outside that set renders as a blank square on the promotion screen.
"""
from __future__ import annotations

import re

from conftest import REPO, SRC_DIR

VANILLA_ICONS = set((REPO / "tests" / "data" / "vanilla_icons.txt").read_text(encoding="utf-8").split())
ICON_RE = re.compile(r"img:///UILibrary_[A-Za-z0-9_]*\.[A-Za-z0-9_]*")


def test_every_icon_exists_in_the_game():
    bad = []
    for f in SRC_DIR.glob("*.uc"):
        if f.name.startswith("XMB"):
            continue
        for icon in ICON_RE.findall(f.read_text(encoding="utf-8", errors="replace")):
            if icon not in VANILLA_ICONS:
                bad.append(f"{f.name}: {icon}")
    assert not bad, "icons not shipped by the game (blank on the promotion screen):\n" + "\n".join(sorted(set(bad)))
