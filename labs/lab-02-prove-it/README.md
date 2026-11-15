# Lab 02: Prove it

Writeup: [`docs/labs/lab-02-prove-it-overview.md`](../../docs/labs/lab-02-prove-it-overview.md)
([on the course site](https://uoftasic.com/dd102/labs/lab-02-prove-it-overview.html)).

You write the testbench, and the package checks it by running it against one working full adder
and three that are broken on purpose.

```bash
cd labs/lab-02-prove-it
make
```

There's no PDK or environment to set up first. `make` always exits 0, so read the verdict in its
output (`make grade` is the target with an exit status). When you're done it prints:

```
 mutants caught: 3 of 3

 All 8 rows checked, all 3 mutants caught. Lab 02 is done.
```

## Targets

| Command | What it does |
|---|---|
| `make` | your testbench against one good adder and three broken ones |
| `make good` | only the working adder |
| `make mutants` | only the three broken ones |
| `make reference` | the same sweep using `reference/tb_full_adder.sv` |
| `make grade` | the same run with an exit status a script can read |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| [`tb/tb_full_adder.sv`](tb/tb_full_adder.sv) | The file you write. It works as shipped and checks one row of eight; seven `check(...)` lines are missing. |
| [`src/full_adder.sv`](src/full_adder.sv) | A working full adder. Replace it with your own from Lab 01 if you like. |
| [`mutants/mut1_cin_ignored.sv`](mutants/mut1_cin_ignored.sv) | `sum` forgot `cin`. |
| [`mutants/mut2_carry_needs_all_three.sv`](mutants/mut2_carry_needs_all_three.sv) | `cout` fires only when all three inputs are 1. |
| [`mutants/mut3_outputs_swapped.sv`](mutants/mut3_outputs_swapped.sv) | Both expressions right, wired to the wrong ports. |
| [`reference/tb_full_adder.sv`](reference/tb_full_adder.sv) | One complete answer. |
| [`src/check_verdict.py`](src/check_verdict.py) | The grader. It reads your testbench's own verdict and decides whether it was the right verdict. |

Every mutant is a complete file declaring `module full_adder`, so your testbench binds to it
without changes.
