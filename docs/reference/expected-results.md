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
