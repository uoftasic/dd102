# Guide examples

Every runnable file printed in guide pages 1–4 lives here, complete. Nothing in those
pages is an excerpt; if a page shows you SystemVerilog, the whole file is in this folder
and it runs as shipped.

This is **not** a lab. The lab is
[`labs/lab-01-transcribe-your-adder/`](../lab-01-transcribe-your-adder/), where you write
the adder yourself. This folder is the finished version, plus seven files that
misbehave on purpose, so the guide pages have something real to point at.

```bash
cd labs/guide-examples
make
```

No `.designinit`, no `mod`, no environment variables. It takes about **2.6 seconds** and
ends with a `PASS` line.

## What's here

| File | What it is |
|---|---|
| `src/full_adder.sv` | The DD101 drawing, transcribed one wire at a time. Five `assign`s. |
| `src/full_adder_flat.sv` | The same adder as one expression per output. Two `assign`s. |
| `src/full_adder_table.sv` | The same adder as `always_comb` + `case` — your eight rows, one line each. |
| `src/half_adder.sv` | Your DD101 Lab 03 subcircuit, as a module. |
| `src/full_adder_hier.sv` | Two `half_adder` **instances** and an Or. The drawing taken literally. |
| `src/full_adder_backwards.sv` | `full_adder.sv` with the five lines in reverse order. Still correct. |
| `src/tb_full_adder.sv` | The eight rows of the DD101 truth table, as a test. Prints `PASS` or `FAIL`. |
| `src/tb_spellings.sv` | Four spellings driven side by side, same eight rows. |
| `src/tb_backwards.sv` | The eight rows aimed at `full_adder_backwards`. |
| `src/check_area.py` | **The grader for the area numbers.** Reads `stat -json` and says PASS or FAIL. |
| `scripts/area.ys` | Six synthesis runs against the sky130 cell library. |
| `scripts/digitaljs.ys` | The exact Yosys script DigitalJS Online runs in your browser. |
| `broken/full_adder.sv` | `src/full_adder.sv` with one `&` where the drawing has an Or. |
| `errors/call_it_like_a_function.sv` | Calls a module like a function. Does not compile. |
| `errors/two_drivers.sv` | Two `assign`s at one output. Does not compile. |
| `errors/if_inside_assign.sv` | An `if` inside an `assign`. One mistake, five error messages. |
| `errors/both_ways_at_once.sv` | One signal driven by an `always_comb` *and* an `assign`. Icarus errors; Yosys only warns. |
| `errors/undeclared_wire.sv` | An internal wire nobody declared. Icarus is silent; Yosys warns three times. |
| `errors/forgot_a_branch.sv` | An `always_comb` that skips a branch. Simulates fine; Yosys refuses it. |

## Targets

| Command | What it does |
|---|---|
| `make` | `sim`, `broken`, `spellings`, `backwards`, `area`, `table` — in that order |
| `make sim` | the adder against the eight rows |
| `make broken` | the same testbench against the wrong adder, so you can read a FAIL |
| `make spellings` | four modules, one truth table, zero disagreements |
| `make backwards` | the five lines in reverse order — still passes |
| `make area` | what each spelling costs in sky130 silicon |
| `make picture` | `results/full_adder_rtl.svg`, the schematic Yosys draws |
| `make errors` | the six misbehaving files, and the exact text each tool prints |
| `make table` | reprint the verdict from JSON you already have |
| `make clean` | empty `results/` |

## Expected results

Measured on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0, Yosys 0.64,
Python 3.12.3, sky130A. `src/check_area.py` knows these numbers and will tell you if
yours drift.

```
file                cells   area (um^2)   verdict  cells used
------------------------------------------------------------------------------
drawing.json            2       33.7824   PASS     1x maj3_1 + 1x xor3_1
flat.json               2       33.7824   PASS     1x maj3_1 + 1x xor3_1
table.json              2       33.7824   PASS     1x maj3_1 + 1x xor3_1
half.json               2       15.0144   PASS     1x and2_0 + 1x xor2_1
boxes.json              7       36.2848   PASS     2x half_adder + 2x and2_0 + 1x lpflow_inputiso1p_1 + 2x xor2_1
boxes_flat.json         2       33.7824   PASS     1x maj3_1 + 1x xor3_1

PASS - every number matches the reference run, to four decimals.
```

`boxes.json` says **7** cells because Yosys counts the two `half_adder` instances as
cells *and* counts what is inside them: 5 real gates + 2 boxes. `boxes_flat.json` says 2
because `flatten` knocked the walls down and let the synthesizer rebuild across them.

`make errors` prints three lines like `make: [Makefile:90: errors] Error 2 (ignored)`. That is
`make` telling you a command failed and that it was told in advance not to care. Those
files are *supposed* to fail. Nothing is wrong.

## Links

- Guide: [From your drawing to a module](../../docs/guide/from-your-drawing-to-a-module.md)
- Guide: [What a module actually is](../../docs/guide/what-a-module-is.md)
- Guide: [Everything happens at once](../../docs/guide/assign-and-always-comb.md)
- Guide: [Seeing it come back as a schematic](../../docs/guide/seeing-it-come-back.md)
- Stuck? [Team Discord](https://discord.gg/hrJnP5UsGz)
