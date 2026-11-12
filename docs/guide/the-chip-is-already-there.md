# Inside an FPGA

Your adder becomes hardware, and yet an FPGA can be reprogrammed in three seconds, when hardware
is supposed to be the part you can't change. The reason is that nothing is being built. The chip
exists, complete, before you write a line. Every wire and transistor on the FPGA was manufactured
months ago in a fab that had never heard of your adder. What you send it isn't a design; it is a
settings file. That explains most of the surprising
numbers in FPGA reports, and it is what this page is about.

Every number below came from `yosys synth_ice40` and `nextpnr-ice40` on the workbench image,
`hpretl/iic-osic-tools:2026.08`. You run them in [Lab 05](labs/lab-05-onto-the-fpga-overview.md).

## What an `SB_LUT4` is

When you synthesized your adder for the iCE40 in Lab 04, the answer came back in a unit you didn't
choose:

```
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
```

Nine `SB_LUT4`: not nine Xor gates or nine Ands, but nine of one thing, whose name is short for
**lookup table**. An `SB_LUT4` is three pieces of hardware together, and none of them is a logic
gate:

1. Four input wires.
2. Sixteen bits of memory, because four inputs have $2^4 = 16$ combinations.
3. A multiplexer that uses the four inputs as an address and hands you the one bit stored there.

That is all. It doesn't compute anything; it looks the answer up.

Write the sixteen bits out in address order, address `0000` first and `1111` last. Load
`0000000000000001` and it behaves as a 4-input AND: the only address that gives a 1 is `1111`, the
last one. Load `0110100110010110` and it is a 4-input XOR. Load sixteen random bits and it is a
function with no name that is exactly as fast as the other two.

Your truth table from DD101 wasn't a metaphor for the hardware. On an FPGA it is the hardware: the
rightmost column of the table, written into memory, one bit per row.

## What a lookup table costs

Three different four-input functions, one line each:

```systemverilog
assign y = a & b & c & d;                       // src/lut_simple.sv
assign y = a ^ b ^ c ^ d;                       // src/lut_parity.sv
assign y = (a ^ b) ? (c & ~d) : (~c | d);       // src/lut_weird.sv
```

These lines are excerpts of three complete files in
[`labs/guide-examples/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples):
[`src/lut_simple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_simple.sv),
[`src/lut_parity.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_parity.sv)
and [`src/lut_weird.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_weird.sv).
Each is nine or ten lines: a header comment, a port list and the line above. Synthesized for the
iCE40, each one costs exactly one lookup table:

```
  lut_simple   1 SB_LUT4
  lut_parity   1 SB_LUT4
  lut_weird    1 SB_LUT4
```

A four-input AND and a function nobody has a name for cost the same, because on an FPGA cost
isn't measured by how hard your logic is. It is measured by how many inputs it has. Add a fifth
input and nothing else:

```systemverilog
assign y = a & b & c & d & e;                   // src/lut_five.sv
```

```
  lut_five     2 SB_LUT4
```

One more input doubled the price, on the simplest function in the set. Four inputs fit in one
table; five need two tables and a way to combine them. On an FPGA, ask "how many inputs does this
depend on?", not "how complicated is this?". The two questions have different answers, and only
the first predicts the report. You run this comparison in Lab 05, Part 1.

## Utilisation

Here is the placement report for your 4-bit adder from Lab 05:

```
PASS  luts      synth_ice40 mapped ripple4 to 9 SB_LUT4
PASS  util      nextpnr placed 11/5280 logic cells and 14/39 pins
```

11 of 5,280. Your adder uses about two tenths of one percent of the logic on this part. The other
5,269 logic cells are there, powered and doing nothing, and you pay for them whether you use them
or not, because they were fabricated before anyone knew what you wanted.

That is the deal an FPGA offers. You don't decide what is on the chip. You decide what each of the
things already on the chip is currently pretending to be, and you can change your mind in seconds.
DD103 opens by setting this against the alternative: buying an empty lot and pouring exactly the
shapes your design needs, which is an ASIC, which is a GDSII, and which takes months. For now, know
that the report counts slots used out of a fixed supply, which is a different kind of number from
an area.

Lab 05 places two other designs on the same part, to give 11/5280 a scale:

```
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
```

A single gate takes 3 logic cells. A design that fills most of the part takes 4,001 and still runs
at over 200 MHz. Your adder is much nearer the first than the second.

## What is in a bitstream

If the chip already exists and you are only choosing settings, the thing you upload is a list of
settings, one for every configurable point on the die. It is called a **bitstream**, and in Lab 05
you produce one with `icepack`:

```bash
icepack results/r4.asc results/r4.bin
```

Lab 05 asks you to predict the size of that file before it shows you, and the answer is the best
surprise in DD102, so don't let anyone tell you first. What you can know now: a bitstream isn't a
description of your adder. There is no `ripple4` in it, no `slice[1].fa`, no carry chain. It is
the contents of every LUT's sixteen bits of memory and the state of every routing switch, in
whatever order the silicon wants them.

That is why loading one takes three seconds. Nothing is compiled, built or manufactured. Memory
cells all over an existing chip get written, and the chip that was pretending to be nothing in
particular starts pretending to be your adder.

A bitstream isn't readable, and it isn't something you show anybody as evidence. If you find
yourself opening `r4.bin` in a text editor to check your work, stop. The file that shows your
design is correct is your testbench output, and the file that shows it fits is nextpnr's
utilisation report. Both are text, and you already have both.

## In the browser

[DigitalJS Online](https://digitaljs.tilk.eu/) has a checkbox labelled **Map into LUTs**: with
your `full_adder.sv` pasted in and that box ticked, the schematic redraws with lookup tables where
your gates were. It is the fastest way to see the substitution `synth_ice40` makes. Two cautions,
both from [The browser tools](reference/the-three-browser-tabs.md):

- Use it for the picture, never for the count. Its Yosys comes unpinned from a CDN (on 2026-08-25
  that was 0.65.176-dev.1145, against your workbench's 0.68), so if its numbers disagree with
  yours, neither is broken.
- Its LUTs are a generic drawing, not iCE40 `SB_LUT4`s specifically.

## Common misreadings

"Then an FPGA is just a slow simulator." No. Nothing is being interpreted and there is no program.
Those sixteen bits are wired into a multiplexer built from transistors, and the answer comes out
at the speed of the silicon, which is why [Carry delay](guide/the-carry-has-to-travel.md) is
measured in nanoseconds rather than instructions.

"9 LUTs from Yosys and 11 logic cells from nextpnr, so one of them is wrong." Neither. Yosys counts
the lookup tables it mapped; nextpnr counts the logic cells it placed. For this adder the
difference is two cells the packer adds, `$PACKER_GND` and `$PACKER_VCC`, because the chip has no
wire that is permanently 0 or permanently 1 and the design needs constants; Lab 05 lists all
eleven cells by name. Quote whichever count answers the question you were asked, and say which
tool it came from.

"5,269 wasted logic cells sounds terrible." It is the product. You are buying the ability to
change your mind in three seconds instead of three months, and unused silicon is what that costs.
When the volume is high enough that the trade stops making sense, you stop buying FPGAs, and that
decision is where DD103 starts.

## Check yourself

1. An `SB_LUT4` holds `0000000000000001`. Which function of its four inputs is it?
2. Why do `a & b & c & d` and `(a ^ b) ? (c & ~d) : (~c | d)` cost the same on an iCE40, while
   `a & b & c & d & e` costs twice as much?
3. Yosys reports 9 `SB_LUT4` for `ripple4` and nextpnr reports 11 logic cells. Where do the other
   two come from?
4. Why is a bitstream not a description of your design?

Next on the [Course path](README.md#course-path): do
[Lab 05: Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md).
