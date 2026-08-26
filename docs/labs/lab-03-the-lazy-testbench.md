# Lab 03 — The lazy testbench

Full runnable package:
[`labs/lab-03-the-lazy-testbench/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-03-the-lazy-testbench).

**The question this lab answers:** *I tested my adder and it passed. Why is that not enough?*

In [Lab 02](labs/lab-02-prove-it.md) you checked all eight rows, because a full adder has
exactly eight. That was the last time in your life it will be that easy.

Four of those adders in a row make a 4-bit adder. It has nine input bits, so it has
$2^9 = 512$ possible situations — still small enough to check every one, and already far too
many to write out by hand. So you do what everybody does: you pick some numbers that feel
representative, you check those, and it passes.

This lab is about what "it passes" was worth.

## Prerequisites

- [Lab 02](labs/lab-02-prove-it.md) done — you have written a self-checking testbench and
  watched it catch three planted bugs
- Read [Eight rows and no opinions](guide/eight-rows-and-no-opinions.md) — it works the same
  arithmetic on a *different* broken adder, and the fingerprinting technique it teaches is the
  one to use here
- [What a module actually is](guide/what-a-module-is.md) — this lab wires four instances of one
  module together, which is the thing that page is about
- `iverilog -V` says `Icarus Verilog version 14.0 (devel)` on its first line

## Objectives

- Chain four full adders into a 4-bit adder and see how little new code that takes
- Commit to a number for how wrong a design is, then measure it, then account for the gap
  exactly
- Recognise a truncated carry on sight, in any width, forever
- Meet the plausible fix that fixes nothing, and the one command that catches it

## Theory (short)

`src/add4.sv` is four `full_adder` instances. The carry out of each one is the carry in of the
next — the same picture you drew in DD101 when you worked out how to add two-digit numbers.
There is no arithmetic in the file at all; there are four boxes and some wires.

The design ends with a wire named `c4`: the carry out of the top adder. It is computed. It is
correct. And it is not in the port list, so it stops inside the module.

That is the entire bug, and it is worth stating as arithmetic rather than as a mistake:

$$15 + 15 + 1 = 31$$

Thirty-one does not fit in four bits. Four bits hold 0 through 15. **The answer to a 4-bit
addition is a 5-bit number**, always, and if you only provide four bits of room, the top one
goes on the floor without a sound.

## Procedure

```bash
cd labs/lab-03-the-lazy-testbench
make
```

Three stages, about two seconds, no environment setup.

---

### 1 — Write a few cases. It passes.

Open [`tb/tb_lazy.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/tb/tb_lazy.sv).
Three cases are in:

```
        //      a      b     cin
        try_one(4'd1,  4'd2, 1'b0);      // 1 + 2 = 3
        try_one(4'd3,  4'd4, 1'b0);      // 3 + 4 = 7
        try_one(4'd5,  4'd2, 1'b1);      // 5 + 2 + 1 = 8
```

- **Try this:** add three of your own. Pick the numbers you would actually use to convince
  yourself a 4-bit adder works — the ones you would put in a lab report. Then `make lazy`.

- **What you should see:**

```
tb_lazy: a few cases somebody thought were representative
TESTED 6
ERRORS 0
VERDICT PASS

PASS    -- your 6 hand-picked cases all agreed with add4.
           6 of the 512 inputs add4 can see. Write that fraction down.
```

  Nothing is rigged. The expected value is computed honestly, in a five-bit variable, so
  nothing is rounded off on the testbench's side. Your cases genuinely pass.

> If one of *your* cases failed instead, you found the bug before this lab showed it to you,
> and the grader says so. That is the better outcome. Keep going anyway — the interesting part
> is not *that* it is wrong, it is *how much*.

- **Now commit to a number.** `make` asks you for it in writing:

```
    Before you run the next stage, commit to a number:
    of add4's 512 possible inputs, how many does it get WRONG?
    Write it down. ______
```

  Most people write something between 1 and 30. Write yours down before you scroll.

---

### 2 — Run all 512. It does not pass.

[`tb/tb_exhaustive.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/tb/tb_exhaustive.sv)
is shipped, complete, and drives the same `add4` through every input it can ever see: 16
values of `a`, times 16 of `b`, times 2 of `cin`.

- **What you should see:** not your number.

```
tb_exhaustive: all 512 inputs of add4
  MISMATCH  0 + 15 + 1 : add4 said 0, the answer is 16
  MISMATCH  1 + 14 + 1 : add4 said 0, the answer is 16
  MISMATCH  1 + 15 + 0 : add4 said 0, the answer is 16
  MISMATCH  1 + 15 + 1 : add4 said 1, the answer is 17
  MISMATCH  2 + 13 + 1 : add4 said 0, the answer is 16
  ... and 251 more. Only the first 5 are printed.
TESTED 512
ERRORS 256
  with cin=0 : 120
  with cin=1 : 136
VERDICT FAIL
```

  **256 of 512.** Exactly half. The same design that passed six hand-picked cases is wrong
  about half of everything it will ever be handed.

  The `... and 251 more.` is deliberate — 256 `MISMATCH` lines would push the numbers you came
  for off the top of your terminal.

- **Now watch the arithmetic close.** 256 is not a vague "about half". It is countable, and the
  testbench splits it for you so you can check it.

  With **`cin = 0`**, the answer is wrong exactly when $a + b \ge 16$. Count the pairs: there
  is 1 way to make 30, 2 ways to make 29, and so on down to 15 ways to make 16. That is
  $1 + 2 + \cdots + 15 = 120$.

  With **`cin = 1`**, the answer is wrong when $a + b + 1 \ge 16$, which is $a + b \ge 15$ —
  the same 120 pairs, plus the 16 pairs that sum to exactly 15. That is $120 + 16 = 136$.

  $$120 + 136 = 256$$

  And the grader will not say `MATCH` unless all four of those numbers are exactly right:

```
MATCH   -- 256 of 512 inputs are wrong. That is the reference number,
           to the digit: 120 of them with cin=0, 136 with cin=1,
           and 120 + 136 = 256.
```

  The very first failure, in counting order, is worth reading twice:

```
  MISMATCH  0 + 15 + 1 : add4 said 0, the answer is 16
```

  **Zero plus fifteen plus one is zero.** No warning, no error, no exception. This is what
  hardware does when you do not give the answer somewhere to live.

- **Why an engineer cares:** your six cases were not lazy in the sense of careless. Two of
  them landed on 15, the largest number `add4` can represent — that *feels* like testing the
  edge. It is not the edge. The edge is one past the largest number, and hand-picked cases
  cluster inside the range you were thinking about, because the range you were thinking about
  is what made you pick them.

> **Reflex: N bits plus N bits does not fit in N bits.** Every adder needs somewhere for the
> top carry to go, and every testbench needs a case that puts something there. When you cannot
> check all the inputs, the ones you check should be *the boundaries*, not the middle.

---

### 3 — One more wire

`make fixed` runs the identical 512 inputs against
[`reference/add5.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/reference/add5.sv).

Diff it against `src/add4.sv` before you run it. Character for character, it is the same four
instances, wired the same way. The difference is one line in the port list and one word in the
last instance: `c4` is now called `cout` and it leaves the module.

```
tb_exhaustive_fixed: all 512 inputs of add5
TESTED 512
ERRORS 0
VERDICT PASS

MATCH   -- 512 of 512 inputs correct, 0 mismatches.
```

Nothing inside the design was repaired. **A wire that already existed was allowed out.**

```
==============================================================
 VERDICT
==============================================================
 tb_lazy.sv        vs add4  (a few cases)  : PASS    6
 tb_exhaustive.sv  vs add4  (all 512)      : MATCH   256/512
 tb_exhaustive_fixed.sv vs add5 (all 512)  : MATCH   0/512
--------------------------------------------------------------
 The same design passed one testbench and failed another by 256 rows.
 The testbench was the variable, not the adder.
```

---

### 4 — The dead end: the fix that fixes nothing

Here is what almost everybody tries first, and it is a *reasonable* thing to try: the answer
needs five bits, so make it five bits.

[`broken/add4_wider_inside.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/broken/add4_wider_inside.sv)
does exactly that. It throws away the four instances, computes the sum in one line into a
five-bit wire, and drives the port from it:

```systemverilog
    logic [4:0] wide;           // five bits, so nothing is lost HERE

    assign wide = a + b + cin;
    assign sum  = wide;         // ...and lost here instead, in silence
```

- **Try this:** predict the error count before you run `make trap`.

- **What you should see:** the same 256.

```
TESTED 512
ERRORS 256
  with cin=0 : 120
  with cin=1 : 136
VERDICT FAIL
```

  Identical, to the digit, including the split. The port is still four bits wide, so the fifth
  bit is discarded at the assignment instead of inside the adder. It moved; it did not go away.

  `iverilog -g2012 -Wall` compiles it with **exit 0**. The only thing it says is two pairs of
  this:

```
broken/add4_wider_inside.sv:10: warning: timescale for add4 inherited from another file.
tb/tb_exhaustive.sv:11: ...: The inherited timescale is here.
src/full_adder.sv:11: warning: timescale for full_adder inherited from another file.
tb/tb_exhaustive.sv:11: ...: The inherited timescale is here.
```

  which is scenery — it means only that one file declared `` `timescale `` and the others did
  not. It appears on healthy runs too and it has nothing to do with your bug.

  Now, the same command that told you nothing in
  [Lab 01](labs/lab-01-transcribe-your-adder.md):

```
$ verilator --lint-only -Wall --top-module add4 broken/add4_wider_inside.sv src/full_adder.sv
%Warning-DECLFILENAME: broken/add4_wider_inside.sv:10:8: Filename 'add4_wider_inside' does not match MODULE name: 'add4'
%Warning-WIDTHTRUNC: broken/add4_wider_inside.sv:20:17: Operator ASSIGNW expects 4 bits on the Assign RHS, but Assign RHS's VARREF 'wide' generates 5 bits.
%Warning-UNUSEDSIGNAL: broken/add4_wider_inside.sv:17:17: Bits of signal are not used: 'wide'[4]
%Error: Exiting due to 3 warning(s)
exit status 1
```

(Verilator prints the offending source line and a documentation link under each warning; the
block above keeps only the headlines. `--top-module add4` tells it which of the two modules is
the top, and without it you get a fourth warning, `MULTITOP`, about that ambiguity rather than
about your design.)

  **Three warnings.** The first one is about the filename and is not your bug — this package
  keeps a module called `add4` in a file called `add4_wider_inside.sv` on purpose, so you can
  compare it against `src/add4.sv` without renaming anything.

  The other two *are* your bug, said twice, in plain language: `WIDTHTRUNC` says the
  assignment throws away a bit, and `UNUSEDSIGNAL` says the bit that gets thrown away is bit 4
  — the carry. `make trap` runs both commands back to back.

**And now run it on the original.** `make lint` does all three designs in a row:

```
 verilator --lint-only -Wall --top-module add4 src/add4.sv
%Warning-UNUSEDSIGNAL: src/add4.sv:16:23: Signal is not used: 'c4'
%Error: Exiting due to 1 warning(s)
exit status 1

 verilator --lint-only -Wall --top-module add5 reference/add5.sv
exit status 0
```

  **One warning on `src/add4.sv`, naming `c4` by name.** The tool knew. It knew before you
  wrote a single test case, from the file alone and nothing else — a wire is
  computed and goes nowhere, which in hardware is almost always either dead logic or a dropped
  answer. And `reference/add5.sv`, the correct one, is clean and exits 0.

- **Why an engineer cares:** in Lab 01 you were told that `verilator --lint-only` is nearly
  silent by default and that `-Wall` is the flag that makes it earn its place. This is the lab
  where that reflex pays, twice. A width mismatch is invisible to a simulator, because it is
  not an error — it is exactly what the language says should happen — and it is the single most
  common way a correct-looking design produces wrong numbers. An unused wire is invisible for
  the same reason. Neither one is a bug in the language. Both are bugs in your design, and one
  command with one flag finds both.

## Expected results

Every number here came from a run on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0,
Python 3.12.3. `src/check_run.py` refuses to say `MATCH` unless yours agree exactly.

```
stage      design                        testbench                tested  wrong  verdict
-----------------------------------------------------------------------------------------
lazy       src/add4.sv                   tb_lazy.sv (as shipped)       3      0  PASS
lazy       src/add4.sv                   reference/tb_lazy.sv          6      0  PASS
exhaustive src/add4.sv                   tb_exhaustive.sv            512    256  FAIL
trap       broken/add4_wider_inside.sv   tb_exhaustive.sv            512    256  FAIL
fixed      reference/add5.sv             tb_exhaustive_fixed.sv      512      0  PASS
```

The 256 splits **120** (`cin=0`) + **136** (`cin=1`). First failure in counting order:
`0 + 15 + 1`, where `add4` says `0` and the answer is `16`.

Lint, on the same files:

```
command                                                                  warnings  exit
----------------------------------------------------------------------------------------
verilator --lint-only -Wall --top-module add4 src/add4.sv                       1     1
verilator --lint-only -Wall --top-module add4 broken/add4_wider_inside.sv       3     1
verilator --lint-only -Wall --top-module add5 reference/add5.sv                 0     0
```

(each also given `src/full_adder.sv`, since all three instantiate it or are compared against
something that does)

`make` always exits 0 — the verdict is the text. `make grade` is the same three stages with an
exit status a script can read, and here it exits **0**, because everything this lab asks of you
is already true of the shipped files. The work is in reading it, not in repairing it.

## Links

- Package: [`labs/lab-03-the-lazy-testbench/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-03-the-lazy-testbench)
- Guide: [Eight rows and no opinions](guide/eight-rows-and-no-opinions.md) ·
  [What a module actually is](guide/what-a-module-is.md)
- Drill: [HDLBits — Exams/m2014 q4j](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j), a 4-bit
  ripple adder built out of full adders, graded by somebody else's testbench
- Stuck? [Team Discord](https://discord.gg/hrJnP5UsGz)

## What you carry forward

- A 4-bit adder you can build out of four one-bit adders without writing any arithmetic
- The number **256 of 512**, and the fact that six sensible cases hit none of them
- **`verilator --lint-only -Wall`**, which is now a thing you run before you are confused
  rather than after
- The habit of asking, of any passing test: *how many of the possible inputs was that?*

Next: [Four adders in a row](guide/four-adders-in-a-row.md), which turns those four hand-typed
instances into one loop and shows you what an extra bit costs — then
[Lab 04 — Four adders in a row](labs/lab-04-four-adders-in-a-row.md), where Yosys **proves** the
loop and the hand-typed version are the same circuit.
