# Testbenches

In DD101 you knew your adder worked because you clicked eight combinations of switches and read
eight answers off the screen. That was a real proof, and it worked because there were only eight
things to click. Your adder is text now, and there is nothing to click. This page is about the
thing that clicks for you.

## Testbenches you have already used

When you finished a nandgame level in DD101 and it went green, something ran your diagram against a list
of inputs and expected outputs and decided you were done. You never wrote that list and never saw
it, but it existed, and it is the only reason the level could go green without a person looking.

That is a **testbench**. It isn't a new idea or a new language. It is what was already checking
your work in DD101, with the lid off.

## What a testbench is

A testbench is a second circuit whose job is to doubt the first:

- It is a `module`, like your adder.
- It has no inputs and no outputs. Nothing connects to it.
- Inside, it creates one copy of your module, drives the wires going in, waits, looks at the
  wires coming out, and complains when they aren't what it expected.
- It is never built: no FPGA, no chip, no gates. It exists only inside the simulator, and the
  parts of it that couldn't be hardware (printing text, waiting ten nanoseconds, counting errors
  in an `int`) are the parts that make it useful.

That last point trips people up. Everything so far has been about SystemVerilog describing
hardware, and about `assign` being a wire rather than an instruction. A testbench is the one place
in this course where that isn't true. It is a program pretending to be the outside world, and
nothing in it has to be buildable.

## Reading the eight-row testbench

An excerpt of
[`labs/guide-examples-proving-it/src/tb_eight_rows.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_eight_rows.sv)
(the complete file is in the package and runs as shipped):

```systemverilog
module tb_eight_rows;

    logic a, b, cin;        // we drive these
    logic sum, cout;        // the adder drives these

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    logic [1:0] expected [0:7];   // your DD101 truth table, as {cout, sum}
    ...
        expected[0] = 2'b00;    // a=0 b=0 cin=0  ->  0
        expected[1] = 2'b01;    // a=0 b=0 cin=1  ->  1
    ...
        for (int row = 0; row < 8; row = row + 1) begin
            {a, b, cin} = row[2:0];     // 0,1,2 ... 7 in binary IS the input list
            #10;                         // let this row settle before looking at it
            mismatch = ({cout, sum} !== expected[row]);
            ...
        end
```

Four things in it are worth stopping on.

`full_adder dut (...)` is an instance, the same idea as placing two `half_adder`s inside
`full_adder_hier` in [Modules and instances](guide/what-a-module-is.md). `dut` stands for device under test, and it is what everybody calls it. The testbench
doesn't know or care what is inside `full_adder`; it only knows the five port names.

`{a, b, cin} = row[2:0]` is the whole input generator. Counting 0 to 7 in binary is the eight rows
of your truth table, in the order your DD101 sheet already has them.

`logic [1:0] expected [0:7]` is an array: eight entries, numbered 0 to 7, each a 2-bit
`{cout, sum}`. The `for` loop is ordinary program code, which a testbench is allowed to use. And
`!==` compares including `x` and `z`: `!=` returns `x` when either side is `x`, and an `if` on `x`
does nothing, while `!==` returns a plain 0 or 1, which is what a check needs.

`#10` means wait ten nanoseconds of simulated time. It costs no real time; the simulator just
moves its clock forward. The full file has two of them in each pass of the loop: one after setting
the inputs and before the check (the one shown above), and one after the check. So each row takes
20 ns, and the eight rows end at 160 ns.

The waits have to be there. Delete them and every row fails:

```
tb_eight_rows: all 8 inputs of full_adder
  a b cin | cout sum | want
  --------+----------+-----
  0 0  0  |   x   x  |  0 0   MISMATCH
  0 0  1  |   x   x  |  0 1   MISMATCH
```

`x` isn't a wrong answer; it is no answer yet. The testbench set the inputs and read the outputs
in the same instant, before the `assign` statements had a turn to run, and the wait is what gives
them that turn.

Be careful about why, because the obvious reading is wrong. It is tempting to think the gates
need ten nanoseconds to settle. They don't. Change the waits to `#0`, a wait of zero nanoseconds,
and all eight rows still pass:

```
TESTED 8
ERRORS 0
VERDICT PASS
tb_eight_rows.sv:66: $finish called at 0 (1ps)
```

The whole test finished at time zero. Settling a chain of `assign` statements costs no simulated
time; `#0` tells the simulator to finish everything scheduled for now before carrying on, and that
is all that was ever needed. The testbench uses `#10` for the waveform you open in Lab 03: `#0`
would stack all eight rows on top of each other at t = 0, and the waits spread them into eight
evenly spaced columns you can point at.

Hold on to this. A number in a delay doesn't buy time for logic to work. In DD103 you'll watch a
synthesizer throw a delay like `#5` away without a warning, because no gate's job is to be late. Real delay is
something you measure afterwards, in Lab 05.

You compile and run this testbench yourself in
[Lab 02, Part 1](labs/lab-02-prove-it-overview.md).

## Exhaustive testing of a full adder

A full adder has three inputs, so it has $2^3 = 8$ possible input combinations. There is no fourth input
hiding anywhere, no memory, no clock, nothing that depends on what happened before. So those
eight rows aren't a test in the sense of "we tried some things and they worked". They are the
adder's entire behaviour, written down, and there is nothing left to try. Almost nothing you build
after this has that property.

## Exit code and verdict

`vvp` is the program that runs a compiled simulation (`iverilog` compiles it first). Run the
eight-row testbench against a full adder with one wrong gate and it prints `VERDICT FAIL`, and
`vvp` still exits 0. The simulator did what it was asked: it simulated a circuit, and the circuit was wrong.
Simulating a wrong circuit isn't a failure of the simulator, so `vvp` exits 0 whether your design
is right or wrong.

Read the `VERDICT` line, never the exit code. If something automated has to decide, make it read
the text. That is what
[`src/check_sim.py`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/check_sim.py)
does: it finds `TESTED`, `ERRORS` and `VERDICT` in the log, compares them with the reference
numbers stored in the checker, and never looks at an exit code. That is why `make` in
`labs/guide-examples-proving-it/` can tell you that you failed. It is the first of several places
in the DD courses where a green light means nothing, and DD103 has a whole page of them. You check this yourself in Lab 02, Part 2.

## Hand-picked cases and every case

A full adder has three input bits and eight combinations, so you can test it completely. Four of
them chained into a 4-bit adder have nine input bits (`a[3:0]`, `b[3:0]` and `cin`), which is
$2^9 = 512$ combinations: sixty-four times as many, and still, just, all of them.

With 512 inputs, people pick a few cases that feel representative and stop. In
[Lab 03](labs/lab-03-the-lazy-testbench-overview.md) you run six such cases against a broken
4-bit adder. They pass. Then you run all 512. Three habits come out of that lab, and they apply to
every test you write:

1. A testbench that never sets an input to 1 hasn't tested that input. Before you believe a
   `PASS`, read the input list and ask which inputs actually moved.
2. When the mismatch count is exactly half the vectors, the bug is structural, not a rare corner
   case: a bug that fired on random inputs would give a scattered number. Exactly half means the
   damage tracks something that is true on exactly half of all inputs. A single input bit is the
   simplest such thing, but not the only one: the carry out of a 4-bit adder is also 1 on exactly
   half of its 512 inputs. So the count alone doesn't tell you which; a breakdown of the failures
   by input does. Count first, then break the count down, then read the RTL (the design's source
   file). Lab 03 has one bug of each kind, and both give the same count.
3. Lint before you believe a `PASS`, and never instead of running the test. A linter, such as the
   `verilator --lint-only -Wall` you ran in Lab 01, reads your file without simulating it and
   warns about its shape: an unused input, an undriven output, a width that doesn't match. That is
   free information. A clean lint says nothing about whether your circuit is right: a module can be
   well formed and still describe the wrong circuit. Only the truth table knows.

## Where exhaustive testing stops

Testing a design completely, in a fraction of a second, is something you'll spend most of your
career unable to do.

An 8-bit version of the same adder has seventeen inputs, so $2^{17} = 131{,}072$ vectors. The
whole sweep takes about six tenths of a second on the workbench (repeated runs landed between 0.59
and 0.63 s), or about 4.5 µs per vector. With that rate the rest is arithmetic:

| Design | Inputs | Vectors | At 4.5 µs each |
|---|---|---|---|
| one full adder | 3 | 8 | instant |
| your 4-bit adder | 9 | 512 | instant |
| the 8-bit adder | 17 | 131,072 | 0.6 s, measured |
| a 16-bit adder | 33 | 8,589,934,592 | about 11 hours |
| a 32-bit adder | 65 | 36,893,488,147,419,103,232 | about 5.3 million years |

The counts are exact, and the two "instant" rows and the 0.6 s row were measured on
`hpretl/iic-osic-tools:2026.08`. The last two rows are arithmetic from the measured rate, so treat
them as the right order of magnitude rather than a stopwatch reading.

Each vector takes longer as the adder gets wider, because it drives more wires. The 4.5 µs
was measured at 8 bits. [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md) measures it again
at 12 bits, gets 7.9 µs, and so puts the 16-bit row at about 19 hours rather than 11. Neither is
wrong and neither is a stopwatch reading; both say "overnight", which is the answer that changes
what you do.

Somewhere between 8 and 16 bits, exhaustive testing stops being something you do while the kettle
boils. And a 32-bit adder is a small, ordinary combinational block: no memory, no state machine.
Add one flip-flop and the input space stops being a number at all, because the answer now depends
on what happened before. That is why DD104 exists. Everything in it (constrained random stimulus,
coverage, assertions, `cocotb`) answers the question "what do you do when you can't try
everything?" You can skip that question for as long as your designs stay this small.

## Where you do this

- [Lab 02: Prove it](labs/lab-02-prove-it-overview.md) runs this page's eight-row testbench, then
  gives you a testbench with one of your eight rows filled in and three deliberately broken
  ("mutant") adders for it to catch. The seven missing rows are the lab.
- [Lab 03: The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md) runs hand-picked cases
  and then all 512 inputs against broken 4-bit adders, and times the 8-bit sweep.

## Check yourself

1. Why does the testbench need `#10` (or `#0`) between setting the inputs and reading the outputs,
   if the gates don't need time to settle?
2. A broken adder fails four of eight rows and `vvp` exits 0. Why?
3. A sweep of 512 inputs reports 256 errors. What does "exactly half" suggest, and what do you run
   next?
4. `verilator --lint-only -Wall` reports nothing on your file. What does that tell you about
   whether it is correct?

Next on the [Course path](README.md#course-path): do
[Lab 02: Prove it](labs/lab-02-prove-it-overview.md).
