# DD102: Digital Logic & FPGAs

Draw a circuit, transcribe it to SystemVerilog, and run it on an FPGA.

Course site: <https://uoftasic.com/dd102/> · Part of the
[UofT ASIC Team](https://github.com/uoftasic) education materials ·
[Education hub](https://edu.uoftasic.com/)

You drew a full adder on paper in [DD101](https://uoftasic.com/dd101/). This course turns that
drawing into text a machine reads, proves it against every input it can ever see, and puts it on
a real Lattice iCE40 UP5K as a 104,090-byte bitstream. Students follow the Course path on the
[course home page](docs/README.md#course-path): guide pages to read, alternating with five labs.

| | |
|---|---|
| Prerequisites | [IC101](https://uoftasic.com/ic101/) then [DD101](https://uoftasic.com/dd101/) |
| Workbench | `hpretl/iic-osic-tools:2026.08`: Icarus Verilog 14.0, Yosys 0.68, nextpnr-ice40, IceStorm, Verilator 5.050 |
| Time | 10–14 hours, self-paced |
| Ends with | a `ripple4.sv` the student wrote, proven on all 512 of its inputs, and the bitstream it becomes |

## Running the labs

Every package under `labs/` runs with `make` alone in a bare container, with no `.designinit`,
`mod`, PDK variable or other environment variable, and ends in a `PASS`/`FAIL` verdict. The two
steps that price a design in SKY130 cells (`make area` in `guide-examples`, `make contrast` in
Lab 05) read the liberty file from its fixed path in the image.

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

| Package | What it is |
|---|---|
| `labs/lab-01-transcribe-your-adder/` | the paper drawing, typed out, graded on eight rows |
| `labs/lab-02-prove-it/` | write the testbench, then three mutants grade it |
| `labs/lab-03-the-lazy-testbench/` | six hand-picked cases pass; all 512 don't |
| `labs/lab-04-four-adders-in-a-row/` | one `generate for`, and Yosys proves it equals the hand-typed version |
| `labs/lab-05-onto-the-fpga/` | `yosys` → `nextpnr` → `icepack`, and a real bitstream |
| `labs/guide-examples/` | the files behind the first guide pages and Inside an FPGA; used in Labs 01 and 05 |
| `labs/guide-examples-proving-it/` | the testbenches behind Testbenches and Waveforms; used in Labs 02 and 03 |
| `labs/guide-examples-carry/` | the width sweep behind Carry delay; used in Lab 05 |
| `labs/reference-card/` | twelve one-file cards, the whole DD102 SystemVerilog subset; used in Lab 04 |

Docs preview (requires Node.js):

```bash
npx docsify-cli serve docs      # → http://localhost:3000
```

## Layout

| Path | On Pages? | Purpose |
|------|-----------|---------|
| `docs/` | Yes | The Docsify site published at uoftasic.com/dd102/ |
| `docs/guide/` | Yes | Guide pages: reading only, no required commands |
| `docs/labs/` | Yes | Lab writeups: the one place students run things, in numbered steps |
| `docs/reference/` | Yes | Lookup pages |
| `labs/` | No | Runnable packages (HDL, Python graders, Makefiles) |
| `scripts/`, `notebooks/`, `data/`, `figures/` | No | Team utilities, exploratory work, sources |

No solutions or grade keys are published under `docs/`.

## GitHub Pages

| Setting | Value |
|---------|--------|
| Source | Deploy from a branch |
| Branch | `main` |
| Folder | `/docs` |

No Actions deploy step is needed. `.github/workflows/docs-link-check.yml` link-checks `docs/**`
on push and pull request.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md). New course repos are created
from [uoftasic/course-template](https://github.com/uoftasic/course-template); see
[TEMPLATE.md](TEMPLATE.md).

## License

[MIT](LICENSE). Copyright UofT ASIC Team / `uoftasic`.
