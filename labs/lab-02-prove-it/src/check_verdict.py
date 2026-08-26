#!/usr/bin/env python3
"""check_verdict.py -- the grader for Lab 02.

Your testbench prints its own verdict. This script reads it and decides whether
the verdict was the RIGHT verdict -- which is a different question, and the one
this lab is about.

    python3 src/check_verdict.py results/good.txt --expect pass --label "..."
    python3 src/check_verdict.py results/mut1.txt --expect fail --label "..."

Standard library only. Python 3.12.3, as shipped in
hpretl/iic-osic-tools:2026.04.
"""

import os
import re
import sys

SCOREBOARD = "results/scoreboard.txt"


def read(path):
    tested = errors = None
    verdict = None
    try:
        with open(path) as fh:
            text = fh.read()
    except FileNotFoundError:
        return None, None, None
    m = re.search(r"^TESTED\s+(\d+)\s*$", text, re.M)
    if m:
        tested = int(m.group(1))
    m = re.search(r"^ERRORS\s+(\d+)\s*$", text, re.M)
    if m:
        errors = int(m.group(1))
    m = re.search(r"^VERDICT\s+(PASS|FAIL)\s*$", text, re.M)
    if m:
        verdict = m.group(1)
    return tested, errors, verdict


def note(line):
    os.makedirs("results", exist_ok=True)
    with open(SCOREBOARD, "a") as fh:
        fh.write(line + "\n")



def summary():
    """Read results/scoreboard.txt and print one verdict for the whole lab."""
    try:
        rows = [l.rstrip("\n").split("|") for l in open(SCOREBOARD) if l.strip()]
    except FileNotFoundError:
        print("No scoreboard. Run `make` first.")
        return 1

    good = [r for r in rows if r[0] in ("GOOD", "THIN", "BAD", "BROKEN") ]
    mutants = [r for r in rows if r[0] in ("CAUGHT", "SLIPPED")]
    caught = [r for r in mutants if r[0] == "CAUGHT"]

    print("=" * 62)
    print(" VERDICT")
    print("=" * 62)
    for r in good:
        rows_checked = r[2]
        print(f" {'against the working adder':<38}: {r[0]} ({rows_checked} of 8 rows checked)")
    for r in mutants:
        print(f" {r[1]:<38}: {r[0]}")
    print("-" * 62)
    print(f" mutants caught: {len(caught)} of {len(mutants)}")

    ok = all(r[0] == "GOOD" for r in good) and len(caught) == len(mutants) and mutants
    if ok:
        print()
        print(" All 8 rows checked, all 3 mutants caught. Lab 02 is done.")
        print(" Next: labs/lab-03-the-lazy-testbench/")
        print("=" * 62)
        return 0
    print()
    if any(r[0] == "THIN" for r in good):
        print(" Your testbench passes a working adder and misses broken ones.")
        print(" A testbench that never fails has proven nothing. Add the other")
        print(" seven check(...) lines to tb/tb_full_adder.sv and run `make` again.")
    else:
        print(" Read the lines above. The first one that is not GOOD or CAUGHT")
        print(" is the real problem; the rest is fallout.")
    print("=" * 62)
    return 1


def main():
    argv = sys.argv[1:]
    if argv and argv[0] == "--summary":
        return summary()
    if not argv:
        print("usage: check_verdict.py <run.txt> --expect pass|fail [--label NAME]")
        return 2
    path = argv[0]
    expect = argv[argv.index("--expect") + 1].upper() if "--expect" in argv else "PASS"
    label = argv[argv.index("--label") + 1] if "--label" in argv else path

    tested, errors, verdict = read(path)

    if verdict is None:
        print(f"BROKEN  -- {label}")
        print("          Your testbench printed no `VERDICT PASS` or `VERDICT FAIL` line.")
        print("          The three $display lines at the bottom of tb/tb_full_adder.sv")
        print("          are what this grader reads. Do not rename them.")
        note(f"BROKEN|{label}|{expect}")
        return 1

    if expect == "PASS":
        # Run against the real, working adder.
        if verdict == "PASS" and tested == 8 and errors == 0:
            print(f"GOOD    -- {label}: {tested} rows checked, {errors} mismatches, said PASS.")
            note(f"GOOD|{label}|{tested}")
            return 0
        if verdict == "PASS" and errors == 0:
            print(f"THIN    -- {label}: said PASS after checking only {tested} of 8 rows.")
            print("          Not wrong. Just not finished. A full adder has exactly eight")
            print("          possible inputs, so 'all of them' is a reachable goal here.")
            note(f"THIN|{label}|{tested}")
            return 1
        print(f"BAD     -- {label}: {errors} mismatches against a KNOWN-GOOD adder.")
        print("          Either src/full_adder.sv is not the shipped one, or one of your")
        print("          expected values does not match the DD101 truth table.")
        note(f"BAD|{label}|{tested}")
        return 1

    # expect FAIL: run against a deliberately broken adder.
    if verdict == "FAIL":
        print(f"CAUGHT  -- {label}: {errors} of {tested} rows disagreed. Your testbench noticed.")
        note(f"CAUGHT|{label}|{errors}/{tested}")
        return 0
    print(f"SLIPPED -- {label}: this adder is BROKEN and your testbench said PASS.")
    print(f"          It checked {tested} row(s). None of them was a row where this")
    print("          particular bug shows up, so it saw nothing and reported nothing.")
    note(f"SLIPPED|{label}|{tested}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
