# DD102 — Digital Logic & FPGAs

You drew a full adder on paper in DD101. This course turns that drawing into text a machine
reads, proves it against every input it can ever see, and lands it on a real FPGA.

Part of the **UofT ASIC Team** education materials. Published at **https://uoftasic.com/dd102/**.
Labs run inside the shared **workspace** you set up in [IC101](https://uoftasic.com/ic101/).

## At a glance

| | |
|---|---|
| **Track** | Digital |
| **Prerequisites** | [IC101](https://uoftasic.com/ic101/) then [DD101](https://uoftasic.com/dd101/), in that order |
| **You bring** | Your DD101 **hand-drawn full-adder diagram** and your filled-in **8-row truth table**. On paper. That is the whole handoff. |
| **Tools** | Icarus Verilog, Yosys, nextpnr, icepack, Surfer — all inside the workbench. Three browser tabs alongside. |
| **Time** | 10–14 hours, self-paced |
| **You leave with** | `ripple4.sv` that you wrote, and a **104,090-byte bitstream** built from it |

> **This course is pinned to the workbench image `hpretl/iic-osic-tools:2026.04`.** Check yours:
>
> ```bash
> yosys -V        # Yosys 0.64
> iverilog -V     # first line: Icarus Verilog version 14.0 (devel)
> ```
>
> The browser tools in the table below run *different* versions of the same programs. That is
> fine, and [Getting started](guide/getting-started.md) tells you exactly where it matters.

> **If a setup command fails, try `make` anyway.** No lab in DD102 reads a PDK, a liberty file,
> or any environment variable — every package runs to a **PASS/FAIL verdict** in a bare
> container with no setup at all. A broken shell profile should cost you a confused minute, not
> the course.

## What you'll do

1. Put your DD101 drawing next to an empty file and **transcribe it** — one line per wire
2. Watch a machine **draw your schematic back to you** from the text you typed
3. Prove the adder against **all 8 rows**, then read the waveform that says so
4. Chain four of them into a **4-bit ripple adder** and prove that against all **512** inputs
5. Send it to a real FPGA: **8 lookup tables**, **10 of 5,280 logic cells**, one **104,090-byte** bitstream
6. Find out that your adder tops out somewhere around **23–24 ns, about 42 MHz** — two
   timing tools will give you 22.86 and 24.26 and neither is lying — and that the carry is why

## Path

| Part | Guide | Lab |
|------|-------|-----|
| 0 | [Getting started](guide/getting-started.md) | — |
| I — Drawing to text | [From your drawing to a module](guide/from-your-drawing-to-a-module.md) · [What a module actually is](guide/what-a-module-is.md) · [Everything happens at once](guide/assign-and-always-comb.md) | [Lab 01 — Transcribe your adder](labs/lab-01-transcribe-your-adder-overview.md) |
| II — Seeing it back | [Seeing it come back as a schematic](guide/seeing-it-come-back.md) | [Lab 02 — Prove it](labs/lab-02-prove-it-overview.md) |
| III — Proving it | [Eight rows and no opinions](guide/eight-rows-and-no-opinions.md) · [Two lines make the waveform appear](guide/two-lines-make-the-waveform-appear.md) | [Lab 03 — The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md) |
| IV — More than one bit | [Four adders in a row](guide/four-adders-in-a-row.md) | [Lab 04 — Four adders in a row](labs/lab-04-four-adders-in-a-row-overview.md) |
| V — Onto the chip | [The carry has to travel](guide/the-carry-has-to-travel.md) · [The chip is already there](guide/the-chip-is-already-there.md) | [Lab 05 — Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md) |

Reference: [The DD102 subset](reference/the-dd102-subset.md) ·
[Reading a waveform](reference/reading-a-waveform.md) ·
[When Icarus says syntax error](reference/when-icarus-says-syntax-error.md) ·
[The three services](reference/the-three-browser-tabs.md)

## The three browser tabs

DD102 is a workbench course, and it is also the only course in the track with a genuinely
useful browser half. These three are not a fallback — each does one job the terminal does
worse.

| Tab | What it is for here | Account? |
|---|---|---|
| **[DigitalJS Online](https://digitaljs.tilk.eu/)** | Paste your SystemVerilog, press **Run**, get a clickable schematic. It is Yosys compiled to WebAssembly, running in your tab. This is how you check your transcription against your paper drawing in about four seconds. | **None.** |
| **[EDA Playground](https://www.edaplayground.com/)** | Icarus Verilog 12.0 with **EPWave** waveforms, and a permalink you can paste into Discord so somebody can see exactly what you see. | **Google login, and it is the only account this whole track asks you for.** See [Getting started](guide/getting-started.md#the-one-account). |
| **[HDLBits](https://hdlbits.01xz.net/wiki/Main_Page)** | A drill deck. Small problems, checked by simulating your circuit against a reference. Use it when a concept has not stuck yet. | None to solve problems. Optional, to remember what you finished. |

**Stuck?** Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). Nobody expects you to work
this out alone at 2 a.m. — see [Getting help](guide/getting-started.md#getting-help).

## Quick start

```bash
# in the noVNC desktop, after IC101
. /foss/designs/common/.designinit
mod add dd102          # first time only
mod dd102
yosys -V               # expect: Yosys 0.64
cd labs/lab-01-transcribe-your-adder && make
```

## What you'll have at the end

`ripple4.sv` — a 4-bit ripple-carry adder you transcribed from your own drawing, proven correct
on all 512 of its possible inputs — and the 104,090-byte bitstream that same file becomes on a
Lattice iCE40 UP5K.

DD102 stops at the bitstream. **You do not get a GDSII in this course**, and it is worth
knowing why: a bitstream configures a chip that already exists, and that is a three-second
operation. A GDSII *is* a chip, and building one is the whole subject of DD103.

## Next courses

- **DD103** — RTL on FPGAs & ASICs: the exact `ripple4.sv` you wrote here, taken to silicon
- **DD104** — Pre-Silicon Verification · **DD201** — HLS · **DD202** — Computer Architecture
