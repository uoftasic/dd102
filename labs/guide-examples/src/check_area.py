#!/usr/bin/env python3
"""Read Yosys `stat -json -liberty` output and say whether you succeeded.

    python3 src/check_area.py results/drawing.json
    python3 src/check_area.py --table results/*.json

Nobody is grading this lab. This script is the grader. The numbers below
were measured on hpretl/iic-osic-tools:2026.08 (Yosys 0.68, sky130A). Yours
should match to the digit; the tolerance exists only so a future Yosys
patch release nudging one cell does not tell you that you failed.

Exit status 0 = every file passed, 1 = something did not.
"""

import json
import os
import sys

#  name          cells   area (um^2)   what it is
EXPECTED = {
    "drawing":    (2,  33.7824),   # five assigns, one per wire on your paper
    "flat":       (2,  33.7824),   # one expression per output
    "table":      (2,  33.7824),   # always_comb + case, your eight rows
    "half":       (2,  15.0144),   # one half adder, alone
    "boxes":      (7,  36.2848),   # 5 gates + the 2 boxes, counted as cells
    "boxes_flat": (2,  33.7824),   # the same two boxes, walls down
}

AREA_TOL = 0.05    # +/- 5 %


def load(path):
    """Pull the numbers that matter out of a stat -json file."""
    with open(path) as f:
        d = json.load(f)["design"]   # "design" sums the whole design, so you
                                     # never have to guess the module name
    by_type = d["num_cells_by_type"]
    # $scopeinfo is bookkeeping Yosys leaves behind after `flatten`. It is not
    # hardware, it has no area, and it should not be counted as a cell.
    real = {t: n for t, n in by_type.items() if t != "$scopeinfo"}
    unmapped = {t: n for t, n in real.items() if t.startswith("$")}
    return {
        "cells": sum(real.values()),
        "area": d["area"],
        "types": real,
        "unmapped": unmapped,
    }


def verdict(name, s):
    """Return a list of complaints. Empty list means pass."""
    bad = []
    if s["unmapped"]:
        names = ", ".join(sorted(s["unmapped"]))
        bad.append(f"cells with no price: {names}. A type whose name starts "
                   f"with '$' is not a real sky130 gate, so it cost 0 um^2 "
                   f"and your total is too small.")
    if name not in EXPECTED:
        bad.append(f"no reference numbers for '{name}'. Known: "
                   + ", ".join(sorted(EXPECTED)))
        return bad
    cells, area = EXPECTED[name]
    if s["cells"] != cells:
        bad.append(f"{s['cells']} cells, expected {cells}")
    if abs(s["area"] - area) > AREA_TOL * area:
        bad.append(f"{s['area']:.4f} um^2, expected {area} um^2")
    return bad


def table(paths):
    print(f"{'file':<18}{'cells':>7}{'area (um^2)':>14}   {'verdict':<8} cells used")
    print("-" * 78)
    failed = False
    for p in paths:
        name = os.path.basename(p)[:-5]
        s = load(p)
        bad = verdict(name, s)
        if bad:
            failed = True
        types = " + ".join(f"{n}x {t.replace('sky130_fd_sc_hd__', '')}"
                           for t, n in sorted(s["types"].items()))
        print(f"{name + '.json':<18}{s['cells']:>7}{s['area']:>14.4f}   "
              f"{'PASS' if not bad else 'FAIL':<8} {types}")
        for b in bad:
            print(f"{'':<18}{'':>7}{'':>14}   -> {b}")
    print()
    if failed:
        print("FAIL - at least one number does not match the reference run.")
        print("       Ask in the team Discord: https://discord.gg/hrJnP5UsGz")
    else:
        print("PASS - every number matches the reference run, to four decimals.")
    return 1 if failed else 0


def main():
    args = sys.argv[1:]
    if args and args[0] == "--table":
        args = args[1:]
    if not args:
        print("usage: check_area.py [--table] results/*.json", file=sys.stderr)
        return 2
    return table(args)


if __name__ == "__main__":
    sys.exit(main())
