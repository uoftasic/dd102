# Guide examples: carry delay

The runnable half of the guide page [Carry delay](../../docs/guide/the-carry-has-to-travel.md)
([on the course site](https://uoftasic.com/dd102/guide/the-carry-has-to-travel.html)). One file,
`src/ripple.sv`, the parameterised adder from Lab 04, synthesized and placed at four widths on a
Lattice iCE40 UP5K. [Lab 05](../../docs/labs/lab-05-onto-the-fpga-overview.md) (Parts 3 and 5)
walks through it.

```bash
cd labs/guide-examples-carry
make
```

No `.designinit`, PDK, liberty file or `mod`. `make` alone in a bare
`hpretl/iic-osic-tools:2026.08` container runs in a few seconds and ends in five `PASS`/`FAIL`
verdicts. On that image the `n12` verdict currently prints `FAIL` (`got 38.99, reference says
39.0`); see the troubleshooting table in the Lab 05 writeup.

## Targets

| Command | What it does |
|---|---|
| `make widths` | 4, 8 and 12 bits through `yosys synth_ice40` and `nextpnr-ice40` |
| `make wall` | 16 bits, which doesn't fit |
| `make check` | every number on the guide page, against the reference run |
| `make clean` | delete `results/`, keep sources |

## Files

| File | What it is |
|---|---|
| `src/ripple.sv` | The parameterised ripple adder (identical to Lab 04's) |
| `src/full_adder.sv` | One bit of it (identical to Lab 04's) |
| `src/top4.sv` … `src/top16.sv` | Fixed-width wrappers, so nextpnr has a top module to place |
| `src/check_carry.py` | The grader. Reads the logs `make` already wrote |

`src/ripple.sv` is parameterised, so it can't be a top module on its own: nextpnr places pins, and
pins need a fixed width. That is the only thing the `topN.sv` wrappers do.
