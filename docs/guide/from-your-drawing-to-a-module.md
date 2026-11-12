# From your drawing to a module

This page turns your DD101 full-adder drawing into a SystemVerilog file, one piece at a time:
the labels on its edge, then the wires inside. You type your own version in
[Lab 01](labs/lab-01-transcribe-your-adder-overview.md); keep the drawing from
[DD101 Lab 04](https://uoftasic.com/dd101/#/labs/lab-04-full-adder) (three blocks, seven wires,
eight rows of a truth table) next to you while you read.

The whole course rests on one idea: you type the drawing out. You don't upload it, convert it or
export it.

## The port list

Look at what crosses the edge of your drawing: three arrows going in, two coming out.

| On your paper | What it is |
|---|---|
| `a` | input |
| `b` | input |
| `cin` | input |
| `sum` | output |
| `cout` | output |

That list is the first thing you write:

```systemverilog
module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

endmodule
```

This is a complete, legal file. Saved as `full_adder.sv`, Icarus Verilog compiles it with exit
status 0 and no output at all. It just doesn't do anything yet: the module has an edge with five
holes in it, and the middle is empty.

> `logic` is the type of a wire that carries one of four values: `0`, `1`, `x` ("nobody has
> said") and `z` ("disconnected"). Everything you write in this course is `logic`. You'll see a
> second type, `wire`, in other people's code; you don't need it and this course never uses it.

The port list is a contract. Once it is written, someone else can wire your box into a bigger
design without knowing what is inside it. That is what happens to this file in Lab 04, where four
copies of it become a 4-bit adder, so the names and directions are the part other people depend
on.

## What an empty module does

Simulate the empty module against the eight rows and every output is `x`:

```
a b cin | cout sum
0 0  0  |  x    x
0 0  1  |  x    x
0 1  0  |  x    x
0 1  1  |  x    x
1 0  0  |  x    x
1 0  1  |  x    x
1 1  0  |  x    x
1 1  1  |  x    x
```

This is the most common thing a first SystemVerilog file does, so read it correctly. `x` doesn't
mean "wrong answer". It means nobody drove this wire: the output exists, no `assign` anywhere in
the file says what it should be, and the simulator won't guess. A column of `x` on an output is a
missing line, not a logic bug. Look for the `assign` that should be there and isn't. You'll see
this table when you first run Lab 01.

## One `assign` per wire

Now fill in the middle by walking your drawing from left to right and writing down each wire as
you meet it.

Your drawing has two wires nobody has named yet, the ones between the two half adders, plus the
carry out of the second one. Name them, because you can't write down a wire you can't say:

```systemverilog
    logic ha1_sum, ha1_carry, ha2_carry;
```

Then write one line per wire:

```systemverilog
    assign ha1_sum   = a ^ b;              // first half adder, sum
    assign ha1_carry = a & b;              // first half adder, carry
    assign sum       = ha1_sum ^ cin;      // second half adder, sum
    assign ha2_carry = ha1_sum & cin;      // second half adder, carry
    assign cout      = ha1_carry | ha2_carry;   // the Or gate
```

Five wires on the drawing that weren't named before, five `assign` lines. Read them against your
paper one at a time. `^` is Xor, `&` is And and `|` is Or, the same three gates you built out of
NANDs in DD101 Lab 02.

The complete file is
[`labs/guide-examples/src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder.sv).
It is 21 lines including comments, and it is the two blocks above joined together.

## Checking it against your eight rows

The lab packages ship a testbench, so you don't have to write one yet. It knows the eight rows of
the full-adder truth table (the same eight you filled in by hand), drives them at your module one
at a time, and prints `PASS - all 8 rows match your DD101 table.` when they all agree. Two things
in its output are worth knowing about in advance.

The compile command is `iverilog -g2012`. The `-g2012` selects the SystemVerilog dialect. Leave it
off and you get five errors that look nothing like the real problem, starting with:

```
src/full_adder.sv:16: error: Variable 'ha1_sum' cannot be driven by a continuous assignment/module.
src/full_adder.sv:16:      : This is allowed when SystemVerilog is enabled.
```

Read the second line: Icarus is telling you the fix. This is the friendliest error message in the
toolchain, and the next tool won't be this kind.

The last line of a successful run is `$finish called at 8000 (1ps)`. That is the simulator
reaching the end of the testbench after 8 ns of simulated time, one nanosecond per row. It appears
at the end of every successful run in this course and isn't a warning.

## Reading a failure

[`broken/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/broken/full_adder.sv)
is `src/full_adder.sv` with one character changed: the `|` on the last line is an `&`, the
mistake your eye makes between two similar symbols. Run against the eight rows, the first three
rows pass and four of the eight fail. Somebody testing by hand in a hurry tries `000`, `001` and
`010`, sees three passes, and ships a design that is half wrong. That is why the testbench walks
all eight and prints a verdict, and why this course never asks you to eyeball a waveform for
correctness when a machine can count for you.

The simulator finds those four wrong rows and still exits 0. "The simulation ran" and "the design
is correct" are different questions, and `vvp` only answers the first. Never trust a simulator's
exit status; trust a line of output you told it to print. The `guide-examples` Makefile decides
pass or fail with `grep -q "^PASS"`, and that one line is what makes `make` a test rather than a
light show.

You produce this failure yourself in Lab 01, Part 6.

## Two mistakes worth making once

Both files are in
[`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors),
complete and runnable. You run them in Lab 01, Part 6.

Two `assign`s aimed at the same output. In Python the second line would win. Here:

```
errors/two_drivers.sv:10: error: Variable 'sum' cannot have multiple drivers.
1 error(s) during elaboration.
```

Both lines are solder joints, and both are attached. The tool isn't being fussy; it can't build
that. One output gets one `assign`, whichever style you write in, as
[`assign` and `always_comb`](guide/assign-and-always-comb.md) shows from the other direction.

Forgetting to declare an internal wire. `errors/undeclared_wire.sv` is your file with the
`logic ha1_sum, ha1_carry, ha2_carry;` line deleted. Icarus compiles it with exit 0 and says
nothing. Yosys says:

```
errors/undeclared_wire.sv:13: Warning: Identifier `\ha1_sum' is implicitly declared.
errors/undeclared_wire.sv:14: Warning: Identifier `\ha1_carry' is implicitly declared.
errors/undeclared_wire.sv:16: Warning: Identifier `\ha2_carry' is implicitly declared.
```

The design still works, because a name used on the left of an `assign` gets invented as a 1-bit
wire. It keeps working until the wire you meant was 4 bits wide, and then 3 of your bits quietly
vanish and nothing errors. If a synthesis log says `implicitly declared`, you have a typo or a
missing declaration; find it while the design is small.

## What it costs

Sent to a synthesizer with the sky130 standard-cell library, your five `assign`s become two
standard cells with an area of 33.7824 µm². As a square, that is about 5.8 µm on a side, roughly
a tenth the width of a human hair.

You drew five gates, and the tool chose two. The tool that made that decision is called a
**synthesizer**, and DD103 is the course about what it did and why. For now, remember the number
33.7824 µm²; you'll meet it again on the next two pages, and you measure it in Lab 01, Part 7.

## Check yourself

1. Your simulation prints `x` for `cout` on every row. What kind of mistake do you look for?
2. Why does a testbench print a `PASS` or `FAIL` line rather than relying on `vvp`'s exit status?
3. You delete the `logic ha1_sum, ...;` line and the design still passes. Why is that not a
   reason to leave it out?

Next: [Modules and instances](guide/what-a-module-is.md).
