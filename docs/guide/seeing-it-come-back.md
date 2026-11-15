# Seeing your adder as a schematic

So far you have turned a drawing into text. This page is about the trip back: turning the text
into a drawing again, in a browser tab, and checking that it still behaves the way your circuit
did. In DD101 you drew a circuit and clicked its inputs to watch it work. Here you hand your text
to a real synthesizer, it gives you back a clickable schematic, and you click its inputs until you
have found all eight rows of your truth table. If the picture that comes back is your picture,
nothing was lost when you transcribed it. You'll do this in
[Lab 01, Part 5](../labs/lab-01-transcribe-your-adder-overview.md).

## DigitalJS Online

**<https://digitaljs.tilk.eu/>** is a demonstration app for **DigitalJS**, a simulator by Marek
Materzok at the University of Wrocław. It runs Yosys, the same synthesizer you use in the
workbench, compiled to WebAssembly so that the whole thing happens inside your browser. Nothing is
uploaded, and there is no account to sign up for.

To use it, you create a `.sv` file on its **Setup** tab, paste your module into it and press
**Run**. Lab 01 lists the exact clicks, and the default settings the course was written against.

## What comes back

For your five-`assign` full adder, DigitalJS draws five gates (two Xor, two And and one Or)
arranged from left to right, with the two Xors on the path to `sum` and the And, And and Or on the
path to `cout`. That's your drawing: the same five gates in the same two chains, because those
five gates are the five `assign` lines you typed, and those lines are the five wires you drew.

Around the gates are your ports and the wires between them:

- Three boxes on the left, labelled `a`, `b` and `cin`, are buttons. Click one and it flips
  between `0` and `1`, like an Input element in CircuitVerse.
- Two boxes on the right, labelled `sum` and `cout`, are lamps. They show what your circuit is
  producing right now.
- Wires change colour. A wire carrying `1` turns green, a wire carrying `0` turns salmon red, and
  a wire nobody has driven yet stays grey. Hover over any wire to see its current value,
  including the wires in the middle that you named `ha1_sum` and `ha1_carry`.

Your ports became buttons and lamps because of a rule DigitalJS applies to top-level ports, and
one part of it can surprise you later. A 1-bit top-level input is drawn as a clickable button,
and a wider one as a number-entry box; a 1-bit output becomes a lamp, and a wider one a number
display. The exception is an input named exactly `clk` or `clock`, which isn't drawn as a button
at all. DigitalJS silently turns it into a clock source that ticks on its own, which is helpful
until the day you name something `clock` and can't work out why it won't stop changing.

When you click `a`, `b` and `cin` through all eight combinations, you get your truth table from
DD101. You didn't draw this circuit: a tool generated it from the text you typed, and that tool
has never seen your drawing on paper.

You have now seen one design in four forms: a drawing, a truth table, a text file and a
machine-generated schematic, and all four agree. That's what we mean by "the design": the
behaviour that all four describe, rather than the file or the picture. Every tool you use from
here on translates between two of those forms, and the industry can trust a hundred such translations in
a row because each one can be checked the way you checked this one.

## The same picture from the workbench

The browser isn't doing anything special, and you can get the same picture from Yosys in the
workbench. Below is the list of commands DigitalJS runs, copied from its converter's source with
every checkbox left at its default. The course ships it as
[`scripts/digitaljs.ys`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/scripts/digitaljs.ys):

```
read_verilog -sv src/full_adder.sv
setattr -mod -unset top
hierarchy -auto-top
proc
opt_clean
memory -nomap
wreduce -memx
opt_clean
stat
show -format svg -prefix results/full_adder_rtl -notitle
```

Its `stat` command reports `5 cells`, two `$and`, one `$or` and two `$xor`, which are the same
five gates, counted by the same Yosys and printed as numbers instead of drawn as a picture. The
SVG it writes looks like this:

![The full adder as Yosys draws it: five gates, with the wire names you typed](../assets/img/full-adder-rtl.svg)

Look at the labels on the wires in the middle. `ha1_sum`, `ha1_carry` and `ha2_carry` are the
names you made up in [From your drawing to a module](../guide/from-your-drawing-to-a-module.md),
and they are still there after a trip through a synthesizer. That's why it's worth naming your
wires well: those names are what make the output of these tools readable. You can run this script
yourself in Lab 01, under Going further.

## Four things that would otherwise confuse you

First, the `case` version comes back as one box rather than as gates. If you paste
`full_adder_table.sv` (the `always_comb` + `case` version), you get a single rectangle labelled
**Memory**, with an address input and no gates. You haven't done anything wrong, and the circuit
isn't different. Yosys recognised eight rows indexed by a 3-bit value as a lookup table and drew
it as one, because at this stage nothing has asked it to build anything out of gates yet. Sent
all the way to a real cell library, the same file is still two cells and 33.7824 µm², as the
previous page showed. A schematic viewer shows you how you wrote a design, and only a synthesizer
with a cell library tells you what it costs, so don't quote one when you were asked for the other.

Second, don't carry a cell count out of the browser. DigitalJS builds its Yosys from a package
that isn't version-pinned, so the copy in your tab today may differ from the workbench's, and it
can change from one week to the next. It also has no cell library at all (a browser can't reach
`sky130_fd_sc_hd__tt_025C_1v80.lib`), so it stops at generic gates with names like `$and` and can
never print an area. Your adder is five generic gates in the browser and two sky130 cells,
33.7824 µm², in the workbench. Both numbers are correct, because they answer different
questions, and DD103 is the course about the second one.

Third, the synthesis checkboxes look as if they would show you the real chip, but all they
change is which generic gates you see. Under *Circuit synthesis*, ticking **Convert to logic
gates** renames your five gates from `$and`/`$or`/`$xor` to `$_AND_`/`$_OR_`/`$_XOR_`, which is
Yosys's internal spelling for the same gates. If you also tick **Map into subset of gates** and leave its default set, you get:

```
        5 cells
        3   $_NAND_
        2   $_XOR_
```

That's three NANDs and two XORs. A tool has rebuilt your Or and both your Ands out of NAND, for
the same reason you built them from NAND by hand in
[DD101 Lab 02](https://uoftasic.com/dd101/labs/lab-02-gates-from-one-gate-overview.html). It still
isn't an area, though, and it still isn't what a factory would build.

Last, a design that uses another module needs that module's file as well.
`full_adder_hier.sv` won't run on its own, because it instantiates `half_adder` and DigitalJS has
never heard of it. If you add `half_adder.sv` as a second file, the two compile together and you
get the hierarchical view, with `half_adder` drawn as a single box, twice. Each box has a
magnifier that takes you down into it to show the Xor and the And inside. It's the same gesture as
opening a subcircuit in CircuitVerse, and what you're looking at is a picture of the module
boundaries from [Modules and instances](../guide/what-a-module-is.md).

## Sharing a circuit

Once a circuit is on screen, DigitalJS can save it as JSON or turn what you're looking at into a
link. When you ask for help in the [Discord](https://discord.gg/hrJnP5UsGz), post the link rather
than a screenshot of the schematic, so that whoever answers can click your inputs themselves.

## Check yourself

1. DigitalJS draws your `case` version as one Memory box and the workbench prices it at two
   cells. Which of those tells you what the circuit costs, and why?
2. Why does a cell count from DigitalJS not match one from the workbench, and why is neither
   wrong?
3. You name an input `clock`. What will DigitalJS do with it?

Next on the [Course path](../index.md#course-path): do
[Lab 01: Transcribe your adder](../labs/lab-01-transcribe-your-adder-overview.md).
