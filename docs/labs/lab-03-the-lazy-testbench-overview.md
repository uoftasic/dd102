# Lab 03: The lazy testbench

Four full adders in a row make a 4-bit adder with nine input bits, so it has $2^9 = 512$
possible inputs: still few enough to check every one, and far too many to write out by hand. In
this lab you meet two broken 4-bit adders that pass a handful of sensible cases, find out exactly
how wrong each one is, find the first failure in a waveform, see which tool could have told you
before you wrote a test, and write the one case that would have caught the second bug. Then you
try a plausible fix that fixes nothing, and time a sweep of every input of an 8-bit adder.

Packages: [`labs/guide-examples-proving-it/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-proving-it)
for Parts 1 to 3 and Part 9, [`labs/lab-03-the-lazy-testbench/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-03-the-lazy-testbench)
for Parts 4 to 8.

## Before you start

- Finish [Lab 02](labs/lab-02-prove-it-overview.md): you have written a self-checking testbench
  and watched it catch three planted bugs.
- Read [Testbenches](guide/eight-rows-and-no-opinions.md) and
  [Waveforms](guide/two-lines-make-the-waveform-appear.md). This lab also wires four instances of
  one module together, which is what [Modules and instances](guide/what-a-module-is.md) covers.
- Work in a terminal on the noVNC desktop. Load `.designinit` and run `mod dd102` as in
  [Lab 01, Part 1](labs/lab-01-transcribe-your-adder-overview.md); that is how you get to the
  repo. The packages themselves need no environment setup, but the waveform viewers in Part 2
  need the desktop.

Time: about 2 hours. The Going further steps at the end are optional and not counted.

## Part 1: Six cases against a broken ripple adder

Do six careful cases show that a 4-bit adder works?

[`broken/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/broken/ripple4.sv)
is a 4-bit ripple adder somebody else wrote. Here it is, complete:

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

Don't go hunting for the bug yet. Its testbench,
[`src/tb_six_cases.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_six_cases.sv),
has six cases picked by hand in about five minutes. Each `try_one` call drives one case into the
adder, waits, compares the answer with the true sum and prints a line. It isn't a straw man; it
is what nearly everybody writes first, and every case is one that obviously matters.

1. Run the six cases:

   ```bash
   cd /foss/designs/modules/dd102/labs/guide-examples-proving-it
   make six
   ```

   You should see:

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

   Six for six: the zero case, the overflow case, the all-ones case, the case where the carry
   walks the whole way. If somebody showed you that transcript you would sign off on the design.

2. Now run every input the design can see:

   ```bash
   make sweep
   ```

   You should see:

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

   256 of 512. The design that passed six careful cases is wrong half the time. Only five
   `MISMATCH` lines print; 256 of them would scroll the `TESTED`/`ERRORS`/`VERDICT` block off
   your screen.

3. Exactly half is a clue to the shape of the bug, as [Testbenches](guide/eight-rows-and-no-opinions.md)
   explains. Ask the sweep which input the failures follow:

   ```bash
   make clue
   ```

   `make clue` runs the sweep again first, so its output repeats. After it you should see:

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

4. Which input do the failures follow? Find the line in the module above that causes it, and say
   why the six cases never saw it.

   <details>
   <summary>Answer</summary>

   Every bit of `a` and `b` is 128/128, so the failures are spread evenly across them and none
   of them is the cause. `cin` is 0 and 256: every failure has `cin = 1`. The port list declares
   `cin`, and then `assign c[0] = 1'b0;` ties the first carry to 0 instead of to `cin`, so the
   input is thrown away. It is a good adder that always adds zero instead of `cin`. Every one of
   the six cases had `1'b0` for `cin` (the `+ 0` in each line of step 1), so the testbench never
   tested the input the bug lives in.

   </details>

5. The repair is one line, `assign c[0] = cin;`, and the package already has the repaired file,
   [`src/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/ripple4.sv);
   you don't edit anything. Run the same sweep against it:

   ```bash
   make fixed
   ```

   You should see `TESTED 512`, `ERRORS 0`, `VERDICT PASS`.

## Part 2: Find the first failure in a waveform

Where in the sweep is the first failure, and what does it look like in a viewer?

The sweep in Part 1 also wrote a waveform file. `make` runs each testbench inside `results/`, so
the `sweep.vcd` named in the first line of its output is `results/sweep.vcd`. Run this part from
a terminal on the noVNC desktop. From anywhere else GTKWave prints
`Could not initialize GTK!  Is DISPLAY env var/xhost set?`, which means it correctly refuses to
draw into a text terminal, not that the install is broken.

1. Open the small one first, the eight rows of one full adder:

   ```bash
   make eight
   gtkwave results/eight.vcd views/eight.gtkw
   ```

   `make eight` reruns the eight-row testbench from Lab 02, Part 1 and writes
   `results/eight.vcd`. In GTKWave you should see `a`, `b` and `cin` stepping through all eight
   combinations over 0 to 160 ns, 20 ns per row, with `sum` and `cout` following. Check against
   [Waveforms](guide/two-lines-make-the-waveform-appear.md): `cin` changes twice as often as `b`
   and `b` twice as often as `a`; `sum` is 1 on rows 1, 2, 4 and 7 (counting from row 0); `cout`
   is high from 60 to 80 ns and from 100 to 160 ns.

2. Open the broken ripple adder's sweep with the signals already added:

   ```bash
   make wave
   ```

   This runs `gtkwave results/sweep.vcd views/sweep.gtkw`. The second argument is a save file,
   a plain-text list of which signals to show, in what order, at what zoom.
   [`views/sweep.gtkw`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/views/sweep.gtkw)
   is, apart from a few layout settings, a list of seven signal names.

   The sweep gives each input 20 ns and checks it 10 ns in, so the second input, 0 + 0 + 1, is
   checked at 30 ns. The save file parks GTKWave's marker there, where the log said
   `FIRST MISMATCH at 30 ns`. You should see the marker at 30 ns and
   the value column reading `a[3:0] =0`, `b[3:0] =0`, `cin =1`, `sum[3:0] =0`, `cout =0`,
   `expected[4:0] =01`, `mismatch =1` (the save file shows buses in hex). That is the failing
   case in one glance: 0 + 0 + 1, and the adder said 0, the same case as the first `MISMATCH`
   line in the log. `expected[4:0]` is red and reads `xx` for the first few nanoseconds: red
   means unknown, and that is normal at t = 0.

3. Open the same file in Surfer, which takes its signal list from a command file:

   ```bash
   make surfer
   ```

   This runs `surfer --command-file views/sweep.surf results/sweep.vcd`.
   [`views/sweep.surf`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/views/sweep.surf)
   is one `variable_add` per signal, then `zoom_fit`. You should see the whole run at once, with
   the `mismatch` row on for about half the trace in a regular stripe. Surfer labels its time
   axis in picoseconds, where GTKWave's toolbar shows `10240 ns` in its **To:** box: same run,
   different unit.

## Part 3: Ask the linter

Could a tool have found the dropped `cin` before you wrote a single test?

Neither the simulator nor the synthesizer complains about `broken/ripple4.sv`. On the workbench,
`iverilog -g2012 -o r.vvp broken/ripple4.sv src/full_adder.sv` compiles it without printing a
character and exits 0. `yosys -p "read_verilog -sv broken/ripple4.sv src/full_adder.sv; synth -top ripple4"`
exits 0 with a 582-line log whose only line containing *Warning* is
`ABC: Warning: The network is combinational (run "fraig" or "fraig_sweep").` The correct
`src/ripple4.sv` gives the same 582 lines and the same warning, which is about the shape of the
netlist and appears on every purely combinational design in this course. You don't need to run
either command.

Both tools are right to be quiet: an input you choose not to use is legal SystemVerilog, and
people do it on purpose. Verilator, the linter you ran in Lab 01, Part 3, reads your file without
simulating it and warns about its shape.

1. You'll lint two files: `broken/ripple4.sv` and `broken/full_adder.sv` (the adder from Lab 02,
   Part 2, with `&` where the Or should be, wrong on four of its eight rows). Write down which of
   them you expect Verilator to warn about.
2. Run Verilator with `-Wall` on both:

   ```bash
   make lint
   ```

   You should see `verilator exit 1` for `broken/ripple4.sv`, with

   ```
   %Warning-UNUSEDSIGNAL: broken/ripple4.sv:5:24: Signal is not used: 'cin'
   ```

   and `verilator exit 0` with `warnings: 0` for `broken/full_adder.sv`.

3. Verilator named the file, line, column and signal of the dropped `cin`. Why does it have
   nothing to say about the broken full adder?

   <details>
   <summary>Answer</summary>

   Nothing about it is malformed: every wire is driven, every input is used, every width
   matches. It is a well-written description of the wrong circuit.

   </details>

Lint before you believe a `PASS`, and never instead of one.

## Part 4: Write a few cases of your own

Now the lab's own adder.
[`src/add4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/src/add4.sv)
is four `full_adder` instances, the carry out of each feeding the carry in of the next. There is
no arithmetic in the file, only four boxes and some wires.

1. Go to the package:

   ```bash
   cd ../lab-03-the-lazy-testbench
   ```

2. Open [`tb/tb_lazy.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/tb/tb_lazy.sv)
   in a text editor. Three cases are in:

   ```
           //      a      b     cin
           try_one(4'd1,  4'd2, 1'b0);      // 1 + 2 = 3
           try_one(4'd3,  4'd4, 1'b0);      // 3 + 4 = 7
           try_one(4'd5,  4'd2, 1'b1);      // 5 + 2 + 1 = 8
   ```

3. Add three of your own, as `try_one` lines under the `// TODO` comment: the numbers you would
   put in a lab report to convince yourself a 4-bit adder works. Then run:

   ```bash
   make lazy
   ```

You should see:

```
tb_lazy: a few cases somebody thought were representative
TESTED 6
ERRORS 0
VERDICT PASS

PASS    -- your 6 hand-picked cases all agreed with add4.
           6 of the 512 inputs add4 can see. Write that fraction down.
```

Nothing is rigged. The expected value is computed in a five-bit variable, so nothing is rounded
off on the testbench's side. If one of your cases failed instead, you found the bug before this
lab showed it to you, and the grader (`src/check_run.py`, which `make` runs) says so. Keep going
anyway.

`make` then asks you to commit to a number in writing:

```
    Before you run the next stage, commit to a number:
    of add4's 512 possible inputs, how many does it get WRONG?
    Write it down. ______
```

4. That is printed text; `make` doesn't wait for an answer. Write your number on paper before you
   start Part 5.

## Part 5: Run all 512

How many of `add4`'s inputs are wrong, and what is the bug?

[`tb/tb_exhaustive.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/tb/tb_exhaustive.sv)
drives `add4` through every input: 16 values of `a`, times 16 of `b`, times 2 of `cin`.

1. Run it:

   ```bash
   make exhaustive
   ```

You should see:

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

and the grader's verdict, which won't say `MATCH` unless all four numbers (512 tested, 256
wrong, 120 and 136) are exactly right:

```
MATCH   -- 256 of 512 inputs are wrong. That is the reference number,
           to the digit: 120 of them with cin=0, 136 with cin=1,
           and 120 + 136 = 256.
```

256 of 512 again, the same headline number as the broken ripple adder in Part 1, from a
different bug. "Exactly half" tells you the bug is structural rather than a rare corner case. It
doesn't tell you which structure; the breakdown does. Run the count, then the breakdown, then
read the RTL.

2. The first failure in counting order is `0 + 15 + 1 : add4 said 0, the answer is 16`: zero plus
   fifteen plus one is zero, with no warning and no error. Open `src/add4.sv`. Where does the
   carry out of the top adder go?

   <details>
   <summary>Answer</summary>

   The file ends with a wire named `c4`, the carry out of the top adder. It is computed
   correctly, and it isn't in the port list, so it stops inside the module. $0 + 15 + 1 = 16$
   doesn't fit in four bits, which hold 0 to 15, and neither does anything up to
   $15 + 15 + 1 = 31$. The answer to a 4-bit addition is a 5-bit
   number, and with only four bits of room the top one is dropped without a sound.

   </details>

3. Check the 120 and 136 yourself. For which pairs $(a, b)$ is the 4-bit answer wrong when
   `cin = 0`, and when `cin = 1`? Count them.

   <details>
   <summary>Answer</summary>

   With `cin = 0` the answer is wrong exactly when $a + b \ge 16$. There is 1 way to make 30, 2
   ways to make 29, and so on down to 15 ways to make 16: $1 + 2 + \cdots + 15 = 120$.

   With `cin = 1` it is wrong when $a + b + 1 \ge 16$, which is $a + b \ge 15$: the same 120
   pairs plus the 16 pairs that sum to exactly 15, so $120 + 16 = 136$.

   $$120 + 136 = 256$$

   </details>

## Part 6: Let one more wire out

Does letting `c4` out of the module fix every input?

1. Compare [`reference/add5.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/reference/add5.sv)
   with `src/add4.sv`:

   ```bash
   diff src/add4.sv reference/add5.sv
   ```

   It has the same four instances, wired the same way. Apart from the header comments and the
   module name, you should see one added port, `output logic       cout`, and the last
   instance's `.cout(c4)` changed to `.cout(cout)`, with `c4` dropped from the internal wires:
   the top carry now leaves the module.
2. Run the same 512 inputs against it (this package's `make fixed`, not the one from Part 1):

   ```bash
   make fixed
   ```

You should see:

```
tb_exhaustive_fixed: all 512 inputs of add5
TESTED 512
ERRORS 0
VERDICT PASS

MATCH   -- 512 of 512 inputs correct, 0 mismatches.
```

Nothing inside the design was repaired; a wire that already existed was allowed out.

## Part 7: Catch it with one case

Your Part 4 cases passed on an adder that is wrong 256 times. Can one more hand-picked case
catch it?

1. Add one `try_one` line to `tb/tb_lazy.sv` whose true sum doesn't fit in four bits.
2. Run:

   ```bash
   make lazy
   ```

   You should see a `MISMATCH` line for your case and `VERDICT FAIL`. With `15 + 1 + 0` added to
   six cases that pass, the run printed:

   ```
   tb_lazy: a few cases somebody thought were representative
     MISMATCH  15 + 1 + 0 : add4 said 0, the answer is 16
   TESTED 7
   ERRORS 1
   VERDICT FAIL
   ```

   Your numbers will be your own. The grader's message starts
   `FAIL    -- one of your 7 cases disagreed with add4, and you found it`. That `FAIL` is your
   testbench's verdict on `add4`: it caught the bug, which is what you want.

3. Run `make` with no target. It runs Parts 4 to 6 in order (your cases, all 512, and `add5`)
   and ends with the verdict table. You should
   see `FOUND` in the first row, followed by the number of cases your testbench ran:

   ```
   ==============================================================
    VERDICT
   ==============================================================
    tb_lazy.sv        vs add4  (a few cases)  : FOUND   7
    tb_exhaustive.sv  vs add4  (all 512)      : MATCH   256/512
    tb_exhaustive_fixed.sv vs add5 (all 512)  : MATCH   0/512
   --------------------------------------------------------------
    The same design passed one testbench and failed another by 256 rows.
    The testbench was the variable, not the adder.
   ```

   `MATCH` in this table means the run agreed with the reference numbers, including the expected
   failures; it isn't a claim that the adder is right. The number after `MATCH` is wrong inputs
   out of 512.

4. Your Part 4 cases missed the bug, and so do the package's own six in `reference/tb_lazy.sv`
   (`make reference` runs them): the three you started with plus `0 + 0 + 0`, `6 + 9 + 0` and
   `7 + 7 + 1`. Why do sensible hand-picked cases miss it, and what should a testbench check
   when it can't check every input?

   <details>
   <summary>Answer</summary>

   Two of the package's cases add up to 15, the largest number `add4` can represent, which feels
   like testing the edge. The edge is one past the largest number, and hand-picked cases cluster
   inside the range you were thinking about. N bits plus N bits doesn't fit in N bits: every
   adder needs somewhere for the top carry to go, and every testbench needs a case that puts
   something there. When you can't check every input, check the boundaries rather than the
   middle. Of any passing test, ask how many of the possible inputs it tried.

   </details>

## Part 8: A five-bit sum inside the module

Does computing the sum in five bits inside the module fix it?

Here is what almost everybody tries first, and it is a reasonable thing to try: the answer needs
five bits, so make it five bits.
[`broken/add4_wider_inside.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-03-the-lazy-testbench/broken/add4_wider_inside.sv)
drops the four instances, computes the sum in one line into a five-bit wire, and drives the port
from it:

```systemverilog
    logic [4:0] wide;           // five bits, so nothing is lost HERE

    assign wide = a + b + cin;
    assign sum  = wide;         // ...and lost here instead, in silence
```

1. Predict the error count, then run:

   ```bash
   make trap
   ```

You should see the same 256, with the same split:

```
TESTED 512
ERRORS 256
  with cin=0 : 120
  with cin=1 : 136
VERDICT FAIL
```

The port is still four bits wide, so the fifth bit is discarded at the assignment instead of
inside the adder.

`make trap` compiles it with `iverilog -g2012 -Wall`, which exits 0. Its only warnings say that
`add4` and `full_adder` inherit their timescale from another file
(`warning: timescale for add4 inherited from another file.`). That only means one file declared
`` `timescale `` and the others didn't. It appears on healthy runs too and has nothing to do with
your bug.

`make trap` then runs Verilator with `-Wall`, the linter from Part 3:

```
%Warning-DECLFILENAME: broken/add4_wider_inside.sv:10:8: Filename 'add4_wider_inside' does not match MODULE name: 'add4'
%Warning-WIDTHTRUNC: broken/add4_wider_inside.sv:20:17: Operator ASSIGNW expects 4 bits on the Assign RHS, but Assign RHS's VARREF 'wide' generates 5 bits.
%Warning-UNUSEDSIGNAL: broken/add4_wider_inside.sv:17:17: Bits of signal are not used: 'wide'[4]
%Error: Exiting due to 3 warning(s)
exit status 1
```

(Verilator prints the source line and a documentation link under each warning; this keeps the
first line of each. The command is
`verilator --lint-only -Wall --top-module add4 broken/add4_wider_inside.sv src/full_adder.sv`.
`--top-module add4` says which module is the top; without it you get a fourth warning,
`MULTITOP`, about that ambiguity rather than your design.)

2. Which of the three warnings are about your bug, and what does each one say?

   <details>
   <summary>Answer</summary>

   The first warning is about the file name and isn't your bug: the package keeps a module
   called `add4` in a file called `add4_wider_inside.sv` on purpose, so you can compare it with
   `src/add4.sv` without renaming anything. The other two are your bug, said twice:
   `WIDTHTRUNC` says the assignment throws a bit away, and `UNUSEDSIGNAL` says the bit thrown
   away is bit 4, the carry.

   </details>

3. Run the linter on all three designs:

   ```bash
   make lint
   ```

You should see one warning on `src/add4.sv`, naming `c4`:

```
%Warning-UNUSEDSIGNAL: src/add4.sv:16:23: Signal is not used: 'c4'
%Error: Exiting due to 1 warning(s)
exit status 1
```

the same three warnings on `broken/add4_wider_inside.sv`, and `exit status 0` for
`reference/add5.sv`.

The linter knew about `c4` from the file alone, before you wrote a single test case: a wire that
is computed and goes nowhere is, in hardware, almost always dead logic or a dropped answer. A
width mismatch and an unused wire are both invisible to a simulator, because both are exactly
what the language says should happen, and a width mismatch is the most common way a
correct-looking design produces wrong numbers. `verilator --lint-only -Wall` finds both.

## Part 9: What "every input" costs

How long does checking every input take once the adder is 8 bits wide?

[`src/ripple8.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/ripple8.sv)
is the same adder with eight `full_adder` instances. It has 17 inputs, so $2^{17} = 131{,}072$
vectors.

1. Before you run it, guess the wall-clock time.

   ```bash
   cd ../guide-examples-proving-it
   make eight-bit
   ```

You should see:

```
tb_sweep8: all 131072 inputs of ripple8
TESTED 131072
ERRORS 0
VERDICT PASS
src/tb_sweep8.sv:40: $finish called at 2621440000 (1ps)
    wall 0.63 s
```

Your `wall` line will differ: repeated runs on the workbench landed between 0.59 and 0.63 s. The
`TESTED 131072` and `ERRORS 0` above it won't. [Testbenches](guide/eight-rows-and-no-opinions.md)
turns that rate into the cost of testing a 16-bit and a 32-bit adder this way, and in Lab 04,
Part 6 you work those costs out yourself.

## Finishing

### You're done when

`make` in `labs/lab-03-the-lazy-testbench/` ends with the verdict table from Part 7 and its first
row reads `FOUND`: a case you wrote caught the dropped carry.

`make` always exits 0; the verdict is the text. `make grade` runs the same three stages (lazy,
exhaustive and fixed; `make trap` is separate) and gives a script an exit status. It exits 0
whether the first row says `PASS` or `FOUND`, so read the table, not the exit status, to know
you're done. In `labs/guide-examples-proving-it/`, `make` with no target reruns the Part 1
testbenches (and Lab 02's) and prints one `PASS` per run that matches the reference numbers,
including the sweep that is supposed to fail. Those lines and the lab's reference numbers are on
[Expected results](reference/expected-results.md#lab-03-the-lazy-testbench).

### Questions

1. The broken ripple adder in Part 1 and `add4` are both wrong on exactly 256 of 512 inputs. How
   do you tell the two bugs apart without reading the RTL?

   <details>
   <summary>Answer</summary>

   Compare the breakdowns. In Part 1 every failure had `cin = 1` (Part 1, step 4), so the bug is
   in how `cin` gets in. In Part 5 the failures split 120 with `cin = 0` and 136 with
   `cin = 1`, and each one is a sum of 16 or more (Part 5, steps 2 and 3), so the bug is where
   the top carry goes.

   </details>

### Submit

Nothing to submit.

## Going further (optional)

1. In `labs/guide-examples-proving-it/`, open the sweep without the save file, to see what a fresh
   viewer looks like:

   ```bash
   gtkwave results/sweep.vcd
   ```

   You should see an empty, black wave pane. Nothing is broken: GTKWave doesn't guess which
   signals matter, and it opens zoomed in at time zero.
   [Reading a waveform](reference/reading-a-waveform.md) has the menus for adding signals and
   zooming out.

2. Run the eight-row testbench on [EDA Playground](https://www.edaplayground.com/), with the one
   Google login the DD courses ask for (see
   [Getting started](guide/getting-started.md#eda-playground-account)). Paste
   [`src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/full_adder.sv)
   into the **`design.sv`** tab and
   [`src/tb_eight_rows.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_eight_rows.sv)
   into **`testbench.sv`**, set the simulator to **Icarus Verilog 12.0**, tick **Open EPWave after
   run** and click **Run**. You should see the log and the waveform in a new EPWave window. The
   site says *"(Pop-ups must be enabled.)"*: a browser that blocks the pop-up does it silently,
   leaving you a successful run and no picture. Then run
   [`src/tb_eight_rows_compact.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_eight_rows_compact.sv)
   the same way. You should see the `sorry:` message that
   [Waveforms](guide/two-lines-make-the-waveform-appear.md) explains; the same file prints
   `VERDICT PASS` on your workbench's Icarus 14.0.
3. [HDLBits Exams/m2014 q4j](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j) is a 4-bit ripple
   adder built from full adders and graded by somebody else's testbench.

Stuck? Ask in the [team Discord](https://discord.gg/hrJnP5UsGz).

Next on the [Course path](README.md#course-path): read
[Vectors, generate loops and parameters](guide/four-adders-in-a-row.md), then do
[Lab 04: Four adders in a row](labs/lab-04-four-adders-in-a-row-overview.md).
