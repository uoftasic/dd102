# Guide examples — proving it works

Every runnable file printed in the **Proving it** guide pages lives here, complete.
Nothing on those pages is an excerpt: if a page shows you SystemVerilog, the whole file
is in this folder and it runs exactly as shipped.

This is **not** a lab. It is the finished version, plus two files that are wrong on
purpose, so the guide pages have something real to point at.

```bash
cd labs/guide-examples-proving-it
make
```

No `.designinit`, no `mod`, no PDK, no liberty file, no environment variables. It takes
about **0.4 seconds** and ends with five `PASS` lines.

## What's here

| File | What it is |
|---|---|
| `src/full_adder.sv` | The DD101 drawing, transcribed one wire at a time. Same file as [`labs/guide-examples/src/full_adder.sv`](../guide-examples/src/full_adder.sv). |
| `src/ripple4.sv` | Four of those in a row, carry-in to carry-out. 4-bit sum plus `cout`. |
| `src/tb_eight_rows.sv` | All 8 inputs of one full adder, against your DD101 table. Dumps `eight.vcd`. |
| `src/tb_six_cases.sv` | Six cases picked by hand. The testbench almost everybody writes first. |
| `src/tb_sweep.sv` | All 512 inputs of `ripple4`. Dumps `sweep.vcd`. `+clue` adds the per-input breakdown. |
| `src/ripple8.sv` | The same adder eight bits wide. Exists so you can price a 131,072-vector sweep. |
| `src/tb_sweep8.sv` | All 131,072 inputs of `ripple8`. No waveform — a VCD that size helps nobody. |
| `src/tb_eight_rows_compact.sv` | `tb_eight_rows.sv` with the compact `'{...}` array initialiser. Runs on Icarus 14.0, **fails on Icarus 12.0**. Shipped so the guide can print the real error. |
| `src/check_sim.py` | **The grader.** Reads a log, finds `TESTED`/`ERRORS`/`VERDICT`, says PASS or FAIL. |
| `broken/full_adder.sv` | `src/full_adder.sv` with an `&` where the drawing has an Or. |
| `broken/ripple4.sv` | `src/ripple4.sv` with one line changed: `assign c[0] = 1'b0;`. |
| `views/eight.gtkw` | GTKWave save file for `results/eight.vcd` — five signals, already zoomed. |
| `views/sweep.gtkw` | GTKWave save file for `results/sweep.vcd` — seven signals, marker on the first mismatch. |
| `views/sweep.surf` | The same seven signals for Surfer, as a `--command-file`. |
| `views/radix.gtkw` | One nine-bit signal, three times, as hex / decimal / binary. The figure in [Reading a waveform](../../docs/reference/reading-a-waveform.md). |

## Targets

| Command | What it does |
|---|---|
| `make` | `eight`, `eight-broken`, `six`, `sweep`, `fixed`, `check` — in that order |
| `make eight` | one full adder against all 8 of its inputs |
| `make eight-broken` | the same testbench against the wrong adder, so you can read a FAIL |
| `make six` | six hand-picked cases on the **broken** ripple adder |
| `make sweep` | all 512 inputs on that same broken adder |
| `make clue` | the sweep again, with the per-input breakdown that names the guilty signal |
| `make fixed` | all 512 inputs on the repaired adder |
| `make eight-bit` | the same sweep on the 8-bit adder — 131,072 vectors |
| `make lint` | what Verilator says about each broken file — and does not say |
| `make check` | re-run the five verdicts against the reference numbers |
| `make wave` | GTKWave on `results/sweep.vcd` (needs the noVNC desktop) |
| `make surfer` | Surfer on the same file |
| `make clean` | empty `results/` |

## Expected results

Measured on `hpretl/iic-osic-tools:2026.08` — Icarus Verilog 14.0, Verilator 5.050,
Python 3.12.3. `src/check_sim.py` knows these numbers and will tell you if yours drift.

```
PASS  eight         got PASS 0/8, reference says PASS 0/8
PASS  eight_broken  got FAIL 4/8, reference says FAIL 4/8
PASS  six           got PASS 0/6, reference says PASS 0/6
PASS  sweep         got FAIL 256/512, reference says FAIL 256/512
PASS  fixed         got PASS 0/512, reference says PASS 0/512
```

Read that table twice. Line 3 says a testbench **passed** on the same file that line 4
says is wrong 256 times. That is not a bug in the package; it is the whole point of it.

**These are golden numbers, not ballparks.** Every one of them is a count of integers,
produced by a deterministic simulation of a design with no clock and no randomness, so
there is no tolerance to state — either you get 256 or something is different.

Verified identical on **Icarus Verilog 12.0**, which is what EDA Playground runs, so you
get the same five verdicts in the browser as in the workbench. The one exception is
`src/tb_eight_rows_compact.sv`, which is there precisely because it does *not* survive the
trip:

```
testbench.sv:20: sorry: Assignment to an entire array or to an array slice is not yet supported.
Elaboration failed
```

`make eight-bit` prints `TESTED 131072 / ERRORS 0 / VERDICT PASS` and a wall time. The counts
are golden; the wall time is a **ballpark** — repeated runs on the workbench landed between
0.59 s and 0.63 s.

`make lint` prints `%Warning-UNUSEDSIGNAL` for `broken/ripple4.sv` and **exit 0 with
zero warnings** for `broken/full_adder.sv`. Both of those are correct behaviour from
Verilator and the guide page explains why.

## Links

- Guide: [Eight rows and no opinions](../../docs/guide/eight-rows-and-no-opinions.md)
- Guide: [Two lines make the waveform appear](../../docs/guide/two-lines-make-the-waveform-appear.md)
- Stuck? [Team Discord](https://discord.gg/hrJnP5UsGz)
