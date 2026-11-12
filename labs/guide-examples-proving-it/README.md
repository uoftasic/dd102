# Guide examples: proving it works

The testbenches, adders and waveform views behind the guide pages
[Testbenches](../../docs/guide/eight-rows-and-no-opinions.md) and
[Waveforms](../../docs/guide/two-lines-make-the-waveform-appear.md), complete, plus two files that
are wrong on purpose. This isn't a lab of its own; [Lab 02](../../docs/labs/lab-02-prove-it-overview.md)
(Parts 1 and 2) and [Lab 03](../../docs/labs/lab-03-the-lazy-testbench-overview.md) (Parts 1 to 3
and 8) walk through it.

```bash
cd labs/guide-examples-proving-it
make
```

No `.designinit`, `mod`, PDK, liberty file or environment variables. It takes about 0.4 seconds
and ends with five `PASS` lines.

## Targets

| Command | What it does |
|---|---|
| `make` | `eight`, `eight-broken`, `six`, `sweep`, `fixed`, `check`, in that order |
| `make eight` | one full adder against all 8 of its inputs |
| `make eight-broken` | the same testbench against the wrong adder |
| `make six` | six hand-picked cases on the broken ripple adder |
| `make sweep` | all 512 inputs on that same broken adder |
| `make clue` | the sweep again, with the per-input breakdown |
| `make fixed` | all 512 inputs on the repaired adder |
| `make eight-bit` | the same sweep on the 8-bit adder: 131,072 vectors, with a wall time |
| `make lint` | what Verilator says, and doesn't say, about each broken file |
| `make check` | re-run the five verdicts against the reference numbers |
| `make wave` | GTKWave on `results/sweep.vcd` (needs the noVNC desktop) |
| `make surfer` | Surfer on the same file (needs the noVNC desktop) |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| `src/full_adder.sv` | The DD101 drawing, one wire at a time. The same file as [`../guide-examples/src/full_adder.sv`](../guide-examples/src/full_adder.sv). |
| `src/ripple4.sv` | Four of those in a row, carry in to carry out. 4-bit sum plus `cout`. |
| `src/tb_eight_rows.sv` | All 8 inputs of one full adder, against the DD101 table. Dumps `eight.vcd`. |
| `src/tb_six_cases.sv` | Six cases picked by hand. |
| `src/tb_sweep.sv` | All 512 inputs of `ripple4`. Dumps `sweep.vcd`. `+clue` adds the per-input breakdown. |
| `src/ripple8.sv` | The same adder eight bits wide, for pricing a 131,072-vector sweep. |
| `src/tb_sweep8.sv` | All 131,072 inputs of `ripple8`. No waveform. |
| `src/tb_eight_rows_compact.sv` | `tb_eight_rows.sv` with the compact `'{...}` array initialiser. Runs on Icarus 14.0, fails on Icarus 12.0. |
| `src/check_sim.py` | The grader. Reads a log, finds `TESTED`/`ERRORS`/`VERDICT`, says PASS or FAIL. |
| `broken/full_adder.sv` | `src/full_adder.sv` with an `&` where the drawing has an Or. |
| `broken/ripple4.sv` | `src/ripple4.sv` with one line changed: `assign c[0] = 1'b0;`. |
| `views/eight.gtkw` | GTKWave save file for `results/eight.vcd`. |
| `views/sweep.gtkw` | GTKWave save file for `results/sweep.vcd`, marker on the first mismatch. |
| `views/sweep.surf` | The same seven signals for Surfer, as a `--command-file`. |
| `views/radix.gtkw` | One nine-bit signal three times, as hex, decimal and binary: the figure in [Reading a waveform](../../docs/reference/reading-a-waveform.md). |

The five verdicts are counts of integers from a deterministic simulation with no clock and no
randomness, so there is no tolerance: either you get 256 or something is different. They are the
same on Icarus Verilog 12.0, which EDA Playground runs, except for `src/tb_eight_rows_compact.sv`,
which is there because it doesn't survive the trip. The wall time from `make eight-bit` is a
ballpark; the counts above it aren't.
