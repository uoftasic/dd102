# Lab 01: Transcribe your adder

Writeup: [`docs/labs/lab-01-transcribe-your-adder-overview.md`](../../docs/labs/lab-01-transcribe-your-adder-overview.md)
([on the course site](https://uoftasic.com/dd102/#/labs/lab-01-transcribe-your-adder-overview)).

Your DD101 drawing, typed out and graded on the eight rows of the truth table. The package runs a
known-good adder through the same machinery as yours, so a failure tells you which of the two is
broken.

```bash
cd labs/lab-01-transcribe-your-adder
make
```

No `.designinit`, `mod`, PDK or environment variables. `make` always exits 0; the verdict is the
text. When you're done it prints:

```
 reference/full_adder.sv : PASS  8/8
 src/full_adder.sv       : PASS  8/8   <-- Lab 01 is done.
```

## Targets

| Command | What it does |
|---|---|
| `make` | the reference, then yours, then one verdict |
| `make reference` | only `reference/full_adder.sv`, to show your toolchain works |
| `make yours` | only `src/full_adder.sv` |
| `make lint` | `verilator --lint-only` on your file, without and then with `-Wall` |
| `make grade` | the same check with an exit status a script can read |
| `make clean` | empty `results/` |

## Files

| File | What it is |
|---|---|
| [`src/full_adder.sv`](src/full_adder.sv) | The file you write. Ports done, middle empty. |
| [`reference/full_adder.sv`](reference/full_adder.sv) | One complete answer. `make` runs it every time. |
| [`tb/print_table.sv`](tb/print_table.sv) | A table printer: drives the eight input combinations and prints what came back. It doesn't know the right answers. |
| [`src/check_table.py`](src/check_table.py) | The grader. Standard-library Python; it knows the eight rows and does the arithmetic on any you got wrong. |

Every `.sv` file in this package is complete and compiles on its own.
