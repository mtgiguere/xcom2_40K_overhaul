"""The Inquisition takes notice (docs/design.md 9.1e), first slice."""
from __future__ import annotations

from conftest import REPO, SRC_DIR
from x2config import unquote


def test_taint_tuning(config):
    sec = next(s for s in config["XComAstartes.ini"] if s.name == "Astartes.Astartes_Inquisition")
    assert sec.first("bEnableInquisition") == "true"
    threshold, possession, exposure = (int(sec.first(k)) for k in ("TAINT_THRESHOLD", "TAINT_POSSESSION", "TAINT_PER_EXPOSURE"))
    assert possession < threshold, "one lost Librarian alone must not bring the Inquisition"
    assert possession + 4 * 2 * exposure >= threshold, "a possession plus two rifts with a full squad should"
    assert unquote(sec.first("InquisitorCharacter")) == "Astartes_Inquisitor"


def test_rifts_expose_the_squad_and_the_tally_reads_it():
    rift = (SRC_DIR / "Astartes_RiftListener.uc").read_text(encoding="utf-8")
    assert "AddWarpExposure(NewGameState);" in rift and "eCleanup_Never" in rift
    inq = (SRC_DIR / "Astartes_Inquisition.uc").read_text(encoding="utf-8")
    assert "LostToTheWarpValueName" in inq and "XComHQ.DeadCrew" in inq, "possessed Librarians are dead crew by the time we tally"
    assert "PossessionCountedName" in inq and "ExposureCountedName" in inq, "nothing is counted twice"


def test_judgement_choices():
    inq = (SRC_DIR / "Astartes_Inquisition.uc").read_text(encoding="utf-8")
    sub = inq[inq.index("static function Submit"):inq.index("static function Refuse")]
    assert "RemoveFromCrew(Censured)" in sub and "Chapter.Taint = 0;" in sub and "bInquisitorJoined = true" in sub
    ref = inq[inq.index("static function Refuse"):]
    assert "bInquisitionHostile = true" in ref and "Chapter.JudgementAt = Chapter.Taint + default.TAINT_THRESHOLD;" in ref
    assert "'Astartes_Librarian' ? 1000 : 0" in inq, "a Librarian is censured before any other brother"
    assert "Astartes_Inquisition.uc" in (REPO / "Astartes/Astartes.x2proj").read_text(encoding="utf-8")
