# DD102 — Digital Logic & FPGAs

Draw a circuit, transcribe it to SystemVerilog, and run it on an FPGA.

**Course site: <https://uoftasic.com/dd102/>** · Part of the
[UofT ASIC Team](https://github.com/uoftasic) education materials ·
[Education hub](https://edu.uoftasic.com/)

You drew a full adder on paper in [DD101](https://uoftasic.com/dd101/). This course turns that
drawing into text a machine reads, proves it against every input it can ever see, and lands it
on a real Lattice iCE40 UP5K as a 104,090-byte bitstream.

| | |
|---|---|
| **Prerequisites** | [IC101](https://uoftasic.com/ic101/) then [DD101](https://uoftasic.com/dd101/) |
| **Workbench** | `hpretl/iic-osic-tools:2026.08` — Icarus Verilog 14.0, Yosys 0.68, nextpnr-ice40, IceStorm, Verilator 5.050 |
| **Time** | 10–14 hours, self-paced |
| **Ends with** | `ripple4.sv` you wrote, proven on all 512 of its inputs, and the bitstream it becomes |

## Running the labs

Every package under `labs/` runs with **`make` alone, in a bare container, with no environment
setup** — no `.designinit`, no `mod`, no PDK, no liberty file, no environment variables — and
ends in a `PASS`/`FAIL` verdict rather than a shrug.

```bash
git clone https://github.com/uoftasic/dd102.git
cd dd102/labs/lab-01-transcribe-your-adder
make
```

Inside the workbench desktop, after [IC101](https://uoftasic.com/ic101/):

```bash
. /foss/designs/common/.designinit
mod add dd102          # first time only
mod dd102
cd labs/lab-01-transcribe-your-adder && make
```

| package | what it is |
|---|---|
| `labs/lab-01-transcribe-your-adder/` | your paper drawing, typed out, graded on eight rows |
| `labs/lab-02-prove-it/` | write the testbench, then three mutants grade *it* |
| `labs/lab-03-the-lazy-testbench/` | six hand-picked cases pass; all 512 do not |
| `labs/lab-04-four-adders-in-a-row/` | one `generate for`, and Yosys **proves** it equals the hand-typed version |
| `labs/lab-05-onto-the-fpga/` | `yosys` → `nextpnr` → `icepack`, and a real bitstream |
| `labs/guide-examples/` | the runnable half of Part I and II of the guide |
| `labs/guide-examples-proving-it/` | the runnable half of Part III |
| `labs/guide-examples-carry/` | the width sweep behind *The carry has to travel* |
| `labs/reference-card/` | twelve one-file cards, the whole DD102 SystemVerilog subset |

Docs preview (requires Node.js):

```bash
npx docsify-cli serve docs      # → http://localhost:3000
```

## Layout

| Path | On Pages? | Purpose |
|------|-----------|---------|
| `docs/` | **Yes** | The Docsify site published at uoftasic.com/dd102/ |
| `docs/guide/`, `docs/labs/`, `docs/reference/` | Yes | Guide pages, lab writeups, reference |
| `labs/` | No | Runnable packages (HDL, Python graders, Makefiles) |
| `scripts/`, `notebooks/`, `data/`, `figures/` | No | Team utilities, exploratory work, sources |

No solutions or grade keys are published under `docs/`.

## GitHub Pages

| Setting | Value |
|---------|--------|
| Source | Deploy from a branch |
| Branch | `main` |
| Folder | `/docs` |

No Actions deploy step is required. `.github/workflows/docs-link-check.yml` link-checks
`docs/**` on push and pull request.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md). New course repos are created
from [uoftasic/course-template](https://github.com/uoftasic/course-template); see
[TEMPLATE.md](TEMPLATE.md).

## License

[MIT](LICENSE) — Copyright UofT ASIC Team / `uoftasic`
