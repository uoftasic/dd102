# Seeing your adder as a schematic

You turned a drawing into text. This page is about turning the text back into a drawing, in a
browser tab, and checking that it still behaves. In DD101 you drew a circuit and clicked its
inputs to watch it work. Here you hand your text to a real synthesizer, get a clickable schematic
back, click its inputs, and find your eight rows. If the picture that comes back is your picture,
nothing was lost in the transcription. You do this in
[Lab 01, Part 5](labs/lab-01-transcribe-your-adder-overview.md).

## DigitalJS Online

**<https://digitaljs.tilk.eu/>** is a demonstration app for **DigitalJS**, a simulator by Marek
Materzok at the University of Wrocław. It runs Yosys, the same synthesizer you use in the
workbench, compiled to WebAssembly inside your browser. Nothing is uploaded and there is nothing
to sign up for.

You create a `.sv` file on its **Setup** tab, paste your module in and press **Run**. Lab 01 lists
the clicks and the default settings the course is written against.

## What comes back

For your five-`assign` full adder: five gates, two Xor, two And and one Or, arranged left to
right, with the two Xors on the path to `sum` and the And/And/Or on the path to `cout`. That is
your drawing, the same five gates in the same two chains, because those five gates are the five
`assign` lines you typed, which are the five wires you drew.

Around them:

- Three boxes on the left, labelled `a`, `b` and `cin`, are buttons. Click one and it flips
  between `0` and `1`, like an Input element in CircuitVerse.
- Two boxes on the right, labelled `sum` and `cout`, are lamps. They show what your circuit is
  producing right now.
- Wires change colour. A wire carrying `1` turns green, a wire carrying `0` turns salmon red, and
  a wire nobody has driven yet stays grey. Hover over any wire to see its current value,
  including the wires in the middle that you named `ha1_sum` and `ha1_carry`.

Your ports became buttons and lamps because of a rule that can surprise you later: a 1-bit
top-level input is drawn as a clickable button and a wider one as a number-entry box; a 1-bit
output becomes a lamp and a wider one a number display. An input named exactly `clk` or `clock`
isn't drawn as a button at all. It silently becomes a clock source that ticks on its own, which
is helpful until the day you name something `clock` and can't work out why it won't stop
changing.

Clicking `a`, `b` and `cin` through all eight combinations gives your table from DD101, off a
circuit you didn't draw, generated from text you typed, by a tool that has never seen your paper.

You have now seen one design in four forms: a drawing, a truth table, a text file and a
machine-generated schematic, and all four agree. That is what "the design" means: not the file
and not the picture, but the behaviour they all describe. Every tool you use from here on
translates between two of those forms, and the industry can trust a hundred such translations in
a row because each one can be checked the way you checked this one.

## The same picture from the workbench

The browser isn't doing anything special. This is the command list DigitalJS runs, copied from
its converter's source with every checkbox at its default, and it ships as
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

Its `stat` reports `5 cells`: two `$and`, one `$or` and two `$xor`, the same five gates counted
by the same Yosys and printed as numbers instead of a picture. The SVG it writes looks like this:

![The full adder as Yosys draws it: five gates, with the wire names you typed](../assets/img/full-adder-rtl.svg)

Look at the labels on the wires in the middle: `ha1_sum`, `ha1_carry`, `ha2_carry`, the names you
made up in [From your drawing to a module](guide/from-your-drawing-to-a-module.md), still there
after a synthesizer. Naming your wires well is what
makes the output of these tools readable. You can run this script in Lab 01, under Going further.

## Four things that would otherwise confuse you

The `case` version comes back as one box, not gates. Paste `full_adder_table.sv` (the
`always_comb` + `case` version) and you get a single rectangle labelled **Memory**, with an
address input and no gates. You haven't done anything wrong, and the circuit isn't different.
Yosys recognised eight rows indexed by a 3-bit value as a lookup table and drew it as one,
because at this stage it hasn't been asked to build anything out of gates yet. The same file sent
all the way to a real cell library is still two cells and 33.7824 µm², as the previous page
showed. A schematic viewer shows you how you wrote it; only a synthesizer with a cell library
tells you what it costs. Don't quote one when you were asked the other.

Don't carry a cell count out of the browser. DigitalJS builds its Yosys from a package that isn't
version-pinned, so the copy in your tab today may differ from the workbench's, and it can change
from one week to the next. It also has no cell library at all (a browser can't reach
`sky130_fd_sc_hd__tt_025C_1v80.lib`), so it stops at generic gates with names like `$and` and can
never print an area. Your adder is five generic gates in the browser and two sky130 cells,
33.7824 µm², in the workbench. Both numbers are correct; they answer different questions, and
DD103 is the course about the second one.

The checkboxes that look like "show me the real chip" don't do that. Under *Circuit synthesis*,
ticking **Convert to logic gates** renames your five gates from `$and`/`$or`/`$xor` to
`$_AND_`/`$_OR_`/`$_XOR_`, Yosys's internal spelling for the same gates. Also ticking **Map into
subset of gates**, with its default set, gives:

```
        5 cells
        3   $_NAND_
        2   $_XOR_
```

Three NANDs and two XORs: your Or and both your Ands, rebuilt out of NAND by a tool, for the same
reason you built them from NAND by hand in
[DD101 Lab 02](https://uoftasic.com/dd101/#/labs/lab-02-gates-from-one-gate). It still isn't an
area, and it still isn't what a factory would build.

Multi-file designs need a second file. `full_adder_hier.sv` won't run on its own, because it
instantiates `half_adder` and DigitalJS has never heard of it. With `half_adder.sv` added as a
second file, both compile together and you get the hierarchical view: `half_adder` drawn as one
box, twice. A magnifier on each box descends into it to show the Xor and the And inside, the same
gesture as opening a subcircuit in CircuitVerse, and a picture of the module boundaries from
[Modules and instances](guide/what-a-module-is.md).

## Sharing a circuit

Once a circuit is on screen, DigitalJS can save it as JSON or turn what you're looking at into a
link. When you want help in the [Discord](https://discord.gg/hrJnP5UsGz), post the link, not a
screenshot of a schematic, so whoever answers can click your inputs themselves.

## Check yourself

1. DigitalJS draws your `case` version as one Memory box and the workbench prices it at two
   cells. Which of those tells you what the circuit costs, and why?
2. Why does a cell count from DigitalJS not match one from the workbench, and why is neither
   wrong?
3. You name an input `clock`. What will DigitalJS do with it?

Next on the [Course path](README.md#course-path): do
[Lab 01: Transcribe your adder](labs/lab-01-transcribe-your-adder-overview.md).
