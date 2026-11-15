# From your drawing to a module

This page turns your DD101 full-adder drawing into a SystemVerilog file one piece at a time,
starting with the labels on its edge and then moving on to the wires inside it. You'll type your
own version in [Lab 01](../labs/lab-01-transcribe-your-adder-overview.md). While you read, keep
the drawing from
[DD101 Lab 04](https://uoftasic.com/dd101/labs/lab-04-full-adder-overview.html) (three blocks, eight wires,
eight rows of a truth table) next to you.

The whole course rests on one idea, which is that you type the drawing out yourself rather than
uploading, converting or exporting it.

## The port list

Start with what crosses the edge of your drawing: three arrows go in, and two come out.

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

This is already a complete, legal file: if you save it as `full_adder.sv`, Icarus Verilog
compiles it with exit status 0 and prints nothing at all. It doesn't do anything yet, though,
because so far the module is only an edge with five holes in it, and the middle is empty.

> `logic` is the type of a wire that carries one of four values: `0`, `1`, `x` ("nobody has
> said") and `z` ("disconnected"). Everything you write in this course is `logic`. You'll see a
> second type, `wire`, in other people's code, but you don't need it, and this course never
> uses it.

The port list works like a contract: once it's written, someone else can wire your box into a
bigger design without knowing what's inside it. That's what happens to this file in Lab 04, where
four copies of it become a 4-bit adder, so the names and directions in the port list are the part
that other people depend on.

## What an empty module does

If you simulate the empty module against the eight rows, every output is `x`:

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

This is the most common thing a first SystemVerilog file does, so it's worth knowing how to read
it. An `x` doesn't mean the answer is wrong; it means nobody drove the wire. The output exists,
but no `assign` anywhere in the file says what its value should be, and the simulator won't
guess. So a column of `x` on an output points to a missing line rather than to a mistake in your
logic, and what you look for is the `assign` that should be there and isn't. You'll see this
table when you first run Lab 01.

## One `assign` per wire

Now fill in the middle by walking your drawing from left to right and writing down each wire as
you meet it.

Your drawing has three wires that nobody has named yet: the sum and the carry coming out of the
first half adder, and the carry coming out of the second one. Give them names first, because you
can't write down a wire you have no name for:

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

That's five `assign` lines for five wires: the three you just named, plus `sum` and `cout`. Read
them against your paper one at a time. `^` is Xor, `&` is And and `|` is Or, the same three gates
you built out of NANDs in DD101 Lab 02.

The complete file is
[`labs/guide-examples/src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder.sv).
It's 21 lines long including comments, and it's simply the port list from the top of this page
with the `logic` line and the five `assign`s added inside it, before `endmodule`.

## Checking it against your eight rows

The lab packages ship a testbench, so you don't have to write one yet. It knows the eight rows of
the full-adder truth table (the same eight you filled in by hand), drives them at your module one
at a time, and prints `PASS - all 8 rows match your DD101 table.` when they all agree. Two things
about running it are worth knowing in advance.

The compile command is `iverilog -g2012`, where `-g2012` selects the SystemVerilog dialect. If you
leave it off, you get five errors that look nothing like the real problem, starting with:

```
src/full_adder.sv:16: error: Variable 'ha1_sum' cannot be driven by a continuous assignment/module.
src/full_adder.sv:16:      : This is allowed when SystemVerilog is enabled.
```

Read the second line, because that's where Icarus tells you the fix. This is the friendliest error
message in the toolchain, and the next tool won't be this kind to you.

The last line of the run is `$finish called at 8000 (1ps)`. It means the simulator reached the
end of the testbench after 8 ns of simulated time, one nanosecond per row. A line like it ends
every simulation run in this course, whether the run passes or fails, so it isn't a warning.

## Reading a failure

[`broken/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/broken/full_adder.sv)
is `src/full_adder.sv` with one character changed: the `|` on the last line has become an `&`,
which is an easy mistake for your eye to make between two symbols that look alike. When you run
it against the eight rows, the first three rows pass, and four of the eight fail. Somebody
testing by hand in a hurry might try `000`, `001` and `010`, see three passes, and ship a design
that's wrong on half of its rows. That's why the testbench walks through all eight and prints a
verdict, and it's also why this course never asks you to judge correctness by eyeballing a
waveform when a machine can count for you.

The simulator finds those four wrong rows and still exits with status 0. Whether
the simulation ran and whether the design is correct are two different questions, and `vvp` only
answers the first. So never trust a simulator's exit status; trust a line of output that you told
it to print. The `guide-examples` Makefile decides pass or fail with `grep -q "^PASS"`, and that
one line is what makes `make` a test rather than a light show.

You run this broken file yourself in Lab 01, Part 6.

## Two mistakes worth making once

Both files are in
[`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors),
and both are complete and runnable. You run them in Lab 01, Part 6.

The first mistake is writing two `assign`s aimed at the same output. In Python the second line
would simply win, but here you get this:

```
errors/two_drivers.sv:10: error: Variable 'sum' cannot have multiple drivers.
1 error(s) during elaboration.
```

Each `assign` is more like a solder joint than a line of Python, so the two lines attach two
drivers to the same wire at once, and there is no circuit the tool could build from that. One
output gets one `assign`, whichever style you write in, as
[`assign` and `always_comb`](../guide/assign-and-always-comb.md) shows from the other direction.

The second mistake is forgetting to declare an internal wire. `errors/undeclared_wire.sv` is your
file with the `logic ha1_sum, ha1_carry, ha2_carry;` line deleted. Icarus compiles it with exit
status 0 and prints nothing, but Yosys warns you:

```
errors/undeclared_wire.sv:13: Warning: Identifier `\ha1_sum' is implicitly declared.
errors/undeclared_wire.sv:14: Warning: Identifier `\ha1_carry' is implicitly declared.
errors/undeclared_wire.sv:16: Warning: Identifier `\ha2_carry' is implicitly declared.
```

The design still works, because when a name that was never declared is used on the left of an
`assign`, the tool invents a 1-bit wire with that name. Every internal wire in the full adder is
1 bit wide, so here no harm is done. If the wire you meant was 4 bits wide, though, 3 of your
bits would quietly vanish and nothing would report an error. So if a synthesis log says
`implicitly declared`, you have a typo or a missing declaration, and it's worth finding it while
the design is still small.

## What it costs

When you send your file to a **synthesizer** with the sky130 standard-cell library, your five
`assign`s become two standard cells with an area of 33.7824 µm². As a square, that would be about
5.8 µm on a side, roughly a tenth the width of a human hair.

You drew five gates, and the synthesizer (the tool that turns your file into cells) chose to use
two. What it did there and why is the subject of DD103. For now, remember the number 33.7824 µm², because you'll meet it again on
the next two pages, and you'll measure it yourself in Lab 01, Part 7.

## Check yourself

1. Your simulation prints `x` for `cout` on every row. What kind of mistake do you look for?
2. Why does a testbench print a `PASS` or `FAIL` line rather than relying on `vvp`'s exit status?
3. You delete the `logic ha1_sum, ...;` line and the design still passes. Why is that not a
   reason to leave it out?

Next: [Modules and instances](../guide/what-a-module-is.md).
