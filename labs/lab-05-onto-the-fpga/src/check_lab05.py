#!/usr/bin/env python3
"""Check the artefacts this lab produces against the reference run.

Three kinds of check:

  * `--expect <name>` on a **log** looks for exact patterns a tool printed.
  * `--expect bitstream` on a **.bin** checks its size in bytes.
  * `--sizes a.bin b.bin ...` prints the size table and fails unless every file
    is the same size.
  * `--lcs post.json` lists the logic cells nextpnr actually placed, and checks
    that the two nobody wrote are still there.

Every check prints one line starting with PASS or FAIL and exits non-zero on FAIL.

    python3 src/check_lab05.py results/pnr.log --expect util
    python3 src/check_lab05.py results/r4.bin  --expect bitstream
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

BITSTREAM_BYTES = 104090

# name -> (list of regexes, description)
TEXTS = {
    "luts": (
        [r"^\s+9\s+SB_LUT4$"],
        "synth_ice40 mapped ripple4 to 9 SB_LUT4",
    ),
    "util": (
        [r"ICESTORM_LC:\s+11/\s+5280", r"SB_IO:\s+14/\s+39"],
        "nextpnr placed 11/5280 logic cells and 14/39 pins",
    ),
    "path": (
        [r"2\.98 ns logic, 23\.24 ns routing"],
        "the critical path is 2.98 ns of logic and 23.24 ns of wire",
    ),
    "nofmax": (
        [r"No Fmax available; no interior timing paths found in design\."],
        "no flip-flops, so --freq 50 had nothing to check",
    ),
    "one_gate": (
        [r"ICESTORM_LC:\s+3/\s+5280", r"SB_IO:\s+3/\s+39"],
        "one_gate placed 3/5280 logic cells and 3/39 pins",
    ),
    "big": (
        [r"ICESTORM_LC:\s+4001/\s+5280", r"SB_IO:\s+3/\s+39",
         r"Max frequency for clock 'clk\$SB_IO_IN_\$glb_clk': 202\.92 MHz \(PASS at 50\.00 MHz\)"],
        "big placed 4001/5280 logic cells and closes timing at 202.92 MHz",
    ),
    "toobig": (
        [r"SB_IO:\s+64/\s+39\s+164%",
         r"ERROR: Unable to find a placement location for cell 'p\[29\]\$sb_io'"],
        "toobig needs 64 pins, the package has 39, and nextpnr says so",
    ),
    "pins": (
        [r"Placed 14 cells based on constraints\.", r"2\.95 ns logic, 11\.16 ns routing"],
        "the .pcf placed all 14 pins; the path got 12.1 ns shorter end to end",
    ),
    "asic": (
        [r"4\s+40\.038\s+sky130_fd_sc_hd__maj3_1",
         r"8\s+70\.067\s+sky130_fd_sc_hd__xnor2_1",
         r"Chip area for module '\\ripple4': 110\.105600"],
        "the same RTL on SKY130: 4 maj3_1 + 8 xnor2_1 = 110.1056 um^2",
    ),
}

DRIFT = """      Yours differs from the reference run. Either a file in this package
      was edited, or you are not on hpretl/iic-osic-tools:2026.08.
      Paste this line into Discord: https://discord.gg/hrJnP5UsGz"""


def check_text(path: Path, name: str) -> int:
    pats, what = TEXTS[name]
    text = path.read_text(errors="replace")
    missing = [p for p in pats if not re.search(p, text, re.M)]
    ok = not missing
    print(f"{'PASS' if ok else 'FAIL'}  {name:<9} {what}")
    if not ok:
        for p in missing:
            print(f"      no line in {path} matches: {p}")
        print(DRIFT)
    return 0 if ok else 1


def check_bitstream(path: Path) -> int:
    n = path.stat().st_size
    ok = n == BITSTREAM_BYTES
    print(f"{'PASS' if ok else 'FAIL'}  bitstream {path.name} is {n} bytes, "
          f"reference says {BITSTREAM_BYTES}")
    if not ok:
        print(DRIFT)
    return 0 if ok else 1


def check_sizes(paths: list[Path]) -> int:
    missing = [p for p in paths if not p.exists()]
    if missing:
        for p in missing:
            print(f"FAIL  sizes     {p} does not exist -- that step never ran.")
        return 1
    print("  bitstream            bytes")
    sizes = []
    for p in paths:
        n = p.stat().st_size
        sizes.append(n)
        print(f"  {p.name:<18} {n:>8}")
    ok = len(set(sizes)) == 1 and sizes[0] == BITSTREAM_BYTES
    print()
    print(f"{'PASS' if ok else 'FAIL'}  sizes     "
          f"{len(paths)} designs, {'all' if ok else 'NOT all'} "
          f"{BITSTREAM_BYTES} bytes")
    if not ok:
        print(DRIFT)
    return 0 if ok else 1


def check_lcs(path: Path) -> int:
    """List the ICESTORM_LC cells in a placed netlist and account for all of them."""
    import json
    d = json.loads(path.read_text())
    cells = d["modules"]["top"]["cells"]
    lcs = sorted(k for k, v in cells.items() if v["type"] == "ICESTORM_LC")
    yours = [k for k in lcs if not k.startswith("$PACKER")]
    packer = [k for k in lcs if k.startswith("$PACKER")]
    for k in yours:
        print(f"    {k}")
    for k in packer:
        print(f"    {k}      <- nobody wrote this one")
    ok = (len(yours), sorted(packer)) == (9, ["$PACKER_GND", "$PACKER_VCC"])
    print()
    print(f"{'PASS' if ok else 'FAIL'}  lcs       {len(lcs)} logic cells placed: "
          f"{len(yours)} from your RTL + {len(packer)} the packer added")
    if not ok:
        print(DRIFT)
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--expect", choices=sorted(set(TEXTS) | {"bitstream"}))
    ap.add_argument("--sizes", action="store_true")
    ap.add_argument("--lcs", action="store_true")
    args = ap.parse_args()

    for f in args.files:
        if not f.exists():
            label = "sizes" if args.sizes else (args.expect or "?")
            print(f"FAIL  {label:<9} {f} does not exist -- that step never ran.")
            return 1

    if args.sizes:
        return check_sizes(args.files)
    if args.lcs:
        return max(check_lcs(f) for f in args.files)
    if args.expect == "bitstream":
        return max(check_bitstream(f) for f in args.files)
    if args.expect is None:
        ap.error("give --expect, --sizes or --lcs")
    return max(check_text(f, args.expect) for f in args.files)


if __name__ == "__main__":
    sys.exit(main())
