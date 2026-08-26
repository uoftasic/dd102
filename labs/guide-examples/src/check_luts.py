#!/usr/bin/env python3
"""Grade the LUT-cost experiment against the reference run.

Reference numbers were measured with Yosys 0.64 (`synth_ice40`) inside
hpretl/iic-osic-tools:2026.04. They are printed on the guide page
docs/guide/the-chip-is-already-there.md and must not drift from it.

    python3 src/check_luts.py results/luts.txt
"""

from __future__ import annotations

import sys

# module -> (expected SB_LUT4, what the number is meant to teach)
REFERENCE = {
    "lut_simple": (1, "a & b & c & d              -- four inputs"),
    "lut_parity": (1, "a ^ b ^ c ^ d              -- four inputs"),
    "lut_weird":  (1, "(a^b) ? (c&~d) : (~c|d)    -- four inputs"),
    "lut_five":   (2, "a & b & c & d & e          -- FIVE inputs"),
}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_luts.py results/luts.txt", file=sys.stderr)
        return 2

    got: dict[str, int] = {}
    with open(sys.argv[1]) as fh:
        for line in fh:
            parts = line.split()
            if len(parts) == 2 and parts[1].isdigit():
                got[parts[0]] = int(parts[1])

    failed = []
    for name, (want, blurb) in REFERENCE.items():
        have = got.get(name)
        ok = have == want
        if not ok:
            failed.append(name)
        print(f"{'PASS' if ok else 'FAIL'}  {name:<12} {have if have is not None else '?':>2}"
              f" SB_LUT4, reference says {want}   {blurb}")

    print()
    if failed:
        print("FAIL - at least one count does not match the reference run.")
        print("       Check `yosys -V` says 0.64. If it does, say so in the")
        print("       team Discord: https://discord.gg/hrJnP5UsGz")
        return 1

    print("PASS - three different 4-input functions cost ONE lookup table each.")
    print("       One extra input cost a second one, on the simplest function here.")
    print("       On an FPGA the price is the number of inputs, not the difficulty.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
