# Expected results

The reference numbers behind each lab's checks, and what the less obvious failures mean. Every
number here comes from `hpretl/iic-osic-tools:2026.08`. Each lab writeup says when you're done;
use this page to check a number or decode a `FAIL`.

## Lab 01: Transcribe your adder

Icarus Verilog 14.0, Python 3.12.3:

| What | Result |
|---|---|
| `reference/full_adder.sv`, all 8 rows | PASS |
| `src/full_adder.sv` as shipped | FAIL, 8 of 8 rows disagree, every output `x` |
| `src/full_adder.sv` once you write it | PASS, 8 of 8 |
| `verilator --lint-only` on the stub | 0 warnings, exit 0 |
| `verilator --lint-only -Wall` on the stub | 5 warnings, exit 1 |

## Lab 02: Prove it

Icarus Verilog 14.0, Python 3.12.3. `make reference` reproduces the "all eight rows" half with
`reference/tb_full_adder.sv`.

```
testbench            design                                  tested  errors  verdict
------------------------------------------------------------------------------------
yours, as shipped    src/full_adder.sv                            1       0  PASS  (THIN)
yours, as shipped    mutants/mut1_cin_ignored.sv                  1       0  PASS  (SLIPPED)
yours, as shipped    mutants/mut2_carry_needs_all_three.sv        1       0  PASS  (SLIPPED)
yours, as shipped    mutants/mut3_outputs_swapped.sv              1       0  PASS  (SLIPPED)
all eight rows       src/full_adder.sv                            8       0  PASS  (GOOD)
all eight rows       mutants/mut1_cin_ignored.sv                  8       4  FAIL  (CAUGHT)
all eight rows       mutants/mut2_carry_needs_all_three.sv        8       3  FAIL  (CAUGHT)
all eight rows       mutants/mut3_outputs_swapped.sv              8       6  FAIL  (CAUGHT)
```

## Lab 03: The lazy testbench

`make` in `labs/guide-examples-proving-it/` runs five checks; `eight` and `eight_broken` are the
two runs from Lab 02, and lines 3 and 4 are the same broken adder passing six cases and failing
256:

```
PASS  eight         got PASS 0/8, reference says PASS 0/8
PASS  eight_broken  got FAIL 4/8, reference says FAIL 4/8
PASS  six           got PASS 0/6, reference says PASS 0/6
PASS  sweep         got FAIL 256/512, reference says FAIL 256/512
PASS  fixed         got PASS 0/512, reference says PASS 0/512
```

In `labs/lab-03-the-lazy-testbench/`, Icarus Verilog 14.0 and Python 3.12.3. `src/check_run.py`
won't say `MATCH` unless yours agree exactly:

```
stage      design                        testbench                tested  wrong  verdict
-----------------------------------------------------------------------------------------
lazy       src/add4.sv                   tb_lazy.sv (as shipped)       3      0  PASS
lazy       src/add4.sv                   reference/tb_lazy.sv          6      0  PASS
lazy       src/add4.sv                   reference six + 15+1+0        7      1  FAIL (FOUND)
exhaustive src/add4.sv                   tb_exhaustive.sv            512    256  FAIL
trap       broken/add4_wider_inside.sv   tb_exhaustive.sv            512    256  FAIL
fixed      reference/add5.sv             tb_exhaustive_fixed.sv      512      0  PASS
```

```
command                                                                  warnings  exit
----------------------------------------------------------------------------------------
verilator --lint-only -Wall --top-module add4 src/add4.sv                       1     1
verilator --lint-only -Wall --top-module add4 broken/add4_wider_inside.sv       3     1
verilator --lint-only -Wall --top-module add5 reference/add5.sv                 0     0
```

Each lint command is also given `src/full_adder.sv`. Your own `tb_lazy.sv` reports however many
cases you wrote: 6 after Part 4, and `FOUND` once a case whose sum doesn't fit in four bits is in.

## Lab 04: Four adders in a row

Icarus Verilog 14.0, Yosys 0.68, Python 3.12.3:

| What | Number |
|---|---|
| inputs a 4-bit adder can have | 512 |
| `full_adder` instances the loop builds | 4 (broken: 3) |
| SAT problem for the proof | 294 variables, 751 clauses |
| broken design, exhaustive | FAIL 512/512 |
| counterexample the solver returns | `a = 14`, `b = 8`, `cin = 1` |
| counterexample with `assign c[0] = 1'b0;` planted (Part 7) | `a = 8`, `b = 15`, `cin = 1` |
| `iverilog` exit status on `errors/ripple4_bit.sv` | 134, `Aborted (core dumped)` |
| `SB_LUT4` at N = 4 / 8 / 16 / 32 | 9 / 18 / 37 / 74 |
| exhaustive at 8 bits | 131,072 cases, 0.78 s |

| What you see | What it means |
|---|---|
| `make: yosys: No such file or directory` | You're not inside the workbench container. Every command here runs in the noVNC terminal, not on your laptop. |
| `FAIL` on any line of `make check` | Something drifted. Paste the whole FAIL line into [Discord](https://discord.gg/hrJnP5UsGz); it contains both your number and the reference. |
| `Aborted (core dumped)` from `iverilog` | Expected only for `errors/ripple4_bit.sv`. Anywhere else, read the first error line above it. |
| `vvp` says nothing and exits 0 | The testbench didn't reach its verdict. Read the log from the top; the first error is the real one. |
