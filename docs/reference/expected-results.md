# Expected results

This page collects the reference numbers that each lab's checks compare against, and explains
what the less obvious failures mean. Every number here comes from a run in the
`hpretl/iic-osic-tools:2026.08` image. Each lab writeup tells you when you're done; come here when
you want to check a number or work out what a `FAIL` is telling you.

## Lab 01: Transcribe your adder

These results come from Icarus Verilog 14.0 and Python 3.12.3:

| What | Result |
|---|---|
| `reference/full_adder.sv`, all 8 rows | PASS |
| `src/full_adder.sv` as shipped | FAIL: all 8 rows disagree, and every output is `x` |
| `src/full_adder.sv` once you write it | PASS on all 8 rows |
| `verilator --lint-only` on the stub | 0 warnings, exit 0 |
| `verilator --lint-only -Wall` on the stub | 5 warnings, exit 1 |

## Lab 02: Prove it

These results come from Icarus Verilog 14.0 and Python 3.12.3. `make reference` reproduces the
"all eight rows" half of the table, using `reference/tb_full_adder.sv` as the testbench.

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

`make` in `labs/guide-examples-proving-it/` runs five checks. `eight` and `eight_broken`
are the two runs from Lab 02. Lines 3 and 4 (`six` and `sweep`) both test one broken adder, which
passes six cases and fails 256 of the 512 in the full sweep:

```
PASS  eight         got PASS 0/8, reference says PASS 0/8
PASS  eight_broken  got FAIL 4/8, reference says FAIL 4/8
PASS  six           got PASS 0/6, reference says PASS 0/6
PASS  sweep         got FAIL 256/512, reference says FAIL 256/512
PASS  fixed         got PASS 0/512, reference says PASS 0/512
```

The lab's own results, from `labs/lab-03-the-lazy-testbench/` with Icarus Verilog 14.0 and
Python 3.12.3, are below. `src/check_run.py` prints `MATCH` only when your numbers agree with
these exactly:

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

Each lint command is also given `src/full_adder.sv`, which the table leaves out. Your own
`tb_lazy.sv` reports however many cases you wrote, which is 6 after Part 4, and its line says
`FOUND` once you've added a case whose sum doesn't fit in four bits.

## Lab 04: Four adders in a row

These numbers come from Icarus Verilog 14.0, Yosys 0.68 and Python 3.12.3:

| What | Number |
|---|---|
| inputs a 4-bit adder can have | 512 |
| `full_adder` instances the loop builds | 4 (3 in the broken design) |
| SAT problem for the proof | 294 variables, 751 clauses |
| broken design, exhaustive | FAIL 512/512 |
| counterexample the solver returns | `a = 14`, `b = 8`, `cin = 1` |
| counterexample with `assign c[0] = 1'b0;` planted (Part 7) | `a = 8`, `b = 15`, `cin = 1` |
| `iverilog` exit status on `errors/ripple4_bit.sv` | 134, `Aborted (core dumped)` |
| `SB_LUT4` at N = 4 / 8 / 16 / 32 | 9 / 18 / 37 / 74 |
| exhaustive at 8 bits | 131,072 cases, 0.78 s |

| What you see | What it means |
|---|---|
| `make: yosys: No such file or directory` | You're not inside the workbench container. Every command in these labs runs in the noVNC terminal, not on your laptop. |
| `FAIL` on any line of `make check` | One of your numbers has drifted from the reference. Paste the whole FAIL line into [Discord](https://discord.gg/hrJnP5UsGz), since it contains both your number and the reference one. |
| `Aborted (core dumped)` from `iverilog` | This is expected for `errors/ripple4_bit.sv` and nowhere else. On any other file, read the first error line above it. |
| `vvp` says nothing and exits 0 | The testbench never got as far as its verdict. Read the log from the top, because the first error is the real one. |

## Lab 05: Onto the FPGA

These numbers come from Yosys 0.68, nextpnr-0.11.1-9-gb17408e2, IceStorm and Python 3.12.3:

| What | Number |
|---|---|
| `synth_ice40` on `ripple4` | 9 × `SB_LUT4` (+ 4 `$scopeinfo`) |
| nextpnr logic cells | 11 / 5280: 9 from your design, plus `$PACKER_GND` and `$PACKER_VCC` |
| nextpnr I/O | 14 / 39 |
| longest path | 26.22 ns = 2.98 ns logic + 23.24 ns routing |
| with `constraints/r4.pcf` | 14.11 ns = 2.95 ns logic + 11.16 ns routing, and nextpnr prints `Placed 14 cells based on constraints` |
| bitstream | 104,090 bytes |
| your Lab 04 rewrite (`i++`, label `stage`) | the same 104,090 bytes, and `cmp` against the shipped copy's bitstream reports no difference |
| `one_gate` / `big` bitstreams | 104,090 bytes each, even though one uses 3 logic cells and the other 4001 |
| bytes that differ, `one_gate` vs `r4` | 201 |
| `toobig` | needs 685/5280 logic cells and 64/39 pins, and fails with `ERROR: Unable to find a placement location` |
| the same file on SKY130 | 4 `maj3_1` + 8 `xnor2_1`, 110.1056 µm² |
| `icetime` step 2 | exit 139, `Segmentation fault (core dumped)` |

| What you see | What it means |
|---|---|
| `nextpnr-ice40: command not found` | You're not inside the workbench container. |
| `Warning: No PCF file specified` | This is expected in Parts 2 to 5, and it's the only warning the good runs produce. |
| `No Fmax available` | This is expected, because your adder has no clock. `src/big.sv` in Part 4 does have one, and it reports 202.92 MHz. |
| `ERROR: Unable to find a placement location` | This is expected in Part 5 only. Read the utilisation table printed above it. |
| `Segmentation fault (core dumped)` | This is expected from step 2 of `make icetime` and nowhere else. |
| `FAIL` on any line of `make check` | Paste the whole line into [Discord](https://discord.gg/hrJnP5UsGz), since it has your number and the reference side by side. |

Step 3 of `make icetime`, which uses the uncompressed chip database, prints the last twelve lines
of `icetime`'s report:

```
        pre_io_13_31_0 (PRE_IO) DOUT0 [setup]: 0.187 ns
    27.424 ns io_pad_13_31_0_din

Resolvable net names on path:
     1.105 ns ..  8.946 ns cin$SB_IO_IN
    10.231 ns .. 16.654 ns cin_SB_LUT4_I1_O[3]
    17.860 ns .. 20.813 ns cout_SB_LUT4_O_I3[3]
    22.098 ns .. 27.237 ns cout$SB_IO_OUT

Total number of logic levels: 4
Total path delay: 27.42 ns (36.46 MHz)
```
