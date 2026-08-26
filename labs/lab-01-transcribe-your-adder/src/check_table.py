#!/usr/bin/env python3
"""check_table.py -- the grader for Lab 01.

Reads the eight rows that tb/print_table.sv printed and compares them, digit by
digit, against the full-adder truth table. Prints PASS or FAIL and, on a FAIL,
does the arithmetic for the rows that disagree.

    python3 src/check_table.py results/yours.txt --label "src/full_adder.sv"

Exit status: 0 on PASS, 1 on FAIL. Runs on the Python 3.12.3 already inside
hpretl/iic-osic-tools:2026.04. No packages, no imports beyond the standard
library.
"""

import re
import sys

# The reference table. cout, sum for each (a, b, cin), in counting order.
# This is the same table you filled in by hand in DD101 Lab 04.
REFERENCE = {
    (0, 0, 0): (0, 0),
    (0, 0, 1): (0, 1),
    (0, 1, 0): (0, 1),
    (0, 1, 1): (1, 0),
    (1, 0, 0): (0, 1),
    (1, 0, 1): (1, 0),
    (1, 1, 0): (1, 0),
    (1, 1, 1): (1, 1),
}

ROW = re.compile(r"^\s*([01xzXZ])\s+([01xzXZ])\s+([01xzXZ])\s*\|\s*([01xzXZ])\s+([01xzXZ])\s*$")


def parse(path):
    rows = []
    with open(path) as fh:
        for line in fh:
            m = ROW.match(line.rstrip("\n"))
            if m:
                rows.append(tuple(g.lower() for g in m.groups()))
    return rows


def main():
    if len(sys.argv) < 2:
        print("usage: check_table.py <printed-table.txt> [--label NAME]")
        return 2
    path = sys.argv[1]
    label = path
    if "--label" in sys.argv:
        label = sys.argv[sys.argv.index("--label") + 1]

    try:
        rows = parse(path)
    except FileNotFoundError:
        print(f"FAIL -- {label}: no output file at {path}.")
        print("       The simulation did not run. Read the iverilog error above this line.")
        return 1

    print(f"--- grading {label} ---")

    if len(rows) != 8:
        print(f"FAIL -- {label}: found {len(rows)} table rows, expected 8.")
        print("       tb/print_table.sv prints exactly eight. Did the run stop early?")
        return 1

    undriven = sum(1 for r in rows if r[3] in "xz" or r[4] in "xz")
    bad = []
    for a_s, b_s, c_s, cout_s, sum_s in rows:
        if a_s not in "01" or b_s not in "01" or c_s not in "01":
            continue
        key = (int(a_s), int(b_s), int(c_s))
        want_cout, want_sum = REFERENCE[key]
        got = (cout_s, sum_s)
        if got != (str(want_cout), str(want_sum)):
            bad.append((key, got, (want_cout, want_sum)))

    if not bad:
        print(f"PASS -- {label}: all 8 rows match the truth table.")
        print("       8 rows is not a sample of this circuit's behaviour. It is all of it.")
        return 0

    print(f"FAIL -- {label}: {len(bad)} of 8 rows disagree.")
    if undriven == 8:
        print()
        print("       Every output is x. In Verilog, x does not mean 'wrong answer' --")
        print("       it means NOBODY DROVE THIS WIRE. Your module declares sum and cout")
        print("       and then never assigns them, so they have no value at all.")
        print("       That is the shipped stub, exactly as it came. The assign lines")
        print("       are the part that is yours.")
    print()
    for (a, b, c), (gc, gs), (wc, ws) in bad:
        total = a + b + c
        print(
            f"       a={a} b={b} cin={c}: you printed cout={gc} sum={gs}; "
            f"the table says cout={wc} sum={ws}."
        )
        print(
            f"                     {a} + {b} + {c} = {total}, which is "
            f"{wc}{ws} in binary."
        )
    return 1


if __name__ == "__main__":
    sys.exit(main())
