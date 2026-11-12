# Reference card

Twelve files, one for each construct on [The DD102 subset](../../docs/reference/the-dd102-subset.md).
Each is complete and runs on its own, and nothing on that page is printed without the whole file
being here. [Lab 04](../../docs/labs/lab-04-four-adders-in-a-row-overview.md) (Part 1, and
`make synth` under Going further) walks through it.

```bash
cd labs/reference-card
make
```

No `.designinit`, `mod`, PDK, liberty file or environment variables. It takes about 0.3 seconds
and ends with `VERDICT PASS  — all 12 cards match the reference run.`

## Targets

| Command | What it does |
|---|---|
| `make` | run all twelve, then the verdict |
| `make card N=11` | run exactly one card |
| `make broken` | feed the checker a wrong card 11 and read the FAIL |
| `make lint` | show card 11's bug to Icarus and Verilator; neither notices |
| `make synth` | card 08 through Yosys for the iCE40 |
| `make check` | re-run the verdict on a `card.log` you already have |
| `make clean` | empty `results/`, keep sources |

## Files

| File | The card it belongs to |
|---|---|
| `src/01_module_ports.sv` | `module` / `endmodule`, and an ANSI port list |
| `src/02_logic_and_vectors.sv` | `logic`, `logic [3:0]`, bit- and part-select |
| `src/03_assign_and_operators.sv` | `assign`, and `& \| ^ ~` |
| `src/04_concatenation.sv` | `{cout, sum}` |
| `src/05_always_comb.sv` | `always_comb`, `=`, `if`/`else` |
| `src/06_case_default.sv` | `case` with a `default:` |
| `src/07_instantiation.sv` | a module inside a module, `.port(signal)` |
| `src/08_generate_for.sv` | `genvar`, `generate for`, `begin : slice` |
| `src/09_parameter.sv` | `parameter int N = 4`, and `#(.N(6))` |
| `src/10_literals.sv` | `4'b1010`, `4'd10`, `4'hA`, `'0`, `'1`, bare `10` |
| `src/11_width_truncation.sv` | the left side decides the width |
| `src/12_testbench_only.sv` | `` `timescale ``, `initial`, `$display`, `$dumpfile`, `$dumpvars`, `$finish` |
| `src/check_card.py` | The grader. Compares your twelve lines with the reference run |
| `broken/card.log` | The answer most people predict for card 11. `make broken` feeds it in |
| `broken/narrow_only.sv` | Card 11's mistake alone in a file, for `make lint` |
| `reference/card.expected` | The twelve lines, as printed on `hpretl/iic-osic-tools:2026.08` |
