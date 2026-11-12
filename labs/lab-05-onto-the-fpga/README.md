# Lab 05: Onto the FPGA

Writeup: [`docs/labs/lab-05-onto-the-fpga-overview.md`](../../docs/labs/lab-05-onto-the-fpga-overview.md)
([on the course site](https://uoftasic.com/dd102/#/labs/lab-05-onto-the-fpga-overview)).
The writeup also uses [`../guide-examples/`](../guide-examples/) and
[`../guide-examples-carry/`](../guide-examples-carry/).

`src/ripple4.sv` from Lab 04 becomes a bitstream for a Lattice iCE40 UP5K, and then the same two
files are mapped to SKY130 standard cells, which is where DD103 starts.

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-05-onto-the-fpga
make
```

Under half a minute, ending in twelve verdicts, all `PASS`. No board is needed or assumed.

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
| `src/ripple4.sv`, `src/full_adder.sv` | Your Lab 04 adder, copied so you can edit the original freely. |
| `src/one_gate.sv` | One AND gate. Used by `make sizes`. |
| `src/big.sv` | A 4000-stage shift register. Also `make sizes`. |
| `src/toobig.sv` | A 16×16 multiplier. Fits in logic, not in pins. `make fits`. |
| `constraints/r4.pcf` | Fourteen `set_io` lines: which signal comes out of which physical pin. |
| `scripts/asic.ys` | The same two source files, mapped to SKY130 standard cells. |
| `src/check_lab05.py` | The grader. Knows every reference number, including the byte count. `--lcs` lists the placed logic cells. |

`results/` ships empty. The lab writes about 3 MB of netlists, ASCII bitstreams and binaries, and
`make icetime` unpacks a 27 MB chip database into it. Everything regenerates in under half a
minute.
