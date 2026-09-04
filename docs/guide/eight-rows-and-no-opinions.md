# Eight rows and no opinions

**Question this page answers:** *I typed my drawing out and the tool drew it back correctly.
How do I know it actually **works**?*

In DD101 you knew your adder worked because you clicked eight combinations of switches and
read eight answers off the screen. That was a real proof, and it worked because there were
only eight things to click.

Your adder is text now. There is nothing to click.

## You have been writing testbenches since your first afternoon

When you finished a nandgame level and it went green, something ran your diagram against a
list of inputs and expected outputs and decided you were done. You did not write that list
and you never saw it, but it existed, and it is the only reason the level could go green
without a human looking at it.

That is a **testbench**. It is not a new idea and it is not a new language. It is the thing
that was already checking your work in DD101, with the lid off.

## A testbench is a second circuit whose job is doubt

Here is the shape of it, and it is genuinely this simple:

- It is a `module`, like your adder.
- It has **no inputs and no outputs**. Nothing connects to it. It sits alone.
- Inside it, it creates one copy of *your* module, drives the wires going in, waits, looks at
  the wires coming out, and complains when they are not what it expected.
- It is **never built**. No FPGA, no chip, no gates. It exists only inside the simulator, and
  the parts of it that could not possibly be hardware — printing text, waiting ten
  nanoseconds, counting errors in an `int` — are exactly the parts that make it useful.

That last point is the one that trips people. Everything in this course so far has been about
SystemVerilog describing hardware, and about `assign` being a wire rather than an instruction.
A testbench is the one place in this course where that is not true. It is a program that pretends to be
the outside world, and nothing in it has to be buildable.

## The one you are given

**Excerpt** from
[`labs/guide-examples-proving-it/src/tb_eight_rows.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_eight_rows.sv)
— the complete file is in the package and it runs as shipped:

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

Three things in there are worth stopping on.

**`full_adder dut (...)`** is an *instance*, the same idea as putting two half adders inside a
full adder. `dut` stands for Device Under Test and it is what everybody calls it. This
testbench does not know or care what is inside `full_adder`; it only knows the five port names.

**`{a, b, cin} = row[2:0]`** is the whole input generator. Counting 0 to 7 in binary *is* the
eight rows of your truth table, in the order your DD101 sheet already has them.

**`#10`** is the only genuinely new syntax on this page. It means *wait ten nanoseconds of
simulated time*. It costs no real time; the simulator just moves its clock forward.

You need **something** there. Delete the line entirely and every row fails:

```
tb_eight_rows: all 8 inputs of full_adder
  a b cin | cout sum | want
  --------+----------+-----
  0 0  0  |   x   x  |  0 0   MISMATCH
  0 0  1  |   x   x  |  0 1   MISMATCH
```

`x` is not a wrong answer, it is *no answer yet* — you set the inputs and read the outputs in
the same breath, before the `assign` statements had a turn to run. The wait is what gives them
that turn.

But be careful about **why**, because the obvious reading is wrong. It is tempting to think
the gates need ten nanoseconds to settle. They do not. Change it to `#0` — wait for *zero*
nanoseconds — and all eight rows still pass:

```
TESTED 8
ERRORS 0
VERDICT PASS
tb_eight_rows.sv:66: $finish called at 0 (1ps)
```

The whole test finished **at time zero**. Settling a chain of `assign` statements costs no
simulated time at all; `#0` just tells the simulator *finish everything scheduled for right
now before you carry on*, and that is all that was ever needed.

So why write `#10`? Because of the waveform you are about to open. `#0` would stack all eight
rows on top of each other at t=0, unreadable. `#10` spreads them into eight evenly spaced
columns you can point at. **The ten is for your eyes, not for the gates.**

> Hold onto this. A number in a delay does not buy you time for logic to work — in DD103 you
> will watch a synthesizer throw `#5` away without a word of warning, because there is no gate
> whose job is to be late. Real delay is something you *measure* afterwards, in Lab 05.

## Run it

```bash
cd /foss/designs/modules/dd102/labs/guide-examples-proving-it
iverilog -g2012 -o eight.vvp src/tb_eight_rows.sv src/full_adder.sv
vvp eight.vvp
```

`iverilog` compiles; `vvp` runs what it compiled. Two steps, always in that order, and the
file in between is not interesting.

```
VCD info: dumpfile eight.vcd opened for output.
tb_eight_rows: all 8 inputs of full_adder
  a b cin | cout sum | want
  --------+----------+-----
  0 0  0  |   0   0  |  0 0   ok
  0 0  1  |   0   1  |  0 1   ok
  0 1  0  |   0   1  |  0 1   ok
  0 1  1  |   1   0  |  1 0   ok
  1 0  0  |   0   1  |  0 1   ok
  1 0  1  |   1   0  |  1 0   ok
  1 1  0  |   1   0  |  1 0   ok
  1 1  1  |   1   1  |  1 1   ok
TESTED 8
ERRORS 0
VERDICT PASS
src/tb_eight_rows.sv:66: $finish called at 160000 (1ps)
```

**Two lines in there look like problems and are not.**

`VCD info: dumpfile eight.vcd opened for output.` is the simulator telling you it is also
writing a waveform file. That is [the next page](guide/two-lines-make-the-waveform-appear.md).
It is not a warning.

`src/tb_eight_rows.sv:66: $finish called at 160000 (1ps)` is Icarus reporting that the
simulation ended where the testbench told it to, at line 66, after 160,000 picoseconds of
simulated time. Eight rows × 20 ns each = 160 ns = 160,000 ps. It prints on **every**
successful run in this course. A file name and a line number in the last line of output is
not, here, an error.

> Compare those eight rows against the sheet you brought from DD101, by eye, once. They are
> your rows. If the page and your paper disagree, your paper is the specification and
> something upstream is wrong — say so in the [Discord](https://discord.gg/hrJnP5UsGz).

## Eight rows is not a sample. It is the whole circuit.

This is the part worth being smug about for a minute.

A full adder has three inputs. Three binary inputs is $2^3 = 8$ possible states, and there is
no fourth input hiding anywhere, no memory, no clock, nothing that depends on what happened
before. So those eight rows are not a *test* of your adder in the sense of "we tried some
things and they worked". They are the adder's **entire behaviour**, written down. There is
nothing left to try.

Almost nothing you will ever build again has this property. Enjoy it.

## Now break it on purpose

The package ships a second full adder,
[`broken/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/broken/full_adder.sv),
which is `src/full_adder.sv` with the comments stripped and **one character** changed on the
last line:

```systemverilog
assign cout      = ha1_carry & ha2_carry;   // <-- & where the drawing has an Or
```

**Before you run it, write down a number.** Of the eight rows, how many do you think that one
character breaks? Commit to it.

```bash
iverilog -g2012 -o bad.vvp src/tb_eight_rows.sv broken/full_adder.sv
vvp bad.vvp
```

```
VCD info: dumpfile eight.vcd opened for output.
tb_eight_rows: all 8 inputs of full_adder
  a b cin | cout sum | want
  --------+----------+-----
  0 0  0  |   0   0  |  0 0   ok
  0 0  1  |   0   1  |  0 1   ok
  0 1  0  |   0   1  |  0 1   ok
  0 1  1  |   0   0  |  1 0   MISMATCH
  1 0  0  |   0   1  |  0 1   ok
  1 0  1  |   0   0  |  1 0   MISMATCH
  1 1  0  |   0   0  |  1 0   MISMATCH
  1 1  1  |   0   1  |  1 1   MISMATCH
TESTED 8
ERRORS 4
FIRST MISMATCH at 70 ns
VERDICT FAIL
src/tb_eight_rows.sv:66: $finish called at 160000 (1ps)
```

**Four.** And the arithmetic closes exactly.

`ha1_carry` is `a & b`. `ha2_carry` is `(a ^ b) & cin`. Those two can never be 1 at the same
time — `a & b` needs `a` and `b` equal, `a ^ b` needs them different — so `ha1_carry &
ha2_carry` is **always zero**, on every row, forever. That broken adder does not have a bug
that shows up sometimes. Its `cout` is a constant 0.

So it is wrong on exactly the rows where `cout` should have been 1, and your DD101 table says
there are four of those: `0 1 1`, `1 0 1`, `1 1 0`, `1 1 1`. Those are the four rows the
simulator just printed. Not "about four". Those four.

Notice also that `sum` is still perfect on all eight rows. Half of that module is flawless.
That is normal, and it is why "it mostly works" is not information.

## The exit code is not the verdict

Run that same broken simulation and ask the shell what it thought:

```bash
vvp bad.vvp > /dev/null; echo "exit $?"
```

```
exit 0
```

Zero. Success. The simulator did exactly what it was asked to do — it simulated a circuit, and
the circuit was wrong, and simulating a wrong circuit is not a failure of the simulator. `vvp`
exits 0 when your design is right and it exits 0 when your design is wrong.

> **Reflex: read the `VERDICT` line, never the exit code.** If something automated has to
> decide, make it read the text. That is exactly what
> [`src/check_sim.py`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/check_sim.py)
> does: it finds `TESTED`, `ERRORS` and `VERDICT` in the log, compares them against the
> reference numbers, and never once looks at an exit code. That is why `make` in this package
> can tell you that you failed.

This is the first of several places in the digital track where a green light means nothing.
DD103 has a whole page of them.

## Six cases is not eight rows

You proved a full adder exhaustively because it has three input bits, and three bits is eight
combinations. Four of those adders chained together — the thing you build in
[Part IV](guide/four-adders-in-a-row.md) — has **nine** input bits: `a[3:0]`, `b[3:0]` and
`cin`. That is $2^9 = 512$ combinations, which is sixty-four times as many and still, just
barely, all of them.

You have not written that module yet. Somebody else has, and theirs is broken, and this is a
better place to meet it than your own file at midnight. Here is
[`broken/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/broken/ripple4.sv),
complete, exactly as shipped:

```systemverilog
module ripple4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);
    logic [4:0] c;

    assign c[0] = 1'b0;

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));

    assign cout = c[4];
endmodule
```

Do not go hunting yet. First, here is a testbench for it — six cases, picked by hand, written
in about five minutes. This is not a straw man; it is what nearly everybody writes first, and
every case in it is a case that obviously matters:

```systemverilog
try_one(4'd0,  4'd0,  1'b0, "zero");
try_one(4'd1,  4'd0,  1'b0, "smallest");
try_one(4'd2,  4'd3,  1'b0, "no carries at all");
try_one(4'd7,  4'd1,  1'b0, "carry ripples all the way");
try_one(4'd15, 4'd1,  1'b0, "overflow into cout");
try_one(4'd15, 4'd15, 1'b0, "biggest inputs");
```

**Excerpt** — the whole file is
[`src/tb_six_cases.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_six_cases.sv).

```bash
iverilog -g2012 -o six.vvp src/tb_six_cases.sv broken/ripple4.sv src/full_adder.sv
vvp six.vvp
```

```
VCD info: dumpfile six.vcd opened for output.
tb_six_cases: six cases somebody thought were representative
  ok        0 + 0 + 0 = 0   (zero)
  ok        1 + 0 + 0 = 1   (smallest)
  ok        2 + 3 + 0 = 5   (no carries at all)
  ok        7 + 1 + 0 = 8   (carry ripples all the way)
  ok        15 + 1 + 0 = 16   (overflow into cout)
  ok        15 + 15 + 0 = 30   (biggest inputs)
TESTED 6
ERRORS 0
VERDICT PASS
src/tb_six_cases.sv:59: $finish called at 120000 (1ps)
```

Six for six. The zero case, the overflow case, the all-ones case, the case where the carry
walks the whole way. If somebody showed you that transcript you would sign off on the design.

## All 512

Now the same broken module against every input it can ever see.

**Write a number down first.** Out of 512, how many do you expect to be wrong?

```bash
iverilog -g2012 -o sweep.vvp src/tb_sweep.sv broken/ripple4.sv src/full_adder.sv
vvp sweep.vvp
```

```
VCD info: dumpfile sweep.vcd opened for output.
tb_sweep: all 512 inputs of ripple4
  MISMATCH  0 + 0 + 1 : ripple4 said 0, the answer is 1
  MISMATCH  0 + 1 + 1 : ripple4 said 1, the answer is 2
  MISMATCH  0 + 2 + 1 : ripple4 said 2, the answer is 3
  MISMATCH  0 + 3 + 1 : ripple4 said 3, the answer is 4
  MISMATCH  0 + 4 + 1 : ripple4 said 4, the answer is 5
  ... and 251 more. Only the first 5 are printed.
TESTED 512
ERRORS 256
FIRST MISMATCH at 30 ns
VERDICT FAIL
src/tb_sweep.sv:91: $finish called at 10240000 (1ps)
```

**256 out of 512.** The design that passed six carefully chosen cases is wrong **half the
time**.

> Only five `MISMATCH` lines print, then a count. That is deliberate: 256 of them would scroll
> the `TESTED`/`ERRORS`/`VERDICT` block off the top of your terminal, and the block is the part
> you need.

## "Exactly half" is itself the clue

Stop before you open the RTL. The number 256 is not just "a lot". It is **exactly half of
512**, and that is a fact about the *shape* of the bug, not its size.

If a bug fired on random inputs you would get some scattered number. If it fired on carries you
would get a lopsided number, because carries are not equally likely. Getting precisely half
means the damage tracks something that is true in exactly half of all inputs. Plenty of things
have that property, but the **simplest** ones, in a design with nine independent input bits,
are the nine bits themselves. So look at the bits first.

The sweep will tell you which one, if you ask it:

```bash
vvp sweep.vvp +clue | tail -12
```

```
  input   wrong when it is 0   wrong when it is 1
  cin                  0                  256
  b[0]               128                  128
  b[1]               128                  128
  b[2]               128                  128
  b[3]               128                  128
  a[0]               128                  128
  a[1]               128                  128
  a[2]               128                  128
  a[3]               128                  128
src/tb_sweep.sv:91: $finish called at 10240000 (1ps)
```

Every bit of `a` and `b` is 128/128 — the failures are spread evenly across them, which means
none of them is the cause. `cin` is **0 and 256**. Every single failure has `cin = 1`, and no
failure has `cin = 0`.

Now go back and read that module. `assign c[0] = 1'b0;` — the carry-in port is declared, and
then thrown away. The design is a perfectly good adder that always adds zero instead of `cin`.

And now look again at the six cases that passed. Every one of them has `1'b0` in the third
column. The testbench never once set `cin` to 1, so it never once tested the input the bug
lives in.

> **Reflex 1: a testbench that never sets an input to 1 has not tested that input.** Before you
> believe a `PASS`, read the input list and ask which inputs actually moved.
>
> **Reflex 2: when the mismatch count is exactly half the vectors, the bug tracks one input.**
> Count first, read RTL second. The count told you it was `cin` before you opened the file.

### The count is not the fingerprint

One warning before you use this trick everywhere.
[Lab 03](labs/lab-03-the-lazy-testbench-overview.md) hands you a **different** broken 4-bit adder, and
its exhaustive sweep also reports **256 of 512**. Same headline number, entirely different bug.
Its breakdown does not look like the one above at all — it splits **120** failures with
`cin = 0` and **136** with `cin = 1`, because that bug is about numbers being too big rather
than about an input being ignored.

So: *"exactly half"* tells you the bug is structural rather than a rare corner case, and that is
worth knowing in itself. It does not tell you **which** structure. The per-input breakdown does.
Run the count, then run the breakdown, then read the RTL — in that order, because each step
narrows the next one.

Repair is one character: `assign c[0] = cin;`. The good version is
[`src/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/ripple4.sv),
and the same sweep against it says:

```
VCD info: dumpfile sweep.vcd opened for output.
tb_sweep: all 512 inputs of ripple4
TESTED 512
ERRORS 0
VERDICT PASS
src/tb_sweep.sv:91: $finish called at 10240000 (1ps)
```

## Did any tool try to warn you?

Reasonable question, and the answer is uncomfortable and worth knowing exactly.

`iverilog -g2012 -o r.vvp broken/ripple4.sv src/full_adder.sv` compiled it without printing a
single character, and exited 0.

`yosys -p "read_verilog -sv broken/ripple4.sv src/full_adder.sv; synth -top ripple4"` synthesized
it and exited 0. Its log is **583 lines** long and contains exactly one line with the word
*Warning* in it:

```
ABC: Warning: The network is combinational (run "fraig" or "fraig_sweep").
```

Run the same command on the **correct** `src/ripple4.sv` and you get a log that is also **583
lines** long, containing that same one warning. It is about the shape of the netlist, not about
your bug, and it appears on every purely combinational design in this course.

Both tools are right to be quiet. An input you decline to use is legal SystemVerilog and people
do it on purpose all the time.

One tool in your workbench does say something. `make lint` runs it:

```bash
verilator --lint-only -Wall --top-module ripple4 broken/ripple4.sv src/full_adder.sv
```

```
%Warning-UNUSEDSIGNAL: broken/ripple4.sv:5:24: Signal is not used: 'cin'
                                             : ... note: In instance 'ripple4'
    5 |     input  logic       cin,
      |                        ^~~
                       ... For warning description see https://verilator.org/warn/UNUSEDSIGNAL?v=5.046
                       ... Use "/* verilator lint_off UNUSEDSIGNAL */" and lint_on around source to disable this message.
%Error: Exiting due to 1 warning(s)
```

Verilator names the file, the line, the column and the signal, and exits **1**. One command,
before any simulation, would have handed you the answer.

**And now the other half, which matters more.** Run the same command on the broken *full
adder* — the one with `&` where the Or should be:

```bash
verilator --lint-only -Wall --top-module full_adder broken/full_adder.sv
```

```
- V e r i l a t i o n   R e p o r t: Verilator 5.050 2026-07-01 rev v5.050
- Verilator: Built from 0.031 MB sources in 2 modules, into 0.010 MB in 3 C++ files needing 0.000 MB
- Verilator: Walltime 0.008 s (elab=0.000, cvt=0.002, bld=0.000); cpu 0.005 s on 1 threads; allocated 30.570 MB
```

Exit 0. Zero warnings. Perfectly clean. (The third line is a stopwatch; yours will read a
different number of milliseconds and that means nothing.)

That module is wrong on four of its eight rows and Verilator has nothing to say, because there
is nothing *malformed* about it. Every wire is driven, every input is used, every width
matches. It is a well-written description of the wrong circuit.

> **Reflex 3: lint before you believe a `PASS`, and never instead of it.** A lint warning is
> free information about how your file is *shaped*. A clean lint says nothing whatsoever about
> whether your circuit is *right*. Only the truth table knows that.

## Exhaustive is a luxury with an expiry date

You just tested a design completely, in a fraction of a second, and you will spend the rest of
your career not being able to do that. It is worth seeing exactly where the door closes.

The package ships an 8-bit version of the same adder,
[`src/ripple8.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/ripple8.sv)
— eight `full_adder` instances instead of four, nothing else new. Seventeen inputs, so
$2^{17} = 131{,}072$ vectors.

```bash
make eight-bit
```

```
tb_sweep8: all 131072 inputs of ripple8
TESTED 131072
ERRORS 0
VERDICT PASS
src/tb_sweep8.sv:40: $finish called at 2621440000 (1ps)
    wall 0.63 s
```

Still free. **131,072 vectors in about six tenths of a second** — repeated runs on the
workbench landed between 0.59 and 0.63 s, so your `wall` line will differ and the `TESTED
131072 / ERRORS 0` above it will not. Call it about 4.5 microseconds per vector. Hold onto
that rate and the rest is arithmetic:

| design | inputs | vectors | at 4.5 µs each |
|---|---|---|---|
| one full adder | 3 | **8** | instant |
| your 4-bit adder | 9 | **512** | instant |
| the 8-bit adder | 17 | **131,072** | **0.6 s, measured** |
| a 16-bit adder | 33 | 8,589,934,592 | about **11 hours** |
| a 32-bit adder | 65 | 36,893,488,147,419,103,232 | about **5.3 million years** |

The counts in that table are exact and the two "instant" rows and the 0.6 s row were measured
on `hpretl/iic-osic-tools:2026.08`. The last two rows are arithmetic from the measured rate, so
treat them as the right order of magnitude rather than a stopwatch reading. The order of
magnitude is the entire point.

> **The rate itself falls as the adder gets wider**, because each vector drives more wires. The
> 4.5 µs above was measured at 8 bits; [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md) measures it
> again at 12 bits, gets **7.9 µs**, and so puts the 16-bit row at about **19 hours** rather than
> 11. Neither is wrong and neither is a stopwatch reading — both say *overnight*, which is the
> answer that changes what you do.

**Somewhere between 8 bits and 16 bits, exhaustive stops being something you do while the
kettle boils.** And a 32-bit adder is a small, boring, combinational block — no memory, no
state machine, nothing clever. Add a single flip-flop and the input space stops being a number
at all, because the answer now depends on what happened before.

That is why **DD104** exists. Everything in it — constrained random stimulus, coverage,
assertions, `cocotb` — is an answer to the question *"what do you do when you cannot try
everything?"* You are allowed to skip that question for exactly as long as your designs stay
this small.

## Where you do this yourself

- **[Lab 02 — Prove it](labs/lab-02-prove-it-overview.md)** ships a testbench with **one** of your eight
  rows filled in, plus mutant adders for it to catch. Your seven missing rows are the lab.
- **[Lab 03 — The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md)** hands you a different
  broken 4-bit adder and does not tell you what is wrong with it. Every technique on this page
  works on it.
- **[`labs/guide-examples-proving-it/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-proving-it)**
  is every file printed above. `make` runs all five experiments and checks all five verdicts in
  about 0.4 seconds, with no environment setup at all.

## What to carry forward

| | |
|---|---|
| a testbench is | a module with no ports whose job is to disagree with you |
| `#10` means | wait ten nanoseconds of pretend time. `#0` would also pass — the ten is to space the waveform out, not to let gates settle |
| `vvp` exit 0 means | the simulation ran. Nothing about whether it passed. |
| six good cases proved | nothing, because they all had `cin = 0` |
| exactly half wrong means | the bug is structural, not a corner case. The breakdown says which signal. |
| a clean lint means | your file is well formed. Not that it is right. |
| 512 is | the entire behaviour of a 4-bit adder, and the last time that will be cheap |

Next: [Two lines make the waveform appear](guide/two-lines-make-the-waveform-appear.md) — the
sweep you just ran already wrote a 57,207-byte file you have not opened, and it can show you
the exact moment — 30 ns in — where this went wrong.
