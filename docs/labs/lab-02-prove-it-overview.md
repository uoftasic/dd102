# Lab 02 — Prove it

Full runnable package:
[`labs/lab-02-prove-it/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-02-prove-it).

**The question this lab answers:** *My adder passes. How do I know my test is any good?*

In [Lab 01](labs/lab-01-transcribe-your-adder-overview.md) a testbench was handed to you, and it told
you your adder was right. This time you write the testbench. And then something has to check
**it**, because a test that says PASS on everything you show it is not a test — it is a
formality with a green tick on the end.

So this package hands your testbench three full adders that are broken on purpose. A good
testbench catches all three. Yours, as shipped, catches none.

## Prerequisites

- [Lab 01](labs/lab-01-transcribe-your-adder-overview.md) done — your `full_adder.sv` passes 8 of 8
- Read [Eight rows and no opinions](guide/eight-rows-and-no-opinions.md)
- `iverilog -V` says `Icarus Verilog version 14.0 (devel)` on its first line

## Objectives

- Write a self-checking testbench: one that prints its own verdict instead of a table you read
- Predict how much a small test proves, be wrong about it, and see the exact number
- Read three `FAIL`s you caused on purpose, each one telling you a different thing
- Leave with a habit you apply to every test you ever write

## Theory (short)

A testbench is a module with no ports. It declares wires, connects them to the thing being
tested, drives values in, and looks at what comes back. There is no new language in it — the
only unfamiliar pieces are:

- `#1` — "let one time unit pass." Your adder is combinational, so this is just long enough
  for the gates to settle before you look.
- `!==` — compare *including* `x` and `z`. `!=` returns `x` when either side is `x`, which
  makes an `if` do nothing at all; `!==` returns a straight 0 or 1 and is what you want in a
  check. This distinction is why a whole class of broken testbenches silently pass.
- `$display` — print a line. `$finish` — stop the simulation.
- `task` — a named block you call with arguments, so eight checks are eight lines instead of
  eight copies of the same six.

The verdict is three `$display` lines at the end:

```
TESTED 8
ERRORS 0
VERDICT PASS
```

`src/check_verdict.py` reads exactly those three lines. **Do not rename them** — the grader
will tell you so if you do.

## Procedure

```bash
cd labs/lab-02-prove-it
make
```

No environment setup of any kind. `make` alone, in a bare container.

---

### 1 — Predict, then measure

Open [`tb/tb_full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-02-prove-it/tb/tb_full_adder.sv).
It is complete and it runs as shipped. It checks exactly one row:

```
        //    a  b  cin   cout  sum
        check(0, 0,  0,    0,    0);
```

Now look at the three files in `mutants/`. Each one is a complete `module full_adder` with
exactly one thing wrong:

| file | what is wrong |
|---|---|
| `mut1_cin_ignored.sv` | `assign sum = a ^ b;` — `cin` dropped |
| `mut2_carry_needs_all_three.sv` | `assign cout = a & b & cin;` — `&` where `\|` belongs |
| `mut3_outputs_swapped.sv` | both expressions correct, connected to the wrong ports |

- **Try this:** **Write down how many of those three your one-row testbench will catch.**
  Most people say one, or two. Then run `make`.

- **What you should see:** not your number.

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

  **Zero of three.** Your testbench printed `VERDICT PASS` four times, and three of those four
  adders are wrong.

- **Now account for it exactly.** Take the one row you check, `a=0 b=0 cin=0`, and run it
  through each mutant by hand:

| | `sum` | `cout` |
|---|---|---|
| correct | `0 ^ 0 ^ 0` = **0** | `(0&0)\|(0&0)\|(0&0)` = **0** |
| mut1 | `0 ^ 0` = **0** | unchanged = **0** |
| mut2 | unchanged = **0** | `0 & 0 & 0` = **0** |
| mut3 | majority = **0** | xor = **0** |

  All four agree. Not by coincidence — `a=0 b=0 cin=0` is the row on which almost every wrong
  adder is accidentally right, because zero in, zero out is what nearly any combination of
  those gates does. It is also, universally, the first row anybody tests.

- **Why an engineer cares:** the grader calls this `THIN`, not `WRONG`, and the distinction is
  the whole lab. Your testbench is not incorrect. It is not finished, and nothing about its
  output distinguishes those two states. `PASS` is a claim about the rows you looked at, and
  it says nothing whatsoever about the rows you did not.

---

### 2 — Read a FAIL you caused on purpose

Add the other seven `check(...)` lines. They are already written down — they are the other
seven rows of the table in your DD101 handwriting. Keep the column order `a, b, cin, cout, sum`.

Run `make` again and read the middle section rather than the summary.

- **What you should see:** three different failures, each one describing its own bug.

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

  **Four rows, and every one of them has `cin=1`.** The four `cin=0` rows are untouched. You
  can read the bug out of the failure pattern without opening the file: whatever is wrong, it
  only matters when `cin` is 1, and `cout` was right every time. That is a `sum` that does not
  look at `cin`.

```
--- mutants/mut2_carry_needs_all_three.sv ---
  MISMATCH  a=0 b=1 cin=1 : got cout=0 sum=0, want cout=1 sum=0
  MISMATCH  a=1 b=0 cin=1 : got cout=0 sum=0, want cout=1 sum=0
  MISMATCH  a=1 b=1 cin=0 : got cout=0 sum=0, want cout=1 sum=0
TESTED 8
ERRORS 3
VERDICT FAIL
```

  **Three rows — and they are exactly the three where two inputs are 1 and the third is 0.**
  Where all three are 1, this mutant is right. Where fewer than two are 1, it is right. It is
  wrong only in the gap, which is precisely the definition of "at least two" versus "all
  three". The failure names the bug.

  `mut3_outputs_swapped.sv` fails **6** of 8 — every row except `000` and `111`, the two where
  the sum bit and the carry bit happen to be equal.

- **What the summary should say now:**

```
 against the working adder             : GOOD (8 of 8 rows checked)
 mutants/mut1_cin_ignored.sv           : CAUGHT
 mutants/mut2_carry_needs_all_three.sv : CAUGHT
 mutants/mut3_outputs_swapped.sv       : CAUGHT
--------------------------------------------------------------
 mutants caught: 3 of 3

 All 8 rows checked, all 3 mutants caught. Lab 02 is done.
```

  4 + 3 + 6 = **13** wrong rows out of the 24 the three mutants offer, and the one-row
  testbench saw none of them.

- **Why an engineer cares:** `MISMATCH` lines are the *useful* output of a testbench, not the
  embarrassing part. A test that has only ever printed `PASS` has never demonstrated that it
  can print anything else. Reading a failure you engineered is how you find out your instrument
  works — and it is much cheaper to practise on a bug you planted than on one you did not.

> **Reflex: a testbench that has never failed has proven nothing.** Before you trust one,
> break the design on purpose and check that it notices. One character is enough — change a
> `|` to a `&`, run it, put the character back.

---

### 3 — Two things worth doing on purpose

**Break your own testbench and watch the grader say so.** Open your finished
`tb/tb_full_adder.sv`, change one expected value to the wrong number, and run `make good`:

```
BAD     -- src/full_adder.sv: 1 mismatches against a KNOWN-GOOD adder.
          Either src/full_adder.sv is not the shipped one, or one of your
          expected values does not match the DD101 truth table.
```

Three different states — `THIN`, `BAD`, `GOOD` — and they mean three different things. A tool
that only said "fail" would have collapsed all three into one word.

**Test your own Lab 01 file.** `src/full_adder.sv` here is a shipped working adder so that
nobody is blocked. Copy your own over it and run `make` — if Lab 01 passed, this passes too,
and now the thing being tested and the thing testing it are both yours.

## Expected results

Every number here came from a run on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0,
Python 3.12.3. `make reference` reproduces all of it using `reference/tb_full_adder.sv`.

```
testbench            design                                  tested  errors  verdict
------------------------------------------------------------------------------------
yours, as shipped    src/full_adder.sv                            1       0  PASS  (THIN)
yours, as shipped    mutants/mut1_cin_ignored.sv                  1       0  PASS  (SLIPPED)
yours, as shipped    mutants/mut2_carry_needs_all_three.sv        1       0  PASS  (SLIPPED)
yours, as shipped    mutants/mut3_outputs_swapped.sv              1       0  PASS  (SLIPPED)
all eight rows       src/full_adder.sv                            8       0  PASS  (GOOD)
all eight rows       mutants/mut1_cin_ignored.sv                  8       4  FAIL  (CAUGHT)
all eight rows       mutants/mut2_carry_needs_all_three.sv        8       3  FAIL  (CAUGHT)
all eight rows       mutants/mut3_outputs_swapped.sv              8       6  FAIL  (CAUGHT)
```

`make` always exits 0 — the verdict is the text. `make grade` is the same run with an exit
status, and it prints `make: *** [Makefile:75: grade] Error 1` until every box is ticked.

`$finish called at 8000 (1ps)` appears after every one of these runs, passing or failing. It
means the testbench reached its last line after 8 nanoseconds of pretend time. It is scenery.

## Links

- Package: [`labs/lab-02-prove-it/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-02-prove-it)
- Guide: [Eight rows and no opinions](guide/eight-rows-and-no-opinions.md) ·
  [What a module actually is](guide/what-a-module-is.md)
- Drill: [HDLBits — Fadd](https://hdlbits.01xz.net/wiki/Fadd), if you want the same problem
  graded by somebody else's testbench
- Stuck? [Team Discord](https://discord.gg/hrJnP5UsGz)

Next: [Lab 03 — The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md), where eight rows stop
being all of them — and a testbench you wrote yourself, and believed, turns out to have missed
256 wrong answers.
