#!/usr/bin/env python3
"""check_run.py -- the grader for Lab 03.

Reads what a testbench printed and compares it against the reference numbers
measured on hpretl/iic-osic-tools:2026.08 (Icarus Verilog 14.0). Standard
library only; Python 3.12.3.

    python3 src/check_run.py results/lazy.txt   --stage lazy
    python3 src/check_run.py results/all512.txt --stage exhaustive
    python3 src/check_run.py results/fixed.txt  --stage fixed
    python3 src/check_run.py --summary
"""

import os
import re
import sys

SCOREBOARD = "results/scoreboard.txt"

# Measured, not guessed. `make` reproduces every one of these.
REF_TOTAL = 512
REF_ERRORS = 256
REF_CIN0 = 120
REF_CIN1 = 136


def read(path):
    try:
        text = open(path).read()
    except FileNotFoundError:
        return {}
    out = {}
    for key, pat in (
        ("tested", r"^TESTED\s+(\d+)\s*$"),
        ("errors", r"^ERRORS\s+(\d+)\s*$"),
        ("cin0", r"^\s+with cin=0\s*:\s*(\d+)\s*$"),
        ("cin1", r"^\s+with cin=1\s*:\s*(\d+)\s*$"),
    ):
        m = re.search(pat, text, re.M)
        if m:
            out[key] = int(m.group(1))
    m = re.search(r"^VERDICT\s+(PASS|FAIL)\s*$", text, re.M)
    if m:
        out["verdict"] = m.group(1)
    return out


def note(line):
    os.makedirs("results", exist_ok=True)
    with open(SCOREBOARD, "a") as fh:
        fh.write(line + "\n")


def stage_lazy(r):
    if not r.get("verdict"):
        print("BROKEN  -- tb/tb_lazy.sv printed no VERDICT line. Did it compile?")
        note("BROKEN|lazy|0")
        return 1
    n = r.get("tested", 0)
    if r["verdict"] == "PASS":
        print(f"PASS    -- your {n} hand-picked cases all agreed with add4.")
        print(f"           {n} of the 512 inputs add4 can see. Write that fraction down.")
        note(f"PASS|lazy|{n}")
        return 0
    print(f"FAIL    -- one of your {n} cases disagreed with add4, and you found it")
    print("           before this lab showed it to you. That is a better outcome than")
    print("           the one the lab was aiming for. Keep going anyway -- `make")
    print("           exhaustive` tells you how many more there are.")
    note(f"FOUND|lazy|{n}")
    return 0


def stage_exhaustive(r):
    if not r.get("verdict"):
        print("BROKEN  -- tb/tb_exhaustive.sv printed no VERDICT line. Did it compile?")
        note("BROKEN|exhaustive|0")
        return 1
    t, e = r.get("tested"), r.get("errors")
    c0, c1 = r.get("cin0"), r.get("cin1")
    if (t, e, c0, c1) == (REF_TOTAL, REF_ERRORS, REF_CIN0, REF_CIN1):
        print(f"MATCH   -- {e} of {t} inputs are wrong. That is the reference number,")
        print(f"           to the digit: {c0} of them with cin=0, {c1} with cin=1,")
        print(f"           and {c0} + {c1} = {c0 + c1}.")
        print("           Exactly half of add4's inputs produce the wrong answer, and")
        print("           six hand-picked cases hit none of them.")
        note(f"MATCH|exhaustive|{e}/{t}")
        return 0
    print(f"DRIFT   -- expected {REF_ERRORS} of {REF_TOTAL} ({REF_CIN0} + {REF_CIN1});")
    print(f"           this run says {e} of {t} ({c0} + {c1}).")
    print("           src/add4.sv or src/full_adder.sv is not the shipped one.")
    note(f"DRIFT|exhaustive|{e}/{t}")
    return 1


def stage_fixed(r):
    if not r.get("verdict"):
        print("BROKEN  -- tb/tb_exhaustive_fixed.sv printed no VERDICT line.")
        note("BROKEN|fixed|0")
        return 1
    t, e = r.get("tested"), r.get("errors")
    if (t, e) == (REF_TOTAL, 0):
        print(f"MATCH   -- {t} of {t} inputs correct, {e} mismatches. add5 is right about")
        print("           every number it will ever be handed.")
        note(f"MATCH|fixed|{e}/{t}")
        return 0
    print(f"DRIFT   -- expected 0 of {REF_TOTAL} wrong; this run says {e} of {t}.")
    note(f"DRIFT|fixed|{e}/{t}")
    return 1


def summary():
    try:
        rows = [l.rstrip("\n").split("|") for l in open(SCOREBOARD) if l.strip()]
    except FileNotFoundError:
        print("No scoreboard. Run `make` first.")
        return 1
    seen = {r[1]: r for r in rows}
    print("=" * 62)
    print(" VERDICT")
    print("=" * 62)
    labels = {
        "lazy": "tb_lazy.sv        vs add4  (a few cases)",
        "exhaustive": "tb_exhaustive.sv  vs add4  (all 512)  ",
        "fixed": "tb_exhaustive_fixed.sv vs add5 (all 512)",
    }
    for key in ("lazy", "exhaustive", "fixed"):
        r = seen.get(key)
        state = r[0] if r else "not run"
        detail = r[2] if r else ""
        print(f" {labels[key]:<42}: {state:<7} {detail}")
    print("-" * 62)
    ok = (
        seen.get("lazy", [""])[0] in ("PASS", "FOUND")
        and seen.get("exhaustive", [""])[0] == "MATCH"
        and seen.get("fixed", [""])[0] == "MATCH"
    )
    if ok:
        print(" The same design passed one testbench and failed another by 256 rows.")
        print(" The testbench was the variable, not the adder.")
        print()
        print(" Reflex: N bits plus N bits does not fit in N bits. Every adder you")
        print(" ever write needs somewhere for the top carry to go -- and every")
        print(" testbench you ever write needs a case that puts something there.")
        print("=" * 62)
        return 0
    print(" Something above is not what it should be. The first line that is not")
    print(" PASS or MATCH is the real problem; the rest is fallout.")
    print("=" * 62)
    return 1


def main():
    argv = sys.argv[1:]
    if argv and argv[0] == "--summary":
        return summary()
    if len(argv) < 3 or "--stage" not in argv:
        print("usage: check_run.py <run.txt> --stage lazy|exhaustive|fixed")
        return 2
    path = argv[0]
    stage = argv[argv.index("--stage") + 1]
    r = read(path)
    return {"lazy": stage_lazy, "exhaustive": stage_exhaustive, "fixed": stage_fixed}[stage](r)


if __name__ == "__main__":
    sys.exit(main())
