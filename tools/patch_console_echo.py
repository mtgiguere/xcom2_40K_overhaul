"""One-off refactor: make the dev console commands echo to the on-screen console as well as the log.

Rewrites `log("Astartes_<Cmd>: ...",, 'Astartes'); calls inside X2DownloadableContentInfo_Astartes.uc into
Say("Astartes_<Cmd>: ..."); and adds the Say helper. Safe to re-run (idempotent).
"""
from __future__ import annotations

import re
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "Astartes" / "Src" / "Astartes" / "Classes" / "X2DownloadableContentInfo_Astartes.uc"

HELPER = '''
/// Log a line and echo it to the in-game console, so dev commands give visible feedback.
static function Say(string Msg)
{
	local Engine Eng;

	`log(Msg,, 'Astartes');
	Eng = class'Engine'.static.GetEngine();
	if (Eng != none && Eng.GameViewport != none && Eng.GameViewport.ViewportConsole != none)
	{
		Eng.GameViewport.ViewportConsole.OutputText(Msg);
	}
}
'''

ANCHOR = "// Developer console commands. Require -allowConsole."


def main() -> None:
    text = PATH.read_text(encoding="utf-8")
    pattern = re.compile(r"`log\((\"Astartes_\w+: [^;]*?),, 'Astartes'\);")
    new_text, n = pattern.subn(r"Say(\1);", text)
    if "static function Say(string Msg)" not in new_text:
        idx = new_text.index(ANCHOR)
        line_start = new_text.rfind("\n// -----", 0, idx)
        new_text = new_text[:line_start] + "\n" + HELPER + new_text[line_start:]
    PATH.write_text(new_text, encoding="utf-8")
    print(f"rewrote {n} log calls; Say helper present: {'static function Say' in new_text}")


if __name__ == "__main__":
    main()
