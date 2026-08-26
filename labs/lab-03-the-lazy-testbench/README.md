# Lab 03 — The lazy testbench

Writeup: [`docs/labs/lab-03-the-lazy-testbench.md`](../../docs/labs/lab-03-the-lazy-testbench.md)

Four of your full adders in a row make a 4-bit adder. This lab is about the difference
between a 4-bit adder that passes your tests and a 4-bit adder that is right.

```bash
cd labs/lab-03-the-lazy-testbench
make
```

No environment setup. `make` alone, in a bare container, three stages, about two seconds.

## What's here

| File | What it is |
|---|---|
| [`tb/tb_lazy.sv`](tb/tb_lazy.sv) | **The file you write.** Three cases in, three yours. |
| [`src/add4.sv`](src/add4.sv) | Four `full_adder` instances chained carry-to-carry. Every gate in it is correct. |
| [`src/full_adder.sv`](src/full_adder.sv) | The one-bit adder from Lab 01, unchanged. |
| [`tb/tb_exhaustive.sv`](tb/tb_exhaustive.sv) | All 512 inputs of `add4`. Complete and shipped. |
| [`reference/add5.sv`](reference/add5.sv) | `add4` plus one port. The name is the lesson. |
| [`tb/tb_exhaustive_fixed.sv`](tb/tb_exhaustive_fixed.sv) | The same 512 inputs, aimed at `add5`. |
| [`reference/tb_lazy.sv`](reference/tb_lazy.sv) | Six cases a careful person would pick. All six pass. |
| [`broken/add4_wider_inside.sv`](broken/add4_wider_inside.sv) | The plausible fix that fixes nothing. Wrong on the same 256 inputs. |
| [`src/check_run.py`](src/check_run.py) | **The grader.** It knows the reference numbers below. |

## Targets

| | |
|---|---|
| `make` | all three stages in order — run this one |
| `make lazy` | stage 1, your hand-picked cases |
| `make exhaustive` | stage 2, all 512 |
| `make fixed` | stage 3, one more wire |
| `make trap` | the plausible fix that changes nothing, and the command that catches it |
| `make lint` | `verilator --lint-only -Wall` on all three designs |
| `make reference` | stage 1 with the shipped six cases |
| `make grade` | the same three stages with an exit status |
| `make clean` | empty `results/` |

## Reference numbers

Measured on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0, Python 3.12.3.

```
stage           design   testbench                 tested   wrong   verdict
----------------------------------------------------------------------------
lazy            add4     tb_lazy.sv (shipped)           3       0   PASS
lazy            add4     reference/tb_lazy.sv           6       0   PASS
exhaustive      add4     tb_exhaustive.sv             512     256   FAIL
trap            wider    tb_exhaustive.sv             512     256   FAIL
fixed           add5     tb_exhaustive_fixed.sv       512       0   PASS
```

`verilator --lint-only -Wall`, given `src/full_adder.sv` alongside and the right
`--top-module`, finds both bugs and clears the fix:

```
--top-module add4 src/add4.sv                      1 warning   exit 1   Signal is not used: 'c4'
--top-module add4 broken/add4_wider_inside.sv      3 warnings  exit 1   WIDTHTRUNC on assign sum = wide
--top-module add5 reference/add5.sv                0 warnings  exit 0
```

The 256 splits **120 with `cin=0`** and **136 with `cin=1`**, and 120 + 136 = 256. The
testbench prints that split itself, and `src/check_run.py` refuses to say `MATCH` unless
all four of those numbers are exactly right.

The first of the 256, in counting order:

```
  MISMATCH  0 + 15 + 1 : add4 said 0, the answer is 16
```

`tb_exhaustive.sv` prints only the first five mismatches and then `... and 251 more.` That
is deliberate — 256 `MISMATCH` lines would scroll the interesting part off your screen.

> **Reflex: N bits plus N bits does not fit in N bits.** Every adder you write needs
> somewhere for the top carry to go, and every testbench you write needs a case that puts
> something there.

## The point

`add4` and `add5` contain the same four full adders, wired the same way. Nothing was fixed
inside the design; a wire that already existed was allowed to leave the module. The variable
across those three rows is **the testbench**, not the adder.

Next: the DD102 guide continues past this lab into the FPGA flow.
