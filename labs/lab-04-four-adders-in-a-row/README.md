# Lab 04 — Four adders in a row

Writeup: [`docs/labs/lab-04-four-adders-in-a-row-overview.md`](../../docs/labs/lab-04-four-adders-in-a-row-overview.md)

Five experiments on one `generate for` loop. Run them in order — three of them ask you to
commit to a number before you look.

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-04-four-adders-in-a-row
make
```

The whole thing takes **under five seconds** and ends in a table of twelve verdicts.

Individual experiments: `make generate`, `make proof`, `make broken`, `make gotcha`,
`make wide`. `make check` re-runs the verdicts on logs you already have. `make wide12` is
the optional one that takes about four and a half minutes. `make clean` empties `results/`.

**No environment setup is needed.** No `.designinit`, no PDK, no liberty file — the two lines
above are how you get *the repo*, not how you get the tools. If your setup is half-broken,
`make` still runs and still tells you the truth.

## What's here

| File | What it is |
|---|---|
| `src/ripple4.sv` | **The design.** Four full adders from one `generate for` loop. |
| `src/full_adder.sv` | Your Lab 01 module, unchanged since you transcribed your drawing. |
| `src/ripple.sv` | The same adder with its width as a `parameter`. Used by `make wide`. |
| `reference/ripple4_hand.sv` | The Lab 03 version: four instances typed out by hand. The proof compares against this. |
| `broken/ripple4.sv` | One character different. Do not fix it — `make broken` needs it. |
| `errors/ripple4_bit.sv` | The generate block labelled `bit`. Breaks Yosys, **crashes Icarus**. |
| `errors/ripple4_incr.sv` | The same loop with `i++`. It works. That is the point. |
| `tb/tb_ripple4.sv` | All 512 inputs a 4-bit adder can ever see. Prints one PASS/FAIL line. |
| `tb/tb_ripple.sv` | The same test at any width: `iverilog -Ptb_ripple.N=8 …` |
| `scripts/proof.ys` | Builds a miter and asks the SAT solver to prove the two adders equal. |
| `scripts/proof_broken.ys` | The same proof against the broken one. Fails, and names the input. |
| `scripts/check_good.ys`, `scripts/check_broken.ys` | Yosys's `check` pass — finds undriven wires without simulating. |
| `src/check_lab04.py` | **The grader.** Knows every number below and says PASS or FAIL. |

## Expected results

Measured on `hpretl/iic-osic-tools:2026.08` — Icarus Verilog 14.0, Yosys 0.68, Python 3.12.3.

```
PASS  generate      got PASS 0/512, reference says PASS 0/512
PASS  clean         `check` on src/ripple4.sv -- nothing undriven, 4 full adders
PASS  proof         Yosys proved generate == hand-typed, for every input
PASS  broken        got FAIL 512/512, reference says FAIL 512/512
PASS  undriven      `check` names the two undriven wires and counts 3 full adders
PASS  proof_broken  the same proof against broken/ripple4.sv -- fails on purpose
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
PASS  luts8         ripple #(.N(8))  -> 18 SB_LUT4
PASS  luts16        ripple #(.N(16)) -> 37 SB_LUT4
PASS  luts32        ripple #(.N(32)) -> 74 SB_LUT4
PASS  wide4         got PASS 0/512, reference says PASS 0/512
PASS  wide8         got PASS 0/131072, reference says PASS 0/131072
```

Three lines in that table are **supposed** to describe a failure. `broken`, `undriven` and
`proof_broken` all PASS when the broken design fails exactly as hard as it should.

## Two exit codes worth knowing before you see them

- `vvp` exits **0** whether your design is right or wrong. Read the verdict line, not `$?`.
- `iverilog` on `errors/ripple4_bit.sv` exits **134** and prints `Aborted (core dumped)`.
  That is a real crash in the compiler, triggered by a one-word typo. `make gotcha` shows it
  to you on purpose so it is not the first time you meet it.

> `src/ripple4.sv` is the file **Lab 05** turns into an FPGA bitstream, and the same file
> DD103 turns into silicon. Lab 05 ships its own copy, so editing this one is safe.
