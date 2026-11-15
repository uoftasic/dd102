# Lab 02: Prove it

You run a self-checking testbench against a full adder, break the adder and read the failure,
and then write a testbench of your own. Something has to check your testbench too, so the
package hands it three full adders that are broken on purpose. A good testbench catches all
three; the one you start with catches none.

Packages: [`labs/guide-examples-proving-it/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-proving-it)
for Parts 1 and 2, [`labs/lab-02-prove-it/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-02-prove-it)
for the rest.

## Before you start

- Finish [Lab 01](../labs/lab-01-transcribe-your-adder-overview.md): your `full_adder.sv` passes
  8 of 8.
- Read [Testbenches](../guide/eight-rows-and-no-opinions.md).
- Open a terminal on the workbench desktop and run `mod dd102`. Neither package needs any other
  setup.

Time: about 1½ hours.

## Part 1: Run a testbench by hand

What does a self-checking testbench print when the adder is right?

1. Go to the package:

   ```bash
   cd /foss/designs/modules/dd102/labs/guide-examples-proving-it
   ```

2. Compile the eight-row testbench together with the full adder, then run what you compiled:

   ```bash
   iverilog -g2012 -o eight.vvp src/tb_eight_rows.sv src/full_adder.sv
   vvp eight.vvp
   ```

   `iverilog` compiles and `vvp` runs. It is always two steps in that order, and the `.vvp` file
   in between isn't interesting.

You should see:

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

Two lines in there look like problems and aren't:

- `VCD info: dumpfile eight.vcd opened for output.` means the simulator is also writing a
  waveform file. You open it in Lab 03. It is not a warning.
- `src/tb_eight_rows.sv:66: $finish called at 160000 (1ps)` is Icarus reporting that the
  simulation ended where the testbench told it to, at line 66, after 160,000 ps of simulated
  time: eight rows × 20 ns = 160 ns. It prints on every successful run in this course.

Compare the eight rows with the sheet you brought from DD101, by eye, once. If the page and your
paper disagree, your paper is the specification and something upstream is wrong; say so in the
[Discord](https://discord.gg/hrJnP5UsGz).

## Part 2: Break the adder

Which rows does one wrong character break, and why those?

[`broken/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/broken/full_adder.sv)
is `src/full_adder.sv` with the comments stripped and one character changed on the last line:

```systemverilog
assign cout      = ha1_carry & ha2_carry;   // <-- & where the drawing has an Or
```

It is the same mistake as the broken adder you ran in Lab 01, Part 6.

1. Run the same testbench against it:

   ```bash
   iverilog -g2012 -o bad.vvp src/tb_eight_rows.sv broken/full_adder.sv
   vvp bad.vvp
   ```

   You should see:

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

2. Exactly four rows fail, and `sum` is right on all eight. Work out why from the two carries:
   `ha1_carry` is `a & b` and `ha2_carry` is `(a ^ b) & cin`. Can they ever both be 1?

   <details>
   <summary>Answer</summary>

   No. `a & b` needs `a` and `b` equal, and `a ^ b` needs them different. So
   `ha1_carry & ha2_carry` is 0 on every row, and this adder's `cout` is a constant 0. It is wrong
   on exactly the rows where `cout` should be 1, and your DD101 table has four of those: `0 1 1`,
   `1 0 1`, `1 1 0` and `1 1 1`. `sum` is still right on all eight rows. Half of the module is
   flawless, which is why "it mostly works" tells you nothing.

   </details>

3. Ask the shell what it thought of that run:

   ```bash
   vvp bad.vvp > /dev/null; echo "exit $?"
   ```

   You should see `exit 0`. The simulator did what it was asked: it simulated a circuit, and the
   circuit was wrong. `vvp` exits 0 whether your design is right or wrong. Read the `VERDICT`
   line, never the exit code. That is what
   [`src/check_sim.py`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/check_sim.py)
   does: it finds `TESTED`, `ERRORS` and `VERDICT` in the log and compares them with the
   reference numbers, and never looks at an exit code.

The `.vvp` and `.vcd` files these commands leave in the package folder are ignored by git, and
`make` writes its own copies under `results/`.

## Part 3: Run the one-row testbench

How much does a testbench that checks one row catch?

Now you write the testbench. A testbench in this lab is a module with no ports: it declares
wires, connects them to the adder, drives values in and looks at what comes back. The pieces
you haven't seen yet:

- `#1` waits one time unit, so the `assign` statements get their turn before you read the
  outputs. As [Testbenches](../guide/eight-rows-and-no-opinions.md) shows, the wait has to be
  there, but its length buys the gates nothing.
- `!==` compares including `x` and `z`. `!=` returns `x` when either side is `x`, and an `if` on
  `x` does nothing at all; `!==` returns a plain 0 or 1, which is what you want in a check. This
  difference is why a whole class of broken testbenches passes silently.
- `$display` prints a line. `$finish` stops the simulation.
- A `task` is a named block you call with arguments, so eight checks are eight lines instead of
  eight copies of the same six.

The verdict is three `$display` lines at the end:

```
TESTED 8
ERRORS 0
VERDICT PASS
```

`src/check_verdict.py` reads exactly those three lines. Don't rename them; the grader tells you
if you do.

1. Go to the package:

   ```bash
   cd ../lab-02-prove-it
   ```

2. Open [`tb/tb_full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-02-prove-it/tb/tb_full_adder.sv).
   It is complete and runs as shipped. It checks one row:

   ```
           //    a  b  cin   cout  sum
           check(0, 0,  0,    0,    0);
   ```

3. Look at the three files in `mutants/`. Each is a complete `module full_adder` with one thing
   wrong:

   | File | What is wrong |
   |---|---|
   | `mut1_cin_ignored.sv` | `assign sum = a ^ b;`: `cin` dropped |
   | `mut2_carry_needs_all_three.sv` | `assign cout = a & b & cin;`: `&` where `\|` belongs |
   | `mut3_outputs_swapped.sv` | both expressions correct, connected to the wrong ports |

4. Write down how many of the three your one-row testbench will catch. Then run:

   ```bash
   make
   ```

You should see:

```
==============================================================
 VERDICT
==============================================================
 against the working adder             : THIN (1 of 8 rows checked)
 mutants/mut1_cin_ignored.sv           : SLIPPED
 mutants/mut2_carry_needs_all_three.sv : SLIPPED
 mutants/mut3_outputs_swapped.sv       : SLIPPED
--------------------------------------------------------------
 mutants caught: 0 of 3
```

A line like `tb/tb_full_adder.sv:56: $finish called at 1000 (1ps)` appears after every one of
these runs, passing or failing. It means the testbench reached its last line, and the time is
1 ns per `check(...)`: `1000 (1ps)` for the shipped one-row testbench, `8000 (1ps)` once all eight
rows are in. (The line number moves as you add rows.)

5. Zero of three: your testbench printed `VERDICT PASS` four times, and three of those four
   adders are wrong. Run the one row you check, `a=0 b=0 cin=0`, through each mutant by hand.
   Why does that row miss all three?

   <details>
   <summary>Answer</summary>

   | | `sum` | `cout` |
   |---|---|---|
   | correct | `0 ^ 0 ^ 0` = 0 | `(0&0)\|(0&0)\|(0&0)` = 0 |
   | mut1 | `0 ^ 0` = 0 | unchanged = 0 |
   | mut2 | unchanged = 0 | `0 & 0 & 0` = 0 |
   | mut3 | majority = 0 | xor = 0 |

   All four agree. `a=0 b=0 cin=0` is the row on which almost every wrong adder is accidentally
   right, because zero in, zero out is what nearly any combination of these gates does. It is
   also the first row everybody tests.

   </details>

The grader calls this `THIN`, not `WRONG`. Your testbench isn't incorrect; it isn't finished, and
nothing in its output tells those two states apart. `PASS` is a claim about the rows you looked
at and says nothing about the rows you didn't.

## Part 4: Write the other seven rows

Does a full truth table catch all three mutants, and what does each failure tell you?

1. Add the other seven `check(...)` lines to `tb/tb_full_adder.sv`. They are the other seven rows
   of the table in your DD101 handwriting. Keep the column order `a, b, cin, cout, sum`.
2. `mut3` has the right expressions on the wrong ports. Write down how many of the eight rows you
   expect it to get wrong.
3. Run `make` again and read the middle section before the summary.

You should see three different failures, each describing its own bug:

```
--- mutants/mut1_cin_ignored.sv ---
  MISMATCH  a=0 b=0 cin=1 : got cout=0 sum=0, want cout=0 sum=1
  MISMATCH  a=0 b=1 cin=1 : got cout=1 sum=1, want cout=1 sum=0
  MISMATCH  a=1 b=0 cin=1 : got cout=1 sum=1, want cout=1 sum=0
  MISMATCH  a=1 b=1 cin=1 : got cout=1 sum=0, want cout=1 sum=1
TESTED 8
ERRORS 4
VERDICT FAIL
CAUGHT  -- mutants/mut1_cin_ignored.sv: 4 of 8 rows disagreed. Your testbench noticed.
```

```
--- mutants/mut2_carry_needs_all_three.sv ---
  MISMATCH  a=0 b=1 cin=1 : got cout=0 sum=0, want cout=1 sum=0
  MISMATCH  a=1 b=0 cin=1 : got cout=0 sum=0, want cout=1 sum=0
  MISMATCH  a=1 b=1 cin=0 : got cout=0 sum=0, want cout=1 sum=0
TESTED 8
ERRORS 3
VERDICT FAIL
```

and `mut3_outputs_swapped.sv` failing 6 of 8. The summary should now say:

```
 against the working adder             : GOOD (8 of 8 rows checked)
 mutants/mut1_cin_ignored.sv           : CAUGHT
 mutants/mut2_carry_needs_all_three.sv : CAUGHT
 mutants/mut3_outputs_swapped.sv       : CAUGHT
--------------------------------------------------------------
 mutants caught: 3 of 3

 All 8 rows checked, all 3 mutants caught. Lab 02 is done.
```

That is 4 + 3 + 6 = 13 wrong rows out of the 24 the mutants offer, and the one-row testbench saw
none of them.

4. Read the bugs out of the patterns without opening the files. What do `mut1`'s four rows have
   in common, what do `mut2`'s three have in common, and which two rows does `mut3` get right?

   <details>
   <summary>Answer</summary>

   `mut1`: every failing row has `cin=1`, and `cout` is right every time. Whatever is wrong only
   matters when `cin` is 1, and only `sum` is affected: a `sum` that doesn't look at `cin`.

   `mut2`: exactly the three rows where two inputs are 1 and the third is 0. Where all three are
   1 this mutant is right, and where fewer than two are 1 it is right. It is wrong only in the
   gap between "at least two" and "all three".

   `mut3` is right on `000` and `111`, the two rows where the sum bit and the carry bit happen to
   be equal, and wrong on the other six.

   </details>

## Part 5: Two more checks

Does the grader notice when your testbench itself is wrong, and does your own Lab 01 adder pass
your testbench?

1. Break your own testbench. In your finished `tb/tb_full_adder.sv`, change one expected value
   to the wrong number and run:

   ```bash
   make good
   ```

   You should see:

   ```
   BAD     -- src/full_adder.sv: 1 mismatches against a KNOWN-GOOD adder.
             Either src/full_adder.sv is not the shipped one, or one of your
             expected values does not match the DD101 truth table.
   ```

   That makes three states, `THIN`, `BAD` and `GOOD`, and they mean three different things. A
   grader that only said "fail" would have folded them into one word. Put the value back.

2. Test your own Lab 01 adder. `src/full_adder.sv` here is a shipped working adder so that nobody
   is blocked. Copy your own Lab 01 file over it and run `make`:

   ```bash
   cp ../lab-01-transcribe-your-adder/src/full_adder.sv src/full_adder.sv
   make
   ```

   If Lab 01 passed, you should see the same summary as in Part 4, ending
   `All 8 rows checked, all 3 mutants caught. Lab 02 is done.` Now the thing being tested and the
   thing testing it are both yours.

## Finishing

### You're done when

you have worked through Parts 1 to 5 and `make` in `labs/lab-02-prove-it/`, with your eight
`check(...)` rows in `tb/tb_full_adder.sv` and your Lab 01 adder in `src/full_adder.sv`, ends
with `All 8 rows checked, all 3 mutants caught. Lab 02 is done.`

`make` always exits 0; the verdict is the text. `make grade` is the same run with an exit status
and prints `make: *** [Makefile:75: grade] Error 1` until every box is ticked. `make reference`
runs the working adder and the mutants against `reference/tb_full_adder.sv` instead of yours. The lab's reference
numbers are on [Expected results](../reference/expected-results.md#lab-02-prove-it).

### Questions

1. Before Part 4, your testbench printed `VERDICT PASS` on the working adder. Why isn't that
   enough to trust it, and what should you do before you trust any testbench?

   <details>
   <summary>Answer</summary>

   `PASS` is a claim about the rows you looked at (Part 3). `MISMATCH` lines are the useful output
   of a testbench: a test that has only ever printed `PASS` has never shown it can print anything
   else. Before you trust a testbench, break the design on purpose and check that it notices:
   change a `|` to a `&`, run it, put the character back.

   </details>

### Submit

Nothing to submit.

## Going further (optional)

[HDLBits Fadd](https://hdlbits.01xz.net/wiki/Fadd) is the same problem graded by somebody else's
testbench.

Stuck? Ask in the [team Discord](https://discord.gg/hrJnP5UsGz).

Next on the [Course path](../index.md#course-path): read [Waveforms](../guide/two-lines-make-the-waveform-appear.md),
then do [Lab 03: The lazy testbench](../labs/lab-03-the-lazy-testbench-overview.md).
