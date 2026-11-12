# Lab 04: Four adders in a row

Writeup: [`docs/labs/lab-04-four-adders-in-a-row-overview.md`](../../docs/labs/lab-04-four-adders-in-a-row-overview.md)
([on the course site](https://uoftasic.com/dd102/#/labs/lab-04-four-adders-in-a-row-overview)).
Part 1 of the writeup uses [`../reference-card/`](../reference-card/).

Five experiments on one `generate for` loop. Run them in the order the writeup gives; several
ask you to commit to a number before you look.

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-04-four-adders-in-a-row
make
```

The first two lines only get you to the repo; no package needs `.designinit`, a PDK or a liberty
file. `make` takes under five seconds and ends with twelve verdicts, all `PASS`.

## Targets

| Command | What it does |
|---|---|
| `make` | all five experiments, then the verdict table |
| `make generate` | the loop against all 512 inputs, and what it built |
| `make proof` | Yosys proves the loop equals the hand-typed version |
| `make broken` | the one-character-broken loop: simulation, `check`, and the proof |
| `make gotcha` | `i++` in a generate loop, and a block labelled `bit` |
| `make wide` | the parameterised adder at four widths, and exhaustive at 4 and 8 bits |
| `make wide12` | optional: exhaustive at 12 bits, about four and a half minutes |
| `make check` | re-run the verdicts on logs you already have |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| `src/ripple4.sv` | The design: four full adders from one `generate for` loop. You rewrite its loop in Part 7 of the writeup. |
| `src/full_adder.sv` | The Lab 01 module. |
| `src/ripple.sv` | The same adder with its width as a `parameter`. Used by `make wide`. |
| `reference/ripple4_hand.sv` | The Lab 03 style: four instances typed out by hand. The proof compares against this. |
| `broken/ripple4.sv` | One character different. Don't fix it; `make broken` needs it. |
| `errors/ripple4_bit.sv` | The generate block labelled `bit`. Yosys rejects it and Icarus crashes. |
| `errors/ripple4_incr.sv` | The same loop with `i++`. It works. |
| `tb/tb_ripple4.sv` | All 512 inputs of a 4-bit adder. Prints one PASS/FAIL line. |
| `tb/tb_ripple.sv` | The same test at any width: `iverilog -Ptb_ripple.N=8 …` |
| `scripts/proof.ys` | Builds a miter and asks the SAT solver to prove the two adders equal. |
| `scripts/proof_broken.ys` | The same proof against the broken one. Fails, and names an input. |
| `scripts/check_good.ys`, `scripts/check_broken.ys` | Yosys's `check` pass, which finds undriven wires without simulating. |
| `src/check_lab04.py` | The grader. Knows every reference number. |

`src/ripple4.sv` is the file Lab 05 turns into an FPGA bitstream. Lab 05 ships its own copy, so
editing this one is safe.
