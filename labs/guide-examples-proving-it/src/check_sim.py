#!/usr/bin/env python3
"""Read a simulation log, find its verdict, and say whether it is the verdict
this package expects.

Every testbench here ends with three lines: TESTED n, ERRORS n, VERDICT word.
`vvp` exits 0 either way -- it exits 0 when your design is right and it exits 0
when your design is wrong -- so the exit code is not the verdict, and this
script never looks at it.

    python3 src/check_sim.py results/eight.log --expect eight
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# name -> (verdict, tested, errors, what it is)
REFERENCE = {
    "eight":        ("PASS",   8,   0, "your full adder, all 8 inputs"),
    "eight_broken": ("FAIL",   8,   4, "the full adder with an And where the drawing has an Or"),
    "six":          ("PASS",   6,   0, "six hand-picked cases on the BROKEN ripple adder"),
    "sweep":        ("FAIL", 512, 256, "all 512 inputs on that same broken ripple adder"),
    "fixed":        ("PASS", 512,   0, "all 512 inputs on the repaired ripple adder"),
}

PAT = re.compile(r"^TESTED (\d+)$.*?^ERRORS (\d+)$.*?^VERDICT (PASS|FAIL)$",
                 re.M | re.S)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("log", type=Path)
    ap.add_argument("--expect", required=True, choices=sorted(REFERENCE))
    args = ap.parse_args()

    want_verdict, want_tested, want_errors, what = REFERENCE[args.expect]

    if not args.log.exists():
        print(f"FAIL  {args.log} does not exist -- the simulation never ran.")
        return 1

    m = PAT.search(args.log.read_text(errors="replace"))
    if not m:
        print(f"FAIL  {args.log} has no TESTED/ERRORS/VERDICT block.")
        print("      The simulation did not reach the end. Read the log from the top:")
        print("      the FIRST error line is the real one, the rest is fallout.")
        return 1

    tested, errors, verdict = int(m.group(1)), int(m.group(2)), m.group(3)
    ok = (verdict == want_verdict and tested == want_tested and errors == want_errors)

    print(f"{'PASS' if ok else 'FAIL'}  {args.expect:<13} "
          f"got {verdict} {errors}/{tested}, reference says {want_verdict} "
          f"{want_errors}/{want_tested}   ({what})")
    if not ok:
        print("      This package expects that exact verdict, so a difference means")
        print("      a file here was edited or you are not on")
        print("      hpretl/iic-osic-tools:2026.04. Bring this line to Discord.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
