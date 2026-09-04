# The chip is already there

**Question this page answers:** *If my adder becomes hardware, how can somebody reprogram an
FPGA in three seconds? Hardware is supposed to be the part you cannot change.*

Because nothing is being built. **The chip already exists, complete, before you write a line.**
Every wire and every transistor on that FPGA was manufactured months ago in a fab that had never
heard of your adder. What you send it is not a design — it is a **settings file**.

That one sentence explains almost every strange thing about FPGA reports, and it is the whole of
this page.

Every number below came from `yosys synth_ice40` on the workbench image, `hpretl/iic-osic-tools:2026.08`.

## `SB_LUT4` is not a gate

When you synthesized your adder in [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md), the answer came
back in a currency you did not choose:

```
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
```

Eight `SB_LUT4`. Not eight XOR gates, not eight ANDs — eight of one thing, whose name is an
abbreviation for **lookup table**.

A `SB_LUT4` is three pieces of hardware soldered together, and none of them is a logic gate:

1. **Four input wires.**
2. **Sixteen bits of memory** — because four inputs have exactly $2^4 = 16$ combinations.
3. **A multiplexer** that uses the four inputs as an *address* and hands you the one bit stored
   at it.

That is all. It does not compute anything. It **looks the answer up**.

Write the sixteen bits out in address order — address `0000` first, address `1111` last. Load
`0000000000000001` and the thing behaves as a 4-input AND: the only address that gives a 1 is
`1111`, which is the last one. Load `0110100110010110` and it is a 4-input XOR. Load sixteen bits
somebody generated at random and it is a function with no name that is every bit as fast as the
other two.

**Your truth table from DD101 was not a metaphor for the hardware. On an FPGA it *is* the
hardware** — the rightmost column of the table, written into memory, one bit per row.

## The demonstration

Here are three completely different four-input functions. Predict how many `SB_LUT4` each
costs before you read the answer.

```systemverilog
assign y = a & b & c & d;                       // src/lut_simple.sv
assign y = a ^ b ^ c ^ d;                       // src/lut_parity.sv
assign y = (a ^ b) ? (c & ~d) : (~c | d);       // src/lut_weird.sv
```

**These three lines are excerpts** — one line each out of three complete, shipped files:
[`src/lut_simple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_simple.sv),
[`src/lut_parity.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_parity.sv)
and
[`src/lut_weird.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_weird.sv),
all in
[`labs/guide-examples/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples). Each is
nine or ten lines: a header comment, a port list, and the line above.

`make` in that package runs all four for you, or you can do one by hand with the same command you
used in Lab 04:

```bash
cd labs/guide-examples
yosys -p "read_verilog -sv src/lut_simple.sv; synth_ice40 -top lut_simple; stat"
```

The result, for all three:

```
  lut_simple   1 SB_LUT4
  lut_parity   1 SB_LUT4
  lut_weird    1 SB_LUT4
```

**One lookup table each.** A four-input AND and a function nobody has a name for cost exactly the
same, because on an FPGA cost is not measured in how hard your logic is. It is measured in **how
many inputs it has**.

Now add a fifth input and nothing else:

```systemverilog
assign y = a & b & c & d & e;                   // src/lut_five.sv
```

```
  lut_five     2 SB_LUT4
```

and `make luts` renders the verdict:

```
PASS - three different 4-input functions cost ONE lookup table each.
       One extra input cost a second one, on the simplest function here.
       On an FPGA the price is the number of inputs, not the difficulty.
```

**The price doubled for one more input**, on the simplest function in the file. Four inputs is a
shelf. Five inputs needs two shelves and a way to combine them.

> **The reflex:** on an FPGA, ask *"how many inputs does this depend on?"*, never *"how
> complicated is this?"* The two questions have different answers and only the first one predicts
> the report.

## The warehouse you are renting

Now look at the whole report from Lab 05 rather than one line of it:

```
PASS  luts      synth_ice40 mapped ripple4 to 9 SB_LUT4
PASS  util      nextpnr placed 11/5280 logic cells and 14/39 pins
```

**10 of 5,280.** Your adder occupies two tenths of one percent of the logic on this part. The
other 5,270 logic cells are sitting there, powered, doing nothing, and you are paying for them
whether you use them or not — because they were fabricated before anyone knew what you wanted.

That is the deal an FPGA offers. You do not get to decide what is on the chip. You get to decide
**what each of the things already on the chip is currently pretending to be**, and you get to
change your mind in seconds.

DD103 opens by setting this against the alternative — buying an empty lot and pouring exactly the
shapes your design needs, which is an ASIC, which is a **GDSII**, and which takes months. You do
not need that argument yet. You need to know that the report in front of you counts **slots used
out of a fixed supply**, and that this is a different kind of number from an area.

### Two more numbers, so 11/5280 has a scale

Lab 05 places two other designs on the same part:

```
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
```

A single gate takes 3 logic cells. A design that genuinely fills the part takes 4,001 and still
runs at over 200 MHz. Your adder is much nearer the first than the second.

## So what is in the file you send it?

If the chip already exists and you are only choosing settings, then the thing you upload is a
list of settings — one for every configurable point on the die. It is called a **bitstream**,
and in Lab 05 you produce one:

```bash
icepack results/r4.asc results/r4.bin
```

Hold that thought about what is *in* it, because Lab 05 asks you to predict the size of that file
before it shows you, and the answer is the best surprise in DD102. Do not let anyone tell you
first.

What you can safely know now: a bitstream is **not** a description of your adder. There is no
`ripple4` in it, no `slice[1].fa`, no carry chain. It is the contents of every LUT's sixteen bits
of memory and the state of every routing switch, in whatever order the silicon wants them.

**That is why loading one takes three seconds.** Nothing is compiled, nothing is built, nothing
is manufactured. Memory cells all over an existing chip get written, and the chip that was
pretending to be nothing in particular starts pretending to be your adder.

> **The dead end, named before you find it.** A bitstream is not readable and it is not a
> deliverable you show anybody. If you find yourself opening `r4.bin` in a text editor to check
> your work, stop — the file that proves your design is correct is your **testbench output**, and
> the file that proves it fits is `nextpnr`'s **utilisation report**. Both are text, and you
> already have both.

## Seeing it without leaving the browser

[DigitalJS Online](https://digitaljs.tilk.eu/) has a checkbox labelled **Map into LUTs**, and it
does this whole page in one click: paste your `full_adder.sv`, tick it, and the schematic redraws
itself with lookup tables where your gates were.

It is the fastest way to *see* the substitution that `synth_ice40` performs in the terminal, and
it costs nothing and needs no account. Two cautions, both from
[The three services](reference/the-three-browser-tabs.md):

- **Use it for the picture, never for the count.** Its Yosys comes unpinned from a CDN — on
  2026-08-25 that was **0.65.176-dev.1145** against your workbench's **0.64** — so if its numbers
  disagree with yours, neither one is broken.
- Its LUTs are a generic drawing, not iCE40 `SB_LUT4` specifically.

## The part that trips people up

**"Then an FPGA is just a slow simulator."** No. Nothing is being interpreted and there is no
program. Those sixteen bits are wired into a multiplexer built out of transistors, and the answer
comes out at the speed of the silicon — which is why
[The carry has to travel](guide/the-carry-has-to-travel.md) is measured in nanoseconds rather than
instructions. Your logic really is running as hardware. It is running as hardware that was
*already there*.

**"8 LUTs from Yosys, 10 logic cells from nextpnr — one of them is wrong."** Neither. Yosys counts
what it mapped; `nextpnr` counts what it *placed*, after packing LUTs together with the carry
logic and the flip-flops that share a cell. The counts stop matching at that step and they are
supposed to. Quote whichever one answers the question you were asked, and say which tool it came
from.

**"5,270 wasted logic cells sounds terrible."** It is the entire product. You are buying the
ability to change your mind in three seconds instead of in three months, and unused silicon is
what that costs. When the volume is high enough that the trade stops making sense, you stop
buying FPGAs — and that decision is where DD103 starts.

## What to remember

- The chip is **manufactured before your design exists**. You choose settings, not shapes.
- A `SB_LUT4` is four inputs, **sixteen bits of memory**, and a multiplexer. It looks answers up;
  it does not compute them.
- **Cost on an FPGA is input count, not complexity.** Three unrelated 4-input functions were
  **1 `SB_LUT4`** each; one 5-input AND was **2**.
- The report counts **slots out of a fixed supply** — `11/5280` logic cells, `14/39` pins. That is
  an FPGA answer, and it is not an area.
- A **bitstream** is the settings for the whole warehouse, not a description of your design. That
  is why it loads in seconds.

Next: [Lab 05 — Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md), where your own `ripple4.sv` becomes
a real bitstream in three commands and 0.8 seconds — and where you find out how big that file is,
which is not what you are about to guess.
