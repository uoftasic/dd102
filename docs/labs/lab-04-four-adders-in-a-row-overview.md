# Lab 04: Four adders in a row

In Lab 03 you read `add4.sv`: four `full_adder` instances typed one after another, with an index
and an instance name changed on every line. It worked, it gave you four chances to get an
index wrong, and typing it out stops being practical somewhere around thirty-two bits. In this
lab you run a `generate for` loop that replaces those four lines, have Yosys prove the loop
built the same circuit, break the loop by one character, and change the width with one number.
Then you rewrite the loop yourself and prove your rewrite changed nothing.

Packages: [`labs/reference-card/`](https://github.com/uoftasic/dd102/tree/main/labs/reference-card)
for Part 1, [`labs/lab-04-four-adders-in-a-row/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-04-four-adders-in-a-row)
for the rest.

## Before you start

- Finish [Lab 03](labs/lab-03-the-lazy-testbench-overview.md): you have read `add4.sv` and
  `add5.sv`, and you know why the first is wrong on 256 of 512 inputs.
- Read [Vectors, generate loops and parameters](guide/four-adders-in-a-row.md).
- In a terminal on the workbench desktop, get to the repo and check Yosys:

  ```bash
  . /foss/designs/common/.designinit
  mod dd102
  yosys -V                 # expect: Yosys 0.68
  ```

  Those first two lines are how you get to the repo. The tools are already on your `PATH`, and
  no package in this lab needs `.designinit` or a PDK, so `make` still runs if your environment
  is half broken.

Time: about 1¾ hours.

## Part 1: Run the reference cards

Do the constructs on the guide page print what the page says they print?

[The DD102 subset](reference/the-dd102-subset.md) is twelve one-file examples, one per construct
this course uses. Four of them are the constructs in this lab's guide page.

1. Run all twelve:

   ```bash
   cd labs/reference-card
   make
   ```

   You should see twelve `PASS` lines and `VERDICT PASS  — all 12 cards match the reference run.`
   It takes about 0.3 seconds. Find these four lines and check them against the guide page:

   ```
   PASS  02_logic_and_vectors   a=1001 y=0110 a[3]=1 a[2:1]=00
   PASS  08_generate_for        9+9+0 -> cout=1 sum=2 (= 18)
   PASS  09_parameter           N=4 -> 00001111   N=6 -> 00111111
   PASS  11_width_truncation    9+9 -> narrow[3:0]=2  wide[4:0]=18
   ```

2. Run card 11 on its own:

   ```bash
   make card N=11
   ```

   You should see:

   ```
   --- src/11_width_truncation.sv
   11_width_truncation: 9+9 -> narrow[3:0]=2  wide[4:0]=18
   ```

3. Same two inputs, same `+`. Why is one answer 18 and the other 2?

   <details>
   <summary>Answer</summary>

   `narrow` is declared `[3:0]` and `wide` is `[4:0]`. 18 is `1_0010` in binary; four bits keep
   `0010`, which is 2.

   </details>

## Part 2: Run the loop on all 512 inputs

Does one loop build four separate adders, and do they add correctly?

The design is [`src/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple4.sv).
Its loop:

```systemverilog
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : slice
        full_adder fa (
            .a    (a[i]),
            .b    (b[i]),
            .cin  (c[i]),
            .sum  (sum[i]),
            .cout (c[i+1])
        );
    end
endgenerate
```

1. Go to the package and run the first experiment:

   ```bash
   cd ../lab-04-four-adders-in-a-row
   make generate
   ```

   `tb/tb_ripple4.sv` drives all $2^9 = 512$ inputs.

You should see:

```
iverilog -g2012 -o results/generate.vvp tb/tb_ripple4.sv src/ripple4.sv src/full_adder.sv
VCD info: dumpfile ripple4.vcd opened for output.

PASS  0 mismatches out of 512
tb/tb_ripple4.sv:48: $finish called at 10240000 (1ps)
```

and then what the loop built:

```
--- and what the loop actually built ---
Found and reported 0 problems.
        4   full_adder
        4   full_adder
```

Four adders, each its own piece of hardware. The count appears twice because Yosys prints it
once for the module and once for the whole hierarchy. `Found and reported 0 problems.` comes
from Yosys's `check` pass, which reads the netlist and looks for structural mistakes, mainly
wires that nothing drives. You'll need it in Part 4.

## Part 3: Prove the loop equals the hand-typed version

Is the loop the same circuit as four hand-typed instances, for every input?

You tested 512 inputs, which happens to be all of them for a 4-bit adder. Make the design 16 bits
wide and the same 512 cases cover $512 / 2^{33}$ of the input space, one sixteen-millionth.
A proof doesn't have that problem.

1. Run:

   ```bash
   make proof
   ```

   [`scripts/proof.ys`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/scripts/proof.ys)
   builds a **miter**: a circuit that holds both your generate version and
   [`reference/ripple4_hand.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/reference/ripple4_hand.sv)
   (four hand-typed instances, the Lab 03 style), feeds them the same inputs, and raises one
   wire called `trigger` if their outputs ever differ. Then it asks a SAT solver for any input
   that makes `trigger` go high.

You should see:

```
Solving problem with 294 variables and 751 clauses..
SAT proof finished - no model found: SUCCESS!
```

followed by nine lines of `Q.E.D.` drawn in dollar signs. That banner is Yosys celebrating;
`make proof` prints it on purpose so it doesn't surprise you.

2. What does "no model found" claim, and why is it stronger than "512 tests passed"?

   <details>
   <summary>Answer</summary>

   The solver exhausted the possibilities: there is no input for which the two circuits
   disagree. A test covers the inputs you ran; a proof covers all of them, which is what you need
   once a design is too wide to test every input.

   </details>

When you refactor RTL and want to know you didn't change its behaviour, this is the question
you're asking. The core of `scripts/proof.ys` is `miter -equiv -flatten A B m; sat -verify -prove trigger 0 m`,
with `A` and `B` the two modules. You'll ask it of
your own rewrite in Part 7.

## Part 4: Break the loop bound

What does one wrong digit in the loop bound do, and which tools tell you?

`broken/ripple4.sv` is `src/ripple4.sv` with one digit changed: the loop reads
`for (i = 0; i < 3; i = i + 1)`. (If you `diff` the two files you'll also see a different header
comment; the loop bound is the only line that does anything.)

1. Write down how many of the 512 inputs you expect to fail. The missing slice is bit 3, the top
   bit.
2. Run:

   ```bash
   make broken
   ```

You should see:

```
  a=0 b=0 cin=0   want 0   got Z
  a=0 b=0 cin=1   want 1   got Z
  a=0 b=1 cin=0   want 1   got Z
  a=0 b=1 cin=1   want 2   got Z
  a=0 b=2 cin=0   want 2   got Z

  ... and 507 more not shown
FAIL  512 mismatches out of 512, first at t = 10 ns
vvp exit status 0   (zero. read the verdict, not the exit code.)
```

3. All 512 fail, including `0 + 0 + 0`, which doesn't involve bit 3 at all. Most people write down
   something between 128 and 384. Why is it every input, and what does the `Z` mean?

   <details>
   <summary>Answer</summary>

   "Bit 3 only matters some of the time" answers a different question, "how often does bit 3
   change the result?", which would be the right question if the loop had computed bit 3
   wrongly. It didn't compute it at all. `sum[3]` and `cout` are connected to nothing, because
   the loop never generated the instance that would drive them, and an undriven wire in Verilog
   isn't `0`. It is `z`, "nobody is driving this", one of the four values a wire can hold. The
   testbench compares with `!==`, which compares all four values, and `z !== 0` is true. So the
   top bit of every answer is wrong, which makes every answer wrong.

   </details>

A `Z` in a result is never an arithmetic bug; it means nothing drives that wire. You don't have
to read RTL to find which one. `make broken` runs this next:

```bash
yosys -p "read_verilog -sv broken/ripple4.sv src/full_adder.sv; hierarchy -top ripple4; check"
```

You should see:

```
Warning: Wire ripple4.\sum [3] is used but has no driver.
Warning: Wire ripple4.\c [4] is used but has no driver.
Found and reported 2 problems.
```

and an instance count of 3 `full_adder` where the good design had 4. Then it runs the Part 3
proof against the broken design:

```
yosys exit status 1   (one. this tool DOES tell you.)
  Signal Name             Dec       Hex           Bin
  --------------- ----------- --------- -------------
  \in_a                    14         e          1110
  \in_b                     8         8          1000
  \in_cin                   1         1             1
  \trigger                  1         1             1
```

(`c[4]` is `cout`: the last line of the module is `assign cout = c[4];`.) The solver hands you an
input: `a = 14`, `b = 8`, `cin = 1`. $14 + 8 + 1 = 23$, which is `1_0111`, five bits wide, and
the fifth bit is `cout`, one of the two wires nothing drives.

Three tools just described the same one-character bug three ways: a simulator said `Z`, a
structural check named the wires, and a solver produced the input. None of them said "line 15",
where the loop bound is in `broken/ripple4.sv`.

## Part 5: `i++` and a block named `bit`

Which of two claims about generate loops is true on this workbench?

1. Run:

   ```bash
   make gotcha
   ```

The first claim is "you can't write `i++` in a generate for". You'll hear it in forum answers
and other people's course notes. You should see:

```
 4a. FOLKLORE: 'you cannot write i++ in a generate for'
yosys exit status 0
        9   SB_LUT4
```

`errors/ripple4_incr.sv` is your adder with `i++` instead of `i = i + 1`. With Yosys 0.68 and
`-sv` it reads, elaborates and synthesizes to the same 9 lookup tables as `src/ripple4.sv`. (The
line `make gotcha` prints under the count says "same 8 SB_LUT4"; that text is out of date, and
the 9 above it is the real count.) Icarus 14.0 accepts it too. `src/ripple4.sv` still uses
`i = i + 1`, because that form is Verilog-2001 and works in every tool that has ever existed, at
a cost of six characters. But you settled the question by running it rather than by taking a
page's word for it.

The second claim is "you can't label a generate block `bit`". This one is true:

```
 4b. TRUE: 'you cannot label a generate block bit'
yosys exit status 1
errors/ripple4_bit.sv:19: ERROR: syntax error, unexpected TOK_LOGIC, expecting TOK_ID
```

`bit` is a SystemVerilog data type, like `logic` or `int`, so you can't use it as a name. The
parser says so in its own vocabulary: it wanted an identifier (`TOK_ID`) and found a type keyword.
`slice`, `stage`, `lane` and `bitslice` are fine; `bit`, `byte`, `wire`, `reg` and `logic` are
not. Then the same file through Icarus:

```
--- the same file through Icarus. Brace yourself. ---
iverilog exit status 134
errors/ripple4_bit.sv:19: syntax error
errors/ripple4_bit.sv:26: error: Invalid module item.
errors/ripple4_bit.sv:27: syntax error
errors/ripple4_bit.sv:30: error: Invalid module item.
errors/ripple4_bit.sv:7: assert: pform.cc:1575: failed assertion lexical_scope == cur_module
Aborted (core dumped)
```

A one-word typo crashed the compiler: `Aborted (core dumped)`, exit status 134, and a line naming
a C++ source file you have never seen. You haven't broken your install and there is nothing to
reinstall. Line 19 is the real error; lines 26, 27, 30, 7 and the crash are fallout. Once a
parser loses its place it stays lost, and the noise it makes is proportional to how confused it
is, not to how bad your mistake was. Fix the first error line and re-run: never the last line,
and never all of them.

## Part 6: Change one number

What does a wider adder cost, and how long would it take to test every input?

[`src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv)
is the same design with `parameter int N = 4`, `logic [N-1:0]` on the ports, and
`for (i = 0; i < N; i = i + 1)`.

1. Run:

   ```bash
   make wide
   ```

You should see:

```
  N = 4   ->         9   SB_LUT4
  N = 8   ->        18   SB_LUT4
  N = 16  ->        37   SB_LUT4
  N = 32  ->        74   SB_LUT4
```

Just over two lookup tables per bit at every width, and the file didn't get longer. (`SB_LUT4`
is the FPGA cell your logic lands on. It is the subject of Lab 05; until then, treat it as a unit
of logic.) Then the same target runs the exhaustive test twice:

```
N = 4   512 cases
PASS  0 mismatches out of 512
N = 8   131072 cases
PASS  0 mismatches out of 131072
```

An $N$-bit adder has $2N + 1$ input bits, so exhaustive testing means $2^{2N+1}$ cases. These
wall-clock times are single runs on the machine these pages were written on; unlike every other
number in this course, yours will be close rather than identical:

| Width | Cases | Time |
|---|---|---|
| 4 bits | 512 | too fast to measure |
| 8 bits | 131,072 | 0.78 s |
| 10 bits | 2,097,152 | 14.77 s |
| 12 bits | 33,554,432 | 264.08 s |

2. That is roughly 127,000 cases per second at 12 bits, and the rate falls as the adder gets
   wider. At that rate, how long would an exhaustive test of a 16-bit adder take, and of a
   32-bit adder? Write both down.

   <details>
   <summary>Answer</summary>

   A 16-bit exhaustive test is $2^{33} = 8{,}589{,}934{,}592$ cases, about 19 hours, and that
   estimate is optimistic. A 32-bit one is $2^{65}$ cases, about 9.2 million years at the same
   rate.

   </details>

Your 4-bit adder is one of the last designs you'll be able to test by trying everything. After
it, designs are tested by choosing cases well (Lab 03) or by proving (Part 3).

## Part 7: Rewrite the loop and prove it

Does your own rewrite of the loop still build the same adder?

You'll edit `src/ripple4.sv` in this package. Lab 05 ships its own copy, so editing this one
breaks nothing there; in Lab 05, Part 8 you copy your edited file across on purpose.

1. In `src/ripple4.sv`, change the loop header so it uses `i++` and a block label of your own
   instead of `slice`. Any name that isn't a keyword works (Part 5); for example:

   ```systemverilog
   for (i = 0; i < 4; i++) begin : stage
   ```

2. Run `make proof`. You should see the same
   `SAT proof finished - no model found: SUCCESS!` as in Part 3, from the same
   `Solving problem with 294 variables and 751 clauses..`.

3. Now plant the Lab 03 bug in your copy: change `assign c[0] = cin;` to
   `assign c[0] = 1'b0;`. Before you run anything, write down what the solver's counterexample
   will have for `cin`.

4. Run `make proof`. The proof fails, and this target stops before printing anything after the
   `yosys` line:

   ```
   yosys scripts/proof.ys > results/proof.log 2>&1
   make: *** [Makefile:46: proof] Error 1
   ```

   Read the counterexample from the log:

   ```bash
   grep -A6 "Signal Name" results/proof.log
   ```

   You should see:

   ```
     Signal Name             Dec       Hex           Bin
     --------------- ----------- --------- -------------
     \in_a                     8         8          1000
     \in_b                    15         f          1111
     \in_cin                   1         1             1
     \trigger                  1         1             1
   ```

5. Why does the counterexample have to have `cin = 1`?

   <details>
   <summary>Answer</summary>

   With `cin = 0`, tying the first carry to 0 changes nothing, so the two designs agree on every
   input with `cin = 0`. Any input that makes `trigger` go high has `cin = 1`. Here the hand-typed
   version computes $8 + 15 + 1 = 24$ and yours computes $8 + 15 = 23$.

   </details>

6. Put `assign c[0] = cin;` back, keep your new loop header, and run `make`. You should see the
   twelve `PASS` lines listed under Finishing.

## Finishing

### You're done when

`make proof` prints `SUCCESS!` for your rewritten loop in `src/ripple4.sv` (`grep -n "i++"
src/ripple4.sv` shows it), and `make` ends with these twelve verdicts, all `PASS`:

```
PASS  generate      got PASS 0/512, reference says PASS 0/512   (src/ripple4.sv, all 512 inputs)
PASS  clean         `check` on src/ripple4.sv -- nothing undriven, 4 full adders
PASS  proof         Yosys proved generate == hand-typed, for every input
PASS  broken        got FAIL 512/512, reference says FAIL 512/512   (broken/ripple4.sv, all 512 inputs)
PASS  undriven      `check` names the two undriven wires and counts 3 full adders
PASS  proof_broken  the same proof against broken/ripple4.sv -- fails on purpose
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
PASS  luts8         ripple #(.N(8))  -> 18 SB_LUT4
PASS  luts16        ripple #(.N(16)) -> 37 SB_LUT4
PASS  luts32        ripple #(.N(32)) -> 74 SB_LUT4
PASS  wide4         got PASS 0/512, reference says PASS 0/512   (ripple #(.N(4)), all 512 inputs)
PASS  wide8         got PASS 0/131072, reference says PASS 0/131072   (ripple #(.N(8)), all 131072 inputs)
```

`make` finishes in under five seconds. `make check` re-runs the verdicts on the logs you already
have. The lab's reference numbers and what to do when a line says `FAIL` are on
[Expected results](reference/expected-results.md#lab-04-four-adders-in-a-row).

### Questions

1. Three of the twelve lines, `broken`, `undriven` and `proof_broken`, describe a failure. Why do
   they say `PASS`?

   <details>
   <summary>Answer</summary>

   They say PASS when the broken design fails exactly as hard as the reference run says it
   should. A checker that only knows what success looks like can't tell you that a deliberate
   failure stopped working.

   </details>

### Submit

Nothing to submit.

## Going further (optional)

1. Send reference card 8, the generate loop, through the iCE40 synthesizer: `make synth` in
   `labs/reference-card/`. You should see `yosys exit 0`, then a `stat` block that includes:

   ```
          13 cells
           4   $scopeinfo
           9   SB_LUT4
   ```

   The four `$scopeinfo` are bookkeeping, one per `full_adder` instance, not hardware. Nine
   `SB_LUT4` is what four hand-written instances cost too, because the loop *is* four instances.
   (The note `make synth` prints under the table still says "Eight SB_LUT4"; that text is out of
   date, and the count above it is the real one.)

2. `make wide12` runs the 12-bit exhaustive test from the Part 6 table, 33,554,432 cases, if you
   want to watch it take its four and a half minutes.

Your `src/ripple4.sv` goes through the FPGA flow in Lab 05, Part 8, and DD103 turns the same
design into silicon.

Next on the [Course path](README.md#course-path): read [Carry delay](guide/the-carry-has-to-travel.md)
and [Inside an FPGA](guide/the-chip-is-already-there.md), then do
[Lab 05: Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md).
