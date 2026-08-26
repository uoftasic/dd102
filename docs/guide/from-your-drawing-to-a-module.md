# From your drawing to a module

**Question this page answers:** *I have a circuit on a piece of paper. How do I turn it
into something a computer can build?*

Get the sheet out. The one from
[DD101 Lab 04](https://uoftasic.com/dd101/#/labs/lab-04-full-adder) — three blocks, seven
wires, eight rows of a truth table, in your handwriting. Put it next to the keyboard.

You are about to type that drawing out. Not upload it, not convert it, not export it.
**Type it.** That is the whole course in one sentence, and this page is where it happens.

By the end of this page you will have a file that a simulator agrees with on all eight of
your rows. Every command below has been run; every number and every error message on this
page is copied from a real terminal.

## The five labels on your paper are the port list

Look at what crosses the edge of your drawing. Three arrows going in, two coming out:

| on your paper | what it is |
|---|---|
| `a` | input |
| `b` | input |
| `cin` | input |
| `sum` | output |
| `cout` | output |

That list, and nothing else, is the first thing you write:

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

**That is a complete, legal file.** Save it as `full_adder.sv` and Icarus Verilog compiles
it without complaint — exit status 0, not one word of output. It just does not do anything
yet. Your module has an edge and five holes in the edge, and the middle is empty.

> `logic` is the type of a wire that carries one of four values: `0`, `1`, `x`
> ("nobody has said"), and `z` ("disconnected"). For now, everything you write is
> `logic`. There is a second type, `wire`, that you will meet in other people's code; you
> do not need it and this course never uses it.

**Why an engineer cares.** The port list is a contract. Once it is written, someone else
can wire your box into a bigger design without knowing or caring what is inside it — which
is precisely what happens to this file in Lab 04, the four-adder lab,
where four copies of it become a 4-bit adder. Getting the names and directions right is the part other people depend on.

## What an empty module does when you simulate it

Run the shipped stub in [Lab 01](labs/lab-01-transcribe-your-adder.md) — the package is
[`labs/lab-01-transcribe-your-adder/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-01-transcribe-your-adder)
— and here is your reward:

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

Eight rows of `x`. This is the single most common thing a first SystemVerilog file does,
and it is worth reading correctly:

> **`x` does not mean "wrong answer". It means *nobody drove this wire*.** The output
> exists, and no `assign` anywhere in the file says what it should be, so the simulator
> refuses to guess.

**The reflex:** a column of `x` on an output is not a logic bug. It is a *missing line*.
Go and look for the `assign` that should be there and is not.

## One `assign` per wire, following the drawing

Now fill in the middle. Walk your drawing from left to right and write down each wire as
you meet it.

Your drawing has two wires nobody has named yet — the ones running between the two half
adders — plus the carry coming out of the second one. Name them, because you cannot write
down a wire you cannot say:

```systemverilog
    logic ha1_sum, ha1_carry, ha2_carry;
```

Then, one line per wire:

```systemverilog
    assign ha1_sum   = a ^ b;              // first half adder, sum
    assign ha1_carry = a & b;              // first half adder, carry
    assign sum       = ha1_sum ^ cin;      // second half adder, sum
    assign ha2_carry = ha1_sum & cin;      // second half adder, carry
    assign cout      = ha1_carry | ha2_carry;   // the Or gate
```

Five wires on the drawing that were not there before; five `assign` lines. Read them
against your paper one at a time. `^` is Xor, `&` is And, `|` is Or — the same three gates
you built out of NANDs in DD101 Lab 02.

The complete file is
[`labs/guide-examples/src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder.sv).
It is 21 lines including the comments, and it is exactly the two blocks above, joined.

## Run it against your own eight rows

The lab package ships a testbench so that you do not have to write one yet. It knows the
eight rows of the full-adder truth table — the same eight you filled in by hand — and it
drives them at your module one at a time.

```bash
cd labs/guide-examples
make sim
```

```
==============================================================
 1. YOUR ADDER AGAINST YOUR OWN TRUTH TABLE
==============================================================
iverilog -g2012 -o results/sim.vvp src/tb_full_adder.sv src/full_adder.sv

  a b cin | cout sum
  --------+---------
  0 0  0  |   0   0   ok
  0 0  1  |   0   1   ok
  0 1  0  |   0   1   ok
  0 1  1  |   1   0   ok
  1 0  0  |   0   1   ok
  1 0  1  |   1   0   ok
  1 1  0  |   1   0   ok
  1 1  1  |   1   1   ok

PASS - all 8 rows match your DD101 table.

src/tb_full_adder.sv:46: $finish called at 8000 (1ps)
```

**Two things to name before they worry you.**

`iverilog -g2012` — the `-g2012` selects the SystemVerilog dialect. Leave it off and you
get five errors that look nothing like the real problem:

```
src/full_adder.sv:16: error: Variable 'ha1_sum' cannot be driven by a continuous assignment/module.
src/full_adder.sv:16:      : This is allowed when SystemVerilog is enabled.
```

Read the **second** line. Icarus is telling you the fix. (This is the friendliest error
message in the whole toolchain; enjoy it, because the next tool will not be this kind.)

`$finish called at 8000 (1ps)` — that is the simulator saying it reached the end of the
testbench after 8 nanoseconds of pretend time, one nanosecond per row. It is the normal
last line of every successful run in this course. It is not a warning.

## Now break it on purpose

Nobody learns to read a `FAIL` from a page that only ever passes. `broken/full_adder.sv`
is `src/full_adder.sv` with exactly one character changed — the `|` on the last line is an
`&`, the mistake you make when your eye slips between two similar symbols:

```bash
make broken
```

```
  a b cin | cout sum
  --------+---------
  0 0  0  |   0   0   ok
  0 0  1  |   0   1   ok
  0 1  0  |   0   1   ok
  0 1  1  |   0   0   WRONG - expected cout=1 sum=0
  1 0  0  |   0   1   ok
  1 0  1  |   0   0   WRONG - expected cout=1 sum=0
  1 1  0  |   0   0   WRONG - expected cout=1 sum=0
  1 1  1  |   0   1   WRONG - expected cout=1 sum=1

FAIL - 4 of 8 rows disagree.
```

Look at the first three rows. They pass. A person testing this by hand, in a hurry, tries
`000`, `001`, `010`, sees three greens, and ships it. **Half of this design is wrong and
the first three rows say nothing about it.** That is why the testbench walks all eight and
prints a verdict, and it is why the rest of this course never asks you to eyeball a
waveform for correctness when a machine can count for you.

And now the part that matters more:

```
    vvp exited 0. Yes. Zero.
```

The simulator found four wrong rows and still exited successfully, because "the simulation
ran" and "the design is correct" are different questions and `vvp` only answers the first.

> **The reflex:** never trust a simulator's exit status. Trust a line of output you told
> it to print. The lab's `Makefile` does exactly that — `grep -q "^PASS"` — and that one
> line is the difference between a test suite and a light show.

## Two mistakes that are worth making once

Both files are in
[`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors),
complete and runnable. `make errors` runs all of them.

**Two `assign`s aimed at the same output.** In Python the second line wins. Here:

```
errors/two_drivers.sv:10: error: Variable 'sum' cannot have multiple drivers.
1 error(s) during elaboration.
```

Both lines are solder joints, and they are both attached. The tool is not being fussy —
it genuinely cannot build that. **One output, one `assign`** — and that rule holds no
matter which style you write in, as [Everything happens at
once](guide/assign-and-always-comb.md) will show you from the other direction.

**Forgetting to declare an internal wire.** `errors/undeclared_wire.sv` is your file with
the `logic ha1_sum, ha1_carry, ha2_carry;` line deleted. Icarus compiles it, exit 0, in
silence. Yosys, later, says:

```
errors/undeclared_wire.sv:13: Warning: Identifier `\ha1_sum' is implicitly declared.
errors/undeclared_wire.sv:14: Warning: Identifier `\ha1_carry' is implicitly declared.
errors/undeclared_wire.sv:16: Warning: Identifier `\ha2_carry' is implicitly declared.
```

Your design still works — a name used on the left of an `assign` gets invented as a 1-bit
wire. It works *until* the wire you meant was 4 bits wide, at which point 3 of your bits
quietly vanish and nothing errors.

> **The reflex:** if a synthesis log says `implicitly declared`, you have a typo or a
> missing declaration. Go and find it now, while the design is small enough to find it in.

## What it costs, since you asked

You now have a file. Here is what it becomes if you send it to a chip factory:

```bash
make area
```

```
---- 1. drawing - five assigns, one per wire on your paper
   Chip area for module '\full_adder': 33.782400
```

**Two standard cells. 33.7824 square micrometres.** If it were a square it would be about
5.8 µm on a side — call it a tenth the width of a human hair.

You did not draw two gates; you drew five. The tool that made that decision is called a
**synthesizer**, and DD103 is the entire course about what it did and why. For now, one
number is enough to hold on to: your adder is **33.7824 µm²**, and you will meet that
number again.

## What you have

- `full_adder.sv`: a port list copied off your paper, three internal wires, five `assign`s
- A `PASS` on all eight rows of the table *you* filled in
- A `FAIL` you produced deliberately, and the habit of reading the verdict line instead of
  the exit status
- One number: **33.7824 µm²**

Next: [What a module actually is](guide/what-a-module-is.md) —
because you have been calling it a "box" this whole page, and it is worth being precise
about how much that word is doing.
