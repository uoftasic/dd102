#!/usr/bin/env python3
"""Read a log this lab produced and say whether it says what it should.

Two kinds of check live here.

  * A **verdict** check reads the PASS/FAIL line a testbench prints and compares
    the mismatch count against the reference run. `vvp` exits 0 whether your
    design is right or wrong, so the exit code is not the verdict.
  * A **text** check looks for an exact sentence in a tool log -- the SAT
    solver's proof result, the undriven-wire warnings, the LUT count.

Both print one line starting with PASS or FAIL, and exit non-zero on FAIL.

    python3 src/check_lab04.py results/generate.log --expect generate
    python3 src/check_lab04.py results/proof.log    --expect proof
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# --- verdict checks: name -> (word, mismatches, total, description) ----------
VERDICTS = {
    "generate": ("PASS",   0,    512, "src/ripple4.sv, all 512 inputs"),
    "broken":   ("FAIL", 512,    512, "broken/ripple4.sv, all 512 inputs"),
    "wide4":    ("PASS",   0,    512, "ripple #(.N(4)), all 512 inputs"),
    "wide8":    ("PASS",   0, 131072, "ripple #(.N(8)), all 131072 inputs"),
    "wide12":   ("PASS",   0, 33554432, "ripple #(.N(12)), all 33554432 inputs"),
}

# --- text checks: name -> (list of exact substrings, description) ------------
TEXTS = {
    "proof": (
        ["SAT proof finished - no model found: SUCCESS!"],
        "Yosys proved generate == hand-typed, for every input",
    ),
    "proof_broken": (
        ["SAT proof finished - model found: FAIL!",
         "ERROR: Called with -verify and proof did fail!"],
        "the same proof against broken/ripple4.sv -- fails on purpose",
    ),
    "undriven": (
        ["Warning: Wire ripple4.\\sum [3] is used but has no driver.",
         "Warning: Wire ripple4.\\c [4] is used but has no driver.",
         "Found and reported 2 problems.",
         "3   full_adder"],
        "`check` names the two undriven wires and counts 3 full adders",
    ),
    "clean": (
        ["Found and reported 0 problems.",
         "4   full_adder"],
        "`check` on src/ripple4.sv -- nothing undriven, 4 full adders",
    ),
    "luts4":  (["9   SB_LUT4"],  "ripple #(.N(4))  -> 9 SB_LUT4"),
    "luts8":  (["18   SB_LUT4"], "ripple #(.N(8))  -> 18 SB_LUT4"),
    "luts16": (["37   SB_LUT4"], "ripple #(.N(16)) -> 37 SB_LUT4"),
    "luts32": (["74   SB_LUT4"], "ripple #(.N(32)) -> 74 SB_LUT4"),
}

VERDICT_RE = re.compile(r"^(PASS|FAIL)\s+(\d+) mismatches out of (\d+)", re.M)

DRIFT = """      Yours differs from the reference run. Either a file in this package
      was edited, or you are not on hpretl/iic-osic-tools:2026.08.
      Paste this line into Discord: https://discord.gg/hrJnP5UsGz"""


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("log", type=Path)
    ap.add_argument("--expect", required=True,
                    choices=sorted(set(VERDICTS) | set(TEXTS)))
    args = ap.parse_args()
    name = args.expect

    if not args.log.exists():
        print(f"FAIL  {name:<13} {args.log} does not exist -- that step never ran.")
        return 1

    text = args.log.read_text(errors="replace")

    if name in VERDICTS:
        want_word, want_bad, want_total, what = VERDICTS[name]
        m = VERDICT_RE.search(text)
        if not m:
            print(f"FAIL  {name:<13} no PASS/FAIL line in {args.log}.")
            print("      The simulation stopped early. Read the log from the top;")
            print("      the FIRST error line is the real one.")
            return 1
        word, bad, total = m.group(1), int(m.group(2)), int(m.group(3))
        ok = (word, bad, total) == (want_word, want_bad, want_total)
        print(f"{'PASS' if ok else 'FAIL'}  {name:<13} got {word} {bad}/{total}, "
              f"reference says {want_word} {want_bad}/{want_total}   ({what})")
        if not ok:
            print(DRIFT)
        return 0 if ok else 1

    needles, what = TEXTS[name]
    missing = [n for n in needles if n not in text]
    ok = not missing
    print(f"{'PASS' if ok else 'FAIL'}  {name:<13} {what}")
    if not ok:
        for n in missing:
            print(f"      not found in {args.log}: {n!r}")
        print(DRIFT)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
