# DD102: Digital Logic & FPGAs

Draw a circuit, transcribe it to SystemVerilog, and run it on an FPGA.

Course site: <https://uoftasic.com/dd102/> · Part of the
[UofT ASIC Team](https://github.com/uoftasic) education materials ·
[Education hub](https://edu.uoftasic.com/)

You drew a full adder on paper in [DD101](https://uoftasic.com/dd101/). In this course you
type that drawing into SystemVerilog, tests it against every input it can ever see, and turns
it into a 104,090-byte bitstream for a real Lattice iCE40 UP5K (no board needed). Students follow the Course path on the
[course home page](docs/index.md#course-path): guide pages to read, alternating with five labs.

| | |
|---|---|
| Prerequisites | [IC101](https://uoftasic.com/ic101/) then [DD101](https://uoftasic.com/dd101/) |
| Workbench | `hpretl/iic-osic-tools:2026.08`: Icarus Verilog 14.0, Yosys 0.68, nextpnr-ice40, IceStorm, Verilator 5.050 |
| Time | about 12 h 20 min, self-paced (the sum of the Course path rows) |
| Ends with | a `ripple4.sv` the student rewrote and proved equal to a hand-typed version, tested on all 512 of its inputs, and the bitstream it becomes |

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

Docs preview (requires [Quarto](https://quarto.org/docs/get-started/) 1.11):

```bash
quarto preview docs                            # → http://localhost:4200
quarto render docs --profile pdf --to typst    # whole course as one PDF in docs/_book/
```

## Layout

| Path | On Pages? | Purpose |
|------|-----------|---------|
| `docs/` | Yes | The Quarto site (`docs/_quarto.yml`) published at uoftasic.com/dd102/ |
| `docs/guide/` | Yes | Guide pages: reading only, no required commands |
| `docs/labs/` | Yes | Lab writeups: the one place students run things, in numbered steps |
| `docs/reference/` | Yes | Lookup pages |
| `labs/` | No | Runnable packages (HDL, Python graders, Makefiles) |
| `scripts/`, `notebooks/`, `data/`, `figures/` | No | Team utilities, exploratory work, sources |

No solutions or grade keys are published under `docs/`.

## GitHub Pages

| Setting | Value |
|---------|--------|
| Source | GitHub Actions |

`.github/workflows/site.yml` renders `docs/` with Quarto on every push to `main` that touches it,
checks every local link and anchor in the result with `scripts/check_site.py`, and deploys
`docs/_site`, which includes a PDF of every page and the whole course as `dd102-course.pdf`. On a
pull request it builds and checks without deploying. `.github/workflows/docs-link-check.yml` also
runs lychee on the Markdown in `docs/**` on push and pull request.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md). New course repos are created
from [uoftasic/course-template](https://github.com/uoftasic/course-template); see
[TEMPLATE.md](TEMPLATE.md).

## License

[MIT](LICENSE). Copyright UofT ASIC Team / `uoftasic`.
