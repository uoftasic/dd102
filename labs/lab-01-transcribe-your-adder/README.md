# Lab 01: Transcribe your adder

Writeup: [`docs/labs/lab-01-transcribe-your-adder-overview.md`](../../docs/labs/lab-01-transcribe-your-adder-overview.md)
([on the course site](https://uoftasic.com/dd102/labs/lab-01-transcribe-your-adder-overview.html)).

In this lab you type your DD101 full-adder drawing into `src/full_adder.sv`, and the package grades
it on the eight rows of the truth table. It runs a known-good adder through the same printer and
grader as yours, so when something fails you can tell whether the problem is in your file or in
your setup.

```bash
cd labs/lab-01-transcribe-your-adder
make
```

There is no `.designinit`, `mod`, PDK or environment variable to set up. `make` always exits 0,
so read the verdict in its output rather than the exit status. When your adder is right, it prints:

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
| [`src/full_adder.sv`](src/full_adder.sv) | The file you write. The ports are declared for you and the body is left empty. |
| [`reference/full_adder.sv`](reference/full_adder.sv) | One complete answer. `make` runs it every time. |
| [`tb/print_table.sv`](tb/print_table.sv) | A table printer: drives the eight input combinations and prints what came back. It doesn't know the right answers. |
| [`src/check_table.py`](src/check_table.py) | The grader. Standard-library Python; it knows the eight rows and does the arithmetic on any you got wrong. |

Every `.sv` file in this package is complete and compiles on its own.
