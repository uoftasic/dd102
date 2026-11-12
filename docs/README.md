# DD102: Digital Logic & FPGAs

You drew a full adder on paper in DD101. In this course you type that drawing into
SystemVerilog, test it against every input it can ever see, chain four copies into a 4-bit adder,
and turn the result into a bitstream for a real FPGA.

Part of the UofT ASIC Team education materials, published at <https://uoftasic.com/dd102/>. The
labs run inside the shared workbench you set up in [IC101](https://uoftasic.com/ic101/).

## Who this is for

Students who have finished [IC101](https://uoftasic.com/ic101/) and then
[DD101](https://uoftasic.com/dd101/), in that order.

| | |
|---|---|
| Prerequisites | IC101, then DD101 |
| You bring | your DD101 hand-drawn full-adder diagram and your filled-in 8-row truth table, on paper |
| Tools | Icarus Verilog, Verilator, Yosys, nextpnr, icepack, GTKWave and Surfer in the workbench, plus three websites: DigitalJS Online, EDA Playground and HDLBits ([Getting started](guide/getting-started.md#the-three-browser-tabs)) |
| Time | 10–14 hours, self-paced (the path below adds up to about 12½) |
| You leave with | a `ripple4.sv` you wrote, proven on all 512 of its inputs, and the 104,090-byte bitstream it becomes on a Lattice iCE40 UP5K |

The course is pinned to the workbench image `hpretl/iic-osic-tools:2026.08`. Lab 01, Part 1
checks that you are on it (`yosys -V` prints `Yosys 0.68`, and the first line of `iverilog -V` is
`Icarus Verilog version 14.0 (devel)`). The browser tools run different versions of the same
programs; [Getting started](guide/getting-started.md) says where that matters.

## Course path

Work down this table in order. Read rows are guide pages: concepts and worked examples, nothing
to run. Do rows are labs, where you run every command, in numbered steps.

| # | | Step | Time |
|---|---|---|---|
| 1 | Read | [Getting started](guide/getting-started.md) · [From your drawing to a module](guide/from-your-drawing-to-a-module.md) · [Modules and instances](guide/what-a-module-is.md) · [`assign` and `always_comb`](guide/assign-and-always-comb.md) · [Seeing your adder as a schematic](guide/seeing-it-come-back.md) | 1 h |
| 2 | Do | [Lab 01: Transcribe your adder](labs/lab-01-transcribe-your-adder-overview.md): set up, type your drawing, check it against eight rows and as a schematic | 2½ h |
| 3 | Read | [Testbenches](guide/eight-rows-and-no-opinions.md) | 30 min |
| 4 | Do | [Lab 02: Prove it](labs/lab-02-prove-it-overview.md): write a testbench and make it catch three broken adders | 1½ h |
| 5 | Read | [Waveforms](guide/two-lines-make-the-waveform-appear.md) | 20 min |
| 6 | Do | [Lab 03: The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md): hand-picked cases against all 512 inputs of a 4-bit adder | 2 h |
| 7 | Read | [Vectors, generate loops and parameters](guide/four-adders-in-a-row.md) | 30 min |
| 8 | Do | [Lab 04: Four adders in a row](labs/lab-04-four-adders-in-a-row-overview.md): one `generate for`, and a proof it equals the hand-typed version | 1½ h |
| 9 | Read | [Carry delay](guide/the-carry-has-to-travel.md) · [Inside an FPGA](guide/the-chip-is-already-there.md) | 45 min |
| 10 | Do | [Lab 05: Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md): synthesis, place-and-route and a bitstream | 2 h |

The times are estimates. Reference pages are for looking things up whenever you need them:
[The DD102 subset](reference/the-dd102-subset.md) ·
[Reading a waveform](reference/reading-a-waveform.md) ·
[Icarus error messages](reference/when-icarus-says-syntax-error.md) ·
[The browser tools](reference/the-three-browser-tabs.md)

If a workbench setup command in Lab 01, Part 1 fails, run `make` in the lab's folder anyway. Each
lab's files live in a package folder under `labs/`, and no package needs `.designinit`, a PDK
variable or any other environment variable; each one runs to a PASS/FAIL verdict in a bare
container.

Stuck? Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). See
[Getting help](guide/getting-started.md#getting-help) for what to post.

## What you'll have at the end

`ripple4.sv`, a 4-bit ripple-carry adder you transcribed from your own drawing and proved correct
on all 512 of its inputs, and the 104,090-byte bitstream that file becomes on a Lattice iCE40
UP5K. Along the way you measure how long its carry takes to cross the adder on that FPGA,
26.22 ns, and why most of that time is wire.

DD102 stops at the bitstream. You don't get a GDSII, the file a chip is manufactured from,
in this course. A bitstream configures a chip that already exists, which takes seconds; building
the chip itself is the subject of DD103.

## Next courses

- DD103: RTL on FPGAs & ASICs. The `ripple4.sv` you wrote here, taken to silicon.
- DD104: Pre-Silicon Verification. DD201: HLS. DD202: Computer Architecture.
