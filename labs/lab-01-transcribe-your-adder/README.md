# Lab 01 — Transcribe your adder

Writeup: [`docs/labs/lab-01-transcribe-your-adder-overview.md`](../../docs/labs/lab-01-transcribe-your-adder-overview.md)

Your DD101 drawing, typed out. **This package exists so that you can be wrong safely** — it
runs a known-good adder through exactly the same machinery as yours, so a failure tells you
which of the two is broken.

```bash
cd labs/lab-01-transcribe-your-adder
make
```

No `.designinit`, no `mod`, no PDK, no liberty file, no environment variables. `make` alone,
in a bare container, is the whole story. It always exits 0 — **the verdict is the text, not
the exit status.**

## What's here

| File | What it is |
|---|---|
| [`src/full_adder.sv`](src/full_adder.sv) | **The file you write.** Ports done, middle empty. |
| [`reference/full_adder.sv`](reference/full_adder.sv) | One complete answer. `make` runs it too, every time. |
| [`tb/print_table.sv`](tb/print_table.sv) | A table **printer**. Complete and shipped; it drives the eight input combinations and prints what came back. It does not know the right answers. |
| [`src/check_table.py`](src/check_table.py) | **The grader.** Standard-library Python; it knows the eight rows and does the arithmetic on the ones you got wrong. |

Every `.sv` file in this package is a complete, compilable file. Nothing here is an excerpt.

## Targets

| | |
|---|---|
| `make` | the reference, then yours, then one verdict |
| `make reference` | only `reference/full_adder.sv` — proves your toolchain works |
| `make yours` | only `src/full_adder.sv` |
| `make lint` | the Verilator dead end (see below) |
| `make grade` | the same check with an exit status a script can read |
| `make clean` | empty `results/` |

## What `make` prints before you have written anything

```
 reference/full_adder.sv : PASS  8/8   (so your toolchain is fine)
 src/full_adder.sv       : FAIL        <-- this one is yours to write.
```

and above it, eight rows of `x`:

```
a b cin | cout sum
0 0  0  |  x    x
0 0  1  |  x    x
```

**`x` is not a wrong answer. It means nobody drove this wire.** Your module declares `sum`
and `cout` and never assigns them, so they have no value at all.

You will also see, once per run:

```
tb/print_table.sv:30: $finish called at 8000 (1ps)
```

That is Icarus saying the testbench reached its end after 8 nanoseconds of pretend time, one
per row. It is the normal last line of every successful simulation in this course.

## What `make` prints when you are done

```
 reference/full_adder.sv : PASS  8/8
 src/full_adder.sv       : PASS  8/8   <-- Lab 01 is done.
```

## The dead end: `verilator --lint-only`

`verilator` is on your `PATH`, it is a serious industrial tool, and "lint your file before
you simulate it" is genuinely good advice. Run it on the empty stub — a module that drives
nothing at all:

```
$ verilator --lint-only src/full_adder.sv
- V e r i l a t i o n   R e p o r t: Verilator 5.050 2026-07-01 rev v5.050
- Verilator: Built from 0.031 MB sources in 2 modules, into 0.002 MB in 3 C++ files needing 0.000 MB
exit status 0
```

**Exit 0. No complaint.** Add one flag:

```
$ verilator --lint-only -Wall src/full_adder.sv
%Warning-UNDRIVEN: src/full_adder.sv:15:18: Signal is not driven: 'sum'
%Warning-UNDRIVEN: src/full_adder.sv:16:18: Signal is not driven: 'cout'
%Error: Exiting due to 5 warning(s)
exit status 1
```

`make lint` runs both, back to back, so you can watch the same file pass and fail.

> **Reflex: Verilator's default lint is nearly silent. If you reach for it, reach for
> `-Wall`.** And in this course, lint is never the verdict — `make` is.

## Reference numbers

Measured on `hpretl/iic-osic-tools:2026.08` — Icarus Verilog 14.0, Python 3.12.3.

```
reference/full_adder.sv          8 of 8 rows match          PASS
src/full_adder.sv as shipped     8 of 8 rows disagree       FAIL   (all x)
verilator --lint-only  (stub)    0 warnings, exit 0
verilator --lint-only -Wall      5 warnings, exit 1
```

Next: [Lab 02 — Prove it](../lab-02-prove-it/).
