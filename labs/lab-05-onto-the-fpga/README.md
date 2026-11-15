# Lab 05: Onto the FPGA

Writeup: [`docs/labs/lab-05-onto-the-fpga-overview.md`](../../docs/labs/lab-05-onto-the-fpga-overview.md)
([on the course site](https://uoftasic.com/dd102/labs/lab-05-onto-the-fpga-overview.html)).
The writeup also uses [`../guide-examples/`](../guide-examples/) and
[`../guide-examples-carry/`](../guide-examples-carry/).

Your Lab 04 adder, `src/ripple4.sv` and `src/full_adder.sv`, becomes a bitstream for a Lattice
iCE40 UP5K. Then the same two files are mapped to SKY130 standard cells, which is where DD103
starts.

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-05-onto-the-fpga
make
```

`make` takes under half a minute and ends with twelve verdicts, which should all be `PASS`. You
don't need an FPGA board, and no required step assumes you have one.

## Targets

| Command | What it does |
|---|---|
| `make` | `fpga`, `sizes`, `fits`, `pins`, `contrast`, then the verdict table |
| `make fpga` | your adder → netlist → placement → bitstream |
| `make sizes` | two more designs, and their bitstream sizes |
| `make fits` | a design that doesn't fit, and how the tool says so |
| `make pins` | the same adder with `constraints/r4.pcf` |
| `make contrast` | the same two files sent to SKY130 instead |
| `make icetime` | optional: the IceStorm timing tool, in three steps |
| `make flash` | optional: `iceprog`, which needs an iCE40 board. Unchecked |
| `make check` | re-run the verdicts on artefacts you already have |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| `src/ripple4.sv`, `src/full_adder.sv` | Your Lab 04 adder, copied so you can edit the original freely. Part 8 of the writeup copies your own rewritten `ripple4.sv` over it. |
| `src/one_gate.sv` | One AND gate. Used by `make sizes`. |
| `src/big.sv` | A 4000-stage shift register. Also used by `make sizes`. |
| `src/toobig.sv` | A 16×16 multiplier, which fits in the logic but not in the pins. Used by `make fits`. |
| `constraints/r4.pcf` | Fourteen `set_io` lines: which signal comes out of which physical pin. |
| `scripts/asic.ys` | The same two source files, mapped to SKY130 standard cells. |
| `src/check_lab05.py` | The grader. It holds every reference number, including the bitstream's size in bytes. `--lcs` lists the placed logic cells. |

`results/` ships empty. The lab writes about 3 MB of netlists, ASCII bitstreams and binaries, and
`make icetime` unpacks a 27 MB chip database into it. Everything regenerates in under half a
minute.
