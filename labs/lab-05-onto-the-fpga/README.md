# Lab 05 — Onto the FPGA

Writeup: [`docs/labs/lab-05-onto-the-fpga-overview.md`](../../docs/labs/lab-05-onto-the-fpga-overview.md)

The last lab in DD102. `src/ripple4.sv` is the file you wrote in Lab 04; here it becomes a
**bitstream for a real Lattice iCE40 UP5K**, and then — the same two files, one command later —
a pile of SKY130 standard cells, which is where DD103 starts.

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-05-onto-the-fpga
make
```

**Under half a minute**, ending in twelve verdicts.

**No board is needed and none is assumed.** Everything here is synthesis and place-and-route.
`make flash` exists for the one student in ten who owns an iCEBreaker; it is optional, it is
not checked, and nothing depends on it.

Individual steps: `make fpga`, `make sizes`, `make fits`, `make pins`, `make contrast`.
`make check` re-runs the verdicts on artefacts you already have. `make icetime` and `make flash`
are the two optional ones. `make clean` empties `results/`.

## What's here

| File | What it is |
|---|---|
| `src/ripple4.sv`, `src/full_adder.sv` | Your Lab 04 adder, copied so you can edit the original freely. |
| `src/one_gate.sv` | One AND gate. Three logic cells. Used by `make sizes`. |
| `src/big.sv` | A 4000-stage shift register. 4001 logic cells, three pins. Also `make sizes`. |
| `src/toobig.sv` | A 16×16 multiplier. Fits in logic, does **not** fit in pins. `make fits`. |
| `constraints/r4.pcf` | Fourteen `set_io` lines: which signal comes out of which physical pin. |
| `scripts/asic.ys` | The same two source files, mapped to SKY130 standard cells instead. |
| `src/check_lab05.py` | **The grader.** Knows every number below, including the byte count. `--lcs` lists the placed logic cells. |

`results/` ships empty. This lab writes about 3 MB of netlists, ASCII bitstreams and binaries,
and `make icetime` unpacks a 27 MB chip database into it. Everything regenerates in under half a minute.

## Expected results

Measured on `hpretl/iic-osic-tools:2026.08` — Yosys 0.68, nextpnr-0.11.1-9-gb17408e2,
IceStorm, Python 3.12.3. Every run of this flow is deterministic: the same input gives the same
bitstream, byte for byte.

```
PASS  luts      synth_ice40 mapped ripple4 to 9 SB_LUT4
PASS  util      nextpnr placed 11/5280 logic cells and 14/39 pins
PASS  lcs       11 logic cells placed: 9 from your RTL + 2 the packer added
PASS  path      the critical path is 2.98 ns of logic and 23.24 ns of wire
PASS  nofmax    no flip-flops, so --freq 50 had nothing to check
PASS  bitstream r4.bin is 104090 bytes, reference says 104090
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
PASS  toobig    toobig needs 64 pins, the package has 39, and nextpnr says so
PASS  pins      the .pcf placed all 14 pins; the path got 12.1 ns shorter end to end
PASS  asic      the same RTL on SKY130: 4 maj3_1 + 8 xnor2_1 = 110.1056 um^2
PASS  sizes     4 designs, all 104090 bytes
```

The last line is the lab. Three designs that differ by a factor of 1300 in size, and one of
them with its pins nailed down, produce **bitstreams of exactly the same length**.

## Numbers that are yours, not ours

Two things printed by `make` legitimately differ on your machine, and the grader does not
check either:

- **`results/r4.json` is about 336 KB.** Yosys records the source file path of every wire, so
  the size shifts by a few hundred bytes depending on where you cloned the repo.
- **`results/ys.log` is 910 lines.** That is a fair count on this image, but log verbosity is
  the sort of thing a tool release changes. `r4.asc` (707,718 bytes) and `r4.bin`
  (**104,090 bytes**) are the stable ones, and `r4.bin` is the one that matters.

## Two optional targets

- **`make icetime`** demonstrates a dead end in three steps: the obvious command fails, the
  obvious fix **segfaults** (`Segmentation fault (core dumped)`, exit 139), and the third thing
  works. The writeup explains why you did not need it in the first place.
- **`make flash`** runs `iceprog`. With no board it prints
  `Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).` and exits 2.
  That message is verified; the with-a-board path is **not** — nobody has run these pages
  against hardware. If you have an iCEBreaker and try it, tell us in
  [Discord](https://discord.gg/hrJnP5UsGz).
