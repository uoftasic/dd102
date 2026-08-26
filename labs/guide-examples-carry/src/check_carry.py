#!/usr/bin/env python3
"""Grade the width sweep behind docs/guide/the-carry-has-to-travel.md.

Reads the yosys and nextpnr logs this package's Makefile already wrote and
compares every number the guide page prints against the reference run on
hpretl/iic-osic-tools:2026.04 (Yosys 0.64, nextpnr-ice40 0.10-33-ge6ecd8fa).

Prints a verdict line. Never raises, never exits non-zero: read the text.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

# Reference run: hpretl/iic-osic-tools:2026.04, Yosys 0.64,
# nextpnr-ice40 0.10-33-ge6ecd8fa. Every one of these is on the guide page.
REFERENCE = {
    4: dict(luts=8, lcs=10, io=14, logic=3.85, routing=19.01, total=22.86),
    8: dict(luts=16, lcs=18, io=26, logic=6.99, routing=36.20, total=43.19),
    12: dict(luts=24, lcs=26, io=38, logic=10.82, routing=47.42, total=58.24),
}
REF16 = dict(luts=32, lcs=34, io=50, cell="b[12]$sb_io")
CELLS = 5280
PINS = 39


def read(path: pathlib.Path) -> str:
    try:
        return path.read_text(errors="replace")
    except OSError:
        return ""


def luts_of(text: str) -> int | None:
    """The SB_LUT4 count from the LAST 'Printing statistics' block."""
    block = text.rsplit("Printing statistics", 1)[-1]
    m = re.search(r"^\s*(\d+)\s+SB_LUT4\s*$", block, re.M)
    return int(m.group(1)) if m else None


def util_of(text: str, kind: str) -> int | None:
    hits = re.findall(rf"{re.escape(kind)}:\s*(\d+)/\s*\d+", text)
    return int(hits[-1]) if hits else None


def split_of(text: str) -> tuple[float, float] | None:
    hits = re.findall(r"([\d.]+) ns logic, ([\d.]+) ns routing", text)
    return (float(hits[-1][0]), float(hits[-1][1])) if hits else None


def total_of(text: str) -> float | None:
    """Last cumulative figure in nextpnr's critical path report."""
    tail = text.split("Critical path report", 1)[-1]
    hits = re.findall(r"^Info:\s+(?:routing|logic)\s+[\d.]+\s+([\d.]+)", tail, re.M)
    return float(hits[-1]) if hits else None


def say(ok: bool, name: str, msg: str) -> None:
    print(f"{'PASS' if ok else 'FAIL'}  {name:<9} {msg}")


def width(res: pathlib.Path, n: int) -> None:
    ref = REFERENCE[n]
    ys = read(res / f"ys{n}.log")
    pnr = read(res / f"pnr{n}.log")
    if not ys or not pnr:
        say(False, f"n{n}", f"no logs for {n} bits -- run `make widths` first")
        return

    got = dict(
        luts=luts_of(ys),
        lcs=util_of(pnr, "ICESTORM_LC"),
        io=util_of(pnr, "SB_IO"),
    )
    split = split_of(pnr)
    got["logic"], got["routing"] = split if split else (None, None)
    got["total"] = total_of(pnr)

    bad = [
        f"{k}: got {got[k]}, reference says {ref[k]}"
        for k in ("luts", "lcs", "io", "logic", "routing", "total")
        if got[k] is None or abs(got[k] - ref[k]) > 1e-9
    ]
    if bad:
        say(False, f"n{n}", f"{n} bits -- " + "; ".join(bad))
        return
    say(
        True,
        f"n{n}",
        f"{n} bits: {ref['luts']} SB_LUT4, {ref['lcs']}/{CELLS} cells, "
        f"{ref['io']}/{PINS} pins, {ref['logic']:.2f} ns logic + "
        f"{ref['routing']:.2f} ns routing = {ref['total']:.2f} ns",
    )


def wall(res: pathlib.Path) -> None:
    ys = read(res / "ys16.log")
    pnr = read(res / "pnr16.log")
    if not ys or not pnr:
        say(False, "n16", "no logs for 16 bits -- run `make wall` first")
        return

    got_luts, got_lcs, got_io = luts_of(ys), util_of(pnr, "ICESTORM_LC"), util_of(pnr, "SB_IO")
    named = REF16["cell"] in pnr
    refused = "Unable to find a placement location" in pnr

    bad = []
    if got_luts != REF16["luts"]:
        bad.append(f"SB_LUT4: got {got_luts}, reference says {REF16['luts']}")
    if got_lcs != REF16["lcs"]:
        bad.append(f"logic cells: got {got_lcs}, reference says {REF16['lcs']}")
    if got_io != REF16["io"]:
        bad.append(f"pins: got {got_io}, reference says {REF16['io']}")
    if not refused:
        bad.append("nextpnr did not refuse the placement, and it should have")
    if not named:
        bad.append(f"the error did not name {REF16['cell']}")
    if bad:
        say(False, "n16", "16 bits -- " + "; ".join(bad))
        return
    say(
        True,
        "n16",
        f"16 bits: {REF16['luts']} SB_LUT4 and only {REF16['lcs']}/{CELLS} cells, "
        f"but {REF16['io']}/{PINS} pins -- nextpnr refuses, naming {REF16['cell']}",
    )


def slope(res: pathlib.Path) -> None:
    """The whole point of the page: logic grows per bit, routing does not."""
    got = {}
    for n in REFERENCE:
        split = split_of(read(res / f"pnr{n}.log"))
        if not split:
            say(False, "slope", f"no critical path for {n} bits -- run `make widths` first")
            return
        got[n] = split[0]

    per_bit = (got[12] - got[8]) / 4
    ref_per_bit = (REFERENCE[12]["logic"] - REFERENCE[8]["logic"]) / 4
    if abs(per_bit - ref_per_bit) > 5e-3:
        say(False, "slope", f"logic grew {per_bit:.2f} ns/bit, reference says {ref_per_bit:.2f}")
        return
    frac = REFERENCE[4]["routing"] / REFERENCE[4]["total"]
    say(
        True,
        "slope",
        f"the logic column grows {per_bit:.2f} ns per bit -- one full adder each -- "
        f"while routing is {frac * 100:.0f} % of the 4-bit delay",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("results", type=pathlib.Path, help="the results/ directory")
    ap.add_argument("--expect", required=True, choices=["n4", "n8", "n12", "n16", "slope"])
    args = ap.parse_args()

    if args.expect == "n16":
        wall(args.results)
    elif args.expect == "slope":
        slope(args.results)
    else:
        width(args.results, int(args.expect[1:]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
