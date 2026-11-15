# Inside an FPGA

Your adder becomes hardware on an FPGA, and yet you can reprogram the FPGA in three seconds, even
though hardware is supposed to be the part you can't change. That works because nothing is built
when you program it: the chip already exists, complete, before you write a line. Every wire and
transistor on the FPGA was manufactured months ago, in a fab that had never heard of your adder,
so what you send it is a file of settings for hardware that is already there. That one fact
explains most of the surprising numbers in FPGA reports, and it's what this page is about.

Every number on this page came from running `yosys synth_ice40` and `nextpnr-ice40` on the
workbench image, `hpretl/iic-osic-tools:2026.08`, and you'll run both yourself in
[Lab 05](../labs/lab-05-onto-the-fpga-overview.md).

## What an `SB_LUT4` is

When you synthesized your adder for the iCE40 in Lab 04, the answer came back in a unit you didn't
choose:

```
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
```

Rather than nine Xor gates or nine Ands, the report counts nine copies of one thing, the
`SB_LUT4`, where LUT is short for **lookup table**. An `SB_LUT4` is three pieces of hardware
working together, and none of them is a logic gate:

1. Four input wires.
2. Sixteen bits of memory, because four inputs have $2^4 = 16$ combinations.
3. A multiplexer that uses the four inputs as an address and hands you the one bit stored there.

There is nothing else in it, so the LUT never works its output out from the inputs: it uses them
as an address and looks the answer up in its memory.

Write the sixteen bits out in address order, address `0000` first and `1111` last, and you can
see how the memory contents choose the function. Load `0000000000000001` and the LUT behaves as a
4-input AND, because the only address that gives a 1 is `1111`, the last one. Load
`0110100110010110` and it's a 4-input XOR. Load sixteen random bits and you get a function with
no name, which is exactly as fast as the other two.

On an FPGA, the truth tables you wrote in DD101 are the hardware itself: the rightmost column of
the table is written into the LUT's memory, one bit per row.

## What a lookup table costs

Here are three different four-input functions, written one line each:

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
Each file is nine or ten lines long: a header comment, a port list and the line shown above.
Synthesized for the iCE40, each one costs exactly one lookup table:

```
  lut_simple   1 SB_LUT4
  lut_parity   1 SB_LUT4
  lut_weird    1 SB_LUT4
```

A four-input AND and a function nobody has a name for cost the same, because on an FPGA the cost
of a piece of logic depends on how many inputs it has, not on how hard the logic is. To see that,
add a fifth input to the AND and change nothing else:

```systemverilog
assign y = a & b & c & d & e;                   // src/lut_five.sv
```

```
  lut_five     2 SB_LUT4
```

One more input doubled the price, even though this is the simplest function in the set. Four
inputs fit in one table, but five need two tables and a way to combine their outputs. So when you
want to know what something will cost on an FPGA, ask "how many inputs does this depend on?"
rather than "how complicated is this?". The two questions have different answers, and only the
first one predicts the report. You'll run this comparison yourself in Lab 05, Part 1.

## Utilisation

Here is the placement report for your 4-bit adder from Lab 05:

```
PASS  luts      synth_ice40 mapped ripple4 to 9 SB_LUT4
PASS  util      nextpnr placed 11/5280 logic cells and 14/39 pins
```

Your adder uses 11 of the 5,280 logic cells, which is about two tenths of one percent of the
logic on this part. The other 5,269 logic cells are still there, powered and doing nothing, and
you pay for them whether you use them or not, because they were fabricated before anyone knew
what you wanted.

That is the deal an FPGA offers: you don't decide what is on the chip, only what each of the
things already on it is currently pretending to be, and you can change your mind in seconds.
DD103 opens by comparing this with the alternative, which is like buying an empty lot and pouring
exactly the shapes your design needs. That alternative is an ASIC, delivered as a GDSII file, and
it takes months. For now, the thing to remember is that the report counts slots used
out of a fixed supply, which is a different kind of number from an area.

To give 11/5280 a sense of scale, Lab 05 also places two other designs on the same part:

```
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
```

A single gate takes 3 logic cells, and a design that fills most of the part takes 4,001 and still
runs at over 200 MHz, so your adder is much nearer the first than the second.

## What is in a bitstream

Since the chip already exists and you are only choosing settings, the file you upload is a list
of those settings, one for every configurable point on the die. It is called a **bitstream**, and
in Lab 05 you produce one with `icepack`:

```bash
icepack results/r4.asc results/r4.bin
```

Lab 05 shows you the size of that file and then asks you to predict the size of two other
designs' bitstreams, and the answer is the best surprise in DD102, so don't let anyone tell you
first. What we can tell you now is that a
bitstream doesn't describe your adder. There is no `ripple4` in it, no `slice[1].fa` and no carry
chain; it holds the contents of every LUT's sixteen bits of memory and the state of every routing
switch, in whatever order the silicon wants them.

That's why loading one takes only three seconds. Nothing is compiled, built or manufactured:
memory cells all over an existing chip get written, and the chip, which was pretending to be
nothing in particular, starts pretending to be your adder.

A bitstream isn't human-readable, so it isn't something you can show anybody as evidence. If you
find yourself opening `r4.bin` in a text editor to check your work, stop. The file that shows
your design is correct is your testbench output, and the file that shows it fits is nextpnr's
utilisation report. Both are text, and you already have both.

## In the browser

[DigitalJS Online](https://digitaljs.tilk.eu/) has a checkbox labelled **Map into LUTs**: with
your `full_adder.sv` pasted in and that box ticked, the schematic redraws with lookup tables where
your gates were. It's the fastest way to see the substitution that `synth_ice40` makes. Two
cautions apply, both from [The browser tools](../reference/the-three-browser-tabs.md):

- Use it for the picture, never for the count. The Yosys it runs is loaded from a CDN without a
  pinned version (on 2026-08-25 that was 0.65.176-dev.1145, against your workbench's 0.68), so if
  its numbers disagree with yours, neither of them is broken.
- The LUTs it draws are generic lookup tables, not iCE40 `SB_LUT4`s specifically.

## Common misreadings

"Then an FPGA is just a slow simulator." It isn't, because nothing is being interpreted and there
is no program running. Those sixteen bits are wired into a multiplexer built from transistors,
and the answer comes out at the speed of the silicon, which is why
[Carry delay](../guide/the-carry-has-to-travel.md) is measured in nanoseconds rather than
instructions.

"9 LUTs from Yosys and 11 logic cells from nextpnr, so one of them is wrong." Neither is
wrong, because they count different things: Yosys counts the lookup tables it mapped, and nextpnr
counts the logic cells it placed. For this adder the difference is two cells that the packer
adds, `$PACKER_GND` and `$PACKER_VCC`, because the design needs constants and the chip has no
wire that is permanently 0 or permanently 1. Lab 05 lists all eleven cells by name. Quote
whichever count answers the question you were asked, and say which tool it came from.

"5,269 wasted logic cells sounds terrible." Those cells are part of the product: what you are
buying is the ability to change your mind in three seconds instead of three months, and unused
silicon is what that costs. When the volume is high enough that the trade stops making sense, you
stop buying FPGAs, and that decision is where DD103 starts.

## Check yourself

1. An `SB_LUT4` holds `0000000000000001`. Which function of its four inputs is it?
2. Why do `a & b & c & d` and `(a ^ b) ? (c & ~d) : (~c | d)` cost the same on an iCE40, while
   `a & b & c & d & e` costs twice as much?
3. Yosys reports 9 `SB_LUT4` for `ripple4` and nextpnr reports 11 logic cells. Where do the other
   two come from?
4. Why is a bitstream not a description of your design?

Next on the [Course path](../index.md#course-path): do
[Lab 05: Onto the FPGA](../labs/lab-05-onto-the-fpga-overview.md).
