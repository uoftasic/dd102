#!/usr/bin/env python3
"""check_card.py — the verdict for the DD102 reference card.

Reads results/card.log (one line per card, produced by `make`) and compares it
against reference/card.expected, line for line, character for character.

Prints PASS or FAIL per card and exits 1 if any card disagrees. No arguments,
no environment variables, no PDK.
"""
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent.parent
GOT = HERE / "results" / "card.log"
WANT = HERE / "reference" / "card.expected"


def rows(path):
    if not path.exists():
        sys.exit(f"FAIL  missing {path}. Run `make` first.")
    out = {}
    for line in path.read_text().splitlines():
        line = line.rstrip()
        if ":" in line and line.split(":", 1)[0].strip()[:2].isdigit():
            key, val = line.split(":", 1)
            out[key.strip()] = val.strip()
    return out


def main():
    got, want = rows(GOT), rows(WANT)
    bad = 0
    for key in sorted(want):
        g = got.get(key)
        if g is None:
            print(f"FAIL  {key:22s} nothing in your log")
            bad += 1
        elif g != want[key]:
            print(f"FAIL  {key:22s}")
            print(f"        you got : {g}")
            print(f"        reference: {want[key]}")
            bad += 1
        else:
            print(f"PASS  {key:22s} {g}")
    extra = sorted(set(got) - set(want))
    for key in extra:
        print(f"NOTE  {key:22s} not in the reference file")
    print()
    if bad:
        print(f"VERDICT FAIL  — {bad} of {len(want)} cards disagree with the reference run.")
        print("Every one of these came from hpretl/iic-osic-tools:2026.04. If yours differ,")
        print("check `iverilog -V` says 14.0 before you suspect your typing.")
        return 1
    print(f"VERDICT PASS  — all {len(want)} cards match the reference run.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
