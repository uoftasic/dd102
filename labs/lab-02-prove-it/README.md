# Lab 02 — Prove it

Writeup: [`docs/labs/lab-02-prove-it.md`](../../docs/labs/lab-02-prove-it.md)

You write the testbench this time. Then this package finds out whether it is any good, by
handing it three adders that are broken on purpose.

```bash
cd labs/lab-02-prove-it
make
```

No environment setup of any kind. `make` alone, in a bare container. It always exits 0 —
the verdict is the text.

## What's here

| File | What it is |
|---|---|
| [`tb/tb_full_adder.sv`](tb/tb_full_adder.sv) | **The file you write.** It works as shipped and it checks one row out of eight. Seven `check(...)` lines are missing. |
| [`src/full_adder.sv`](src/full_adder.sv) | A full adder that works. Replace it with your own from Lab 01 if you like — it passes the same way. |
| [`mutants/mut1_cin_ignored.sv`](mutants/mut1_cin_ignored.sv) | `sum` forgot `cin`. |
| [`mutants/mut2_carry_needs_all_three.sv`](mutants/mut2_carry_needs_all_three.sv) | `cout` fires only when all three inputs are 1. |
| [`mutants/mut3_outputs_swapped.sv`](mutants/mut3_outputs_swapped.sv) | Both expressions right, wired to the wrong ports. |
| [`reference/tb_full_adder.sv`](reference/tb_full_adder.sv) | One complete answer. `make reference` runs it through the identical sweep. |
| [`src/check_verdict.py`](src/check_verdict.py) | **The grader.** It reads *your testbench's own verdict* and decides whether that was the right verdict. |

Every mutant is a complete file declaring `module full_adder`, so your testbench binds to it
without changing a character.

## Targets

| | |
|---|---|
| `make` | your testbench vs. one good adder and three broken ones |
| `make good` | only the working adder |
| `make mutants` | only the three broken ones |
| `make reference` | the identical sweep using `reference/tb_full_adder.sv` |
| `make grade` | the same run with an exit status a script can read |
| `make clean` | empty `results/` |

## What `make` prints before you have added anything

```
 against the working adder             : THIN (1 of 8 rows checked)
 mutants/mut1_cin_ignored.sv           : SLIPPED
 mutants/mut2_carry_needs_all_three.sv : SLIPPED
 mutants/mut3_outputs_swapped.sv       : SLIPPED
--------------------------------------------------------------
 mutants caught: 0 of 3
```

**Zero of three.** The shipped testbench says `VERDICT PASS` on all four adders, including
the three that are wrong. It is not lying — row `a=0 b=0 cin=0` really does come out `cout=0
sum=0` on every one of them.

## What `make` prints when you are done

```
 against the working adder             : GOOD (8 of 8 rows checked)
 mutants/mut1_cin_ignored.sv           : CAUGHT
 mutants/mut2_carry_needs_all_three.sv : CAUGHT
 mutants/mut3_outputs_swapped.sv       : CAUGHT
--------------------------------------------------------------
 mutants caught: 3 of 3
```

## Reference numbers

Measured on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0, Python 3.12.3. With all
eight rows in, each mutant fails on a different number of them:

```
file                                      rows checked   mismatches   verdict
--------------------------------------------------------------------------------
src/full_adder.sv                                    8            0   PASS
mutants/mut1_cin_ignored.sv                          8            4   FAIL
mutants/mut2_carry_needs_all_three.sv                8            3   FAIL
mutants/mut3_outputs_swapped.sv                      8            6   FAIL
```

4 + 3 + 6 = **13 of the 24 mutant rows are wrong**, and the one-row testbench sees none of
them. `make reference` reproduces every number above.

> **Reflex: a testbench that has never failed has proven nothing.** Before you trust one,
> break the design on purpose and check that it notices.

Next: [Lab 03 — The lazy testbench](../lab-03-the-lazy-testbench/).
