# Lab 03: The lazy testbench

Writeup: [`docs/labs/lab-03-the-lazy-testbench-overview.md`](../../docs/labs/lab-03-the-lazy-testbench-overview.md)
([on the course site](https://uoftasic.com/dd102/labs/lab-03-the-lazy-testbench-overview.html)).
The writeup also uses the examples in [`../guide-examples-proving-it/`](../guide-examples-proving-it/).

The package is a 4-bit adder built from four full adders. You test it first with a few cases you
pick by hand, and then with all 512 possible inputs.

```bash
cd labs/lab-03-the-lazy-testbench
make
```

There's no PDK or environment to set up first. `make` runs the three stages in about two seconds
and always exits 0, so read the verdict in its output, which ends with a table of the three
stages (`make grade` is the target with an exit status).

## Targets

| Command | What it does |
|---|---|
| `make` | all three stages in order |
| `make lazy` | stage 1: your hand-picked cases |
| `make exhaustive` | stage 2: all 512 inputs |
| `make fixed` | stage 3: the same 512 against `reference/add5.sv` |
| `make trap` | the plausible fix that changes nothing, and the command that catches it |
| `make lint` | `verilator --lint-only -Wall` on all three designs |
| `make reference` | stage 1 with the six shipped cases |
| `make grade` | the same three stages with an exit status |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| [`tb/tb_lazy.sv`](tb/tb_lazy.sv) | The file you write. Three cases in; you add three, then one that catches the bug. |
| [`src/add4.sv`](src/add4.sv) | Four `full_adder` instances chained carry to carry. |
| [`src/full_adder.sv`](src/full_adder.sv) | The one-bit adder from Lab 01. |
| [`tb/tb_exhaustive.sv`](tb/tb_exhaustive.sv) | All 512 inputs of `add4`. |
| [`reference/add5.sv`](reference/add5.sv) | `add4` plus one port. |
| [`tb/tb_exhaustive_fixed.sv`](tb/tb_exhaustive_fixed.sv) | The same 512 inputs, aimed at `add5`. |
| [`reference/tb_lazy.sv`](reference/tb_lazy.sv) | Six hand-picked cases. |
| [`broken/add4_wider_inside.sv`](broken/add4_wider_inside.sv) | A plausible fix that fixes nothing. |
| [`src/check_run.py`](src/check_run.py) | The grader. It knows the reference numbers in the writeup. |
