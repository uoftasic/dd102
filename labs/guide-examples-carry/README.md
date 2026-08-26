# guide-examples-carry

The runnable half of
[**The carry has to travel**](https://uoftasic.com/dd102/#/guide/the-carry-has-to-travel).

One file — `src/ripple.sv`, the parameterised adder from Lab 04 — synthesized and placed at
four widths on a Lattice iCE40 UP5K, so you can watch the two halves of the delay behave
completely differently as the adder gets wider.

```bash
cd labs/guide-examples-carry
make
```

No environment setup. No `.designinit`, no PDK, no liberty file, no `mod`. `make` alone in
a bare `hpretl/iic-osic-tools:2026.04` container runs the whole thing in a few seconds and
ends in five `PASS`/`FAIL` verdicts.

| target | what it does |
|---|---|
| `make widths` | 4, 8 and 12 bits through `yosys synth_ice40` + `nextpnr-ice40` |
| `make wall` | 16 bits, which does **not** fit — and not for the reason you expect |
| `make check` | every number on the guide page, against the reference run |
| `make clean` | delete `results/`, keep sources |

## Files

| path | what it is |
|---|---|
| `src/ripple.sv` | the parameterised ripple adder (identical to Lab 04's) |
| `src/full_adder.sv` | one bit of it (identical to Lab 04's) |
| `src/top4.sv` … `src/top16.sv` | fixed-width wrappers, so nextpnr has a top module to place |
| `src/check_carry.py` | the grader — reads the logs `make` already wrote |

`src/ripple.sv` is parameterised, so it cannot be a top module on its own: `nextpnr` places
*pins*, and pins need a fixed width. That is the only thing the `topN.sv` wrappers do.

## Reference numbers

Measured on `hpretl/iic-osic-tools:2026.04` — Yosys 0.64, nextpnr-ice40 0.10-33-ge6ecd8fa.

| width | `SB_LUT4` | logic cells | pins | logic | routing | total |
|---|---|---|---|---|---|---|
| 4 bits | 8 | 10 / 5280 | 14 / 39 | 3.85 ns | 19.01 ns | **22.86 ns** |
| 8 bits | 16 | 18 / 5280 | 26 / 39 | 6.99 ns | 36.20 ns | **43.19 ns** |
| 12 bits | 24 | 26 / 5280 | 38 / 39 | 10.82 ns | 47.42 ns | **58.24 ns** |
| 16 bits | 32 | 34 / 5280 | **50 / 39** | — | — | `ERROR: Unable to find a placement location for cell 'b[12]$sb_io'` |

The logic column grows **0.96 ns per bit** — one full adder each. The routing column does
not, and it is **83 %** of the four-bit delay. Sixteen bits runs out of **pins** while using
under one percent of the logic.
