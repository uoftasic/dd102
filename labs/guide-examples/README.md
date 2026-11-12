# Guide examples

Every file printed in the guide pages From your drawing to a module, Modules and instances,
`assign` and `always_comb`, Seeing your adder as a schematic and Inside an FPGA, complete. If one
of those pages shows you SystemVerilog, the whole file is here. This isn't a lab; you write your
own adder in [`../lab-01-transcribe-your-adder/`](../lab-01-transcribe-your-adder/).
[Lab 01](../../docs/labs/lab-01-transcribe-your-adder-overview.md) (Parts 6 and 7) and
[Lab 05](../../docs/labs/lab-05-onto-the-fpga-overview.md) (Part 1) walk through the targets.

```bash
cd labs/guide-examples
make
```

No `.designinit`, `mod` or environment variables. The sky130 liberty file is read from its fixed
path in the image. It takes about 2.6 seconds and ends with
`PASS - every number matches the reference run, to four decimals.`

## Targets

| Command | What it does |
|---|---|
| `make` | `sim`, `broken`, `spellings`, `backwards`, `area`, `luts`, `table`, in that order |
| `make sim` | the adder against the eight rows |
| `make broken` | the same testbench against the wrong adder |
| `make spellings` | four modules, one truth table |
| `make backwards` | the five lines in reverse order |
| `make area` | what each spelling costs in sky130 cells |
| `make luts` | three 4-input functions and one 5-input AND on an iCE40 |
| `make picture` | `results/full_adder_rtl.svg`, the schematic Yosys draws |
| `make errors` | the six misbehaving files, and what each tool prints |
| `make syntax` | six files that don't compile, with the exact Icarus messages and exit codes |
| `make table` | reprint the area verdict from JSON you already have |
| `make clean` | empty `results/` |

`make errors` and `make syntax` print lines like `make: [Makefile:92: errors] Error 2 (ignored)`.
That is `make` saying a command failed and that it was told in advance not to care; those files
are supposed to fail.

## Files

| File | What it is |
|---|---|
| `src/full_adder.sv` | The DD101 drawing, one wire at a time. Five `assign`s. |
| `src/full_adder_flat.sv` | The same adder as one expression per output. Two `assign`s. |
| `src/full_adder_table.sv` | The same adder as `always_comb` + `case`: the eight rows, one line each. |
| `src/half_adder.sv` | The DD101 Lab 03 subcircuit, as a module. |
| `src/full_adder_hier.sv` | Two `half_adder` instances and an Or. |
| `src/full_adder_backwards.sv` | `full_adder.sv` with the five lines in reverse order. |
| `src/tb_full_adder.sv` | The eight rows of the DD101 truth table, as a test. Prints `PASS` or `FAIL`. |
| `src/tb_spellings.sv` | Four spellings driven side by side from the same eight rows. |
| `src/tb_backwards.sv` | The eight rows aimed at `full_adder_backwards`. |
| `src/lut_simple.sv`, `src/lut_parity.sv`, `src/lut_weird.sv`, `src/lut_five.sv` | The lookup-table examples from Inside an FPGA. |
| `src/check_area.py` | Grader for the area numbers. Reads `stat -json`. |
| `src/check_luts.py` | Grader for the LUT counts. |
| `scripts/area.ys` | Six synthesis runs against the sky130 cell library. |
| `scripts/digitaljs.ys` | The Yosys script DigitalJS Online runs in your browser. |
| `broken/full_adder.sv` | `src/full_adder.sv` with one `&` where the drawing has an Or. |
| `errors/call_it_like_a_function.sv` | Calls a module like a function. Doesn't compile. |
| `errors/two_drivers.sv` | Two `assign`s at one output. Doesn't compile. |
| `errors/if_inside_assign.sv` | An `if` inside an `assign`. One mistake, five error messages. |
| `errors/both_ways_at_once.sv` | One signal driven by an `always_comb` and an `assign`. Icarus errors; Yosys only warns. |
| `errors/undeclared_wire.sv` | An internal wire nobody declared. Icarus is silent; Yosys warns three times. |
| `errors/forgot_a_branch.sv` | An `always_comb` that skips a branch. Simulates; Yosys refuses it. |
| `syntax/01_missing_semicolon.sv` … `syntax/06_needs_g2012.sv` | The files behind [Icarus error messages](../../docs/reference/when-icarus-says-syntax-error.md). |
