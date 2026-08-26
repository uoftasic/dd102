# Reference card — every example on the SystemVerilog survival card

Twelve files. Each one is **complete and runs on its own** — nothing in this folder
is a fragment, and nothing on
[the survival card](../../docs/reference/systemverilog-survival-card.md) is printed
without the whole file being here.

```bash
cd labs/reference-card
make
```

No `.designinit`, no `mod`, no PDK, no liberty file, no environment variables. It takes
about **0.3 seconds** and ends with `VERDICT PASS — all 12 cards match the reference run.`

## What's here

| File | The card it belongs to |
|---|---|
| `src/01_module_ports.sv` | `module` / `endmodule`, and an ANSI port list |
| `src/02_logic_and_vectors.sv` | `logic`, `logic [3:0]`, bit- and part-select |
| `src/03_assign_and_operators.sv` | `assign`, and `& \| ^ ~` |
| `src/04_concatenation.sv` | `{cout, sum}` |
| `src/05_always_comb.sv` | `always_comb`, `=`, `if`/`else` |
| `src/06_case_default.sv` | `case` with a `default:` |
| `src/07_instantiation.sv` | putting a module inside a module, `.port(signal)` |
| `src/08_generate_for.sv` | `genvar`, `generate for`, `begin : slice` |
| `src/09_parameter.sv` | `parameter int N = 4`, and `#(.N(6))` |
| `src/10_literals.sv` | `4'b1010`, `4'd10`, `4'hA`, `'0`, `'1`, bare `10` |
| `src/11_width_truncation.sv` | the trap: the **left** side decides the width |
| `src/12_testbench_only.sv` | `` `timescale ``, `initial`, `$display`, `$dumpfile`, `$dumpvars`, `$finish` |
| `src/check_card.py` | **the grader.** Compares your twelve lines against the reference run |
| `broken/card.log` | the answer most people predict for card 11. `make broken` feeds it in |
| `broken/narrow_only.sv` | card 11's mistake alone in a file, so `make lint` can fail to find it |
| `reference/card.expected` | the twelve lines, as printed on `hpretl/iic-osic-tools:2026.04` |

## Targets

| Command | What it does |
|---|---|
| `make` | run all twelve, then the verdict table |
| `make card N=11` | run exactly one card |
| `make broken` | read a **FAIL** you caused on purpose |
| `make lint` | show card 11's bug to Icarus and Verilator. Neither notices |
| `make synth` | card 08 through Yosys: how many LUTs a `generate for` costs |
| `make check` | re-run the verdict on a `card.log` you already have |
| `make clean` | empty `results/`, keep sources |

## Expected results

Measured on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0, Verilator 5.046,
Yosys 0.64, Python 3.12.3.

```
VERDICT PASS  — all 12 cards match the reference run.
```

`make synth` ends with `12 cells` — `4 $scopeinfo` and **`8 SB_LUT4`**. The four
`$scopeinfo` are bookkeeping, not hardware.

`make lint` ends with `iverilog exit 0` and `verilator exit 0`, both silent about a
real bug. That is the point of the target.
