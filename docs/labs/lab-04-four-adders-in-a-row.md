# Lab 04 — Four adders in a row

Full runnable package:
[`labs/lab-04-four-adders-in-a-row/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-04-four-adders-in-a-row).

**The question this lab answers:** *I copied the same line four times and changed one digit
each time. Is that really how professionals do it?*

No. And the reason is not tidiness.

In [Lab 03](labs/lab-03-the-lazy-testbench.md) you read `add4.sv`: four `full_adder`
instances typed out one after another — `fa0`, `fa1`, `fa2`, `fa3` — with five indices and an
instance name changed on every line. It worked. It also gave you four separate opportunities to
get an index wrong, and it stops being possible somewhere around thirty-two bits.

This lab replaces those four lines with one loop, and then does the thing that actually
matters: it **proves** the loop built the same circuit.

Five experiments. Two of them ask you to commit to a number before you look, and both are
designed so that the number you write down is wrong.

## Prerequisites

- [IC101](https://uoftasic.com/ic101/) complete — the workbench desktop launches
- DD102 cloned under `workspace/modules/dd102`
- [Lab 03](labs/lab-03-the-lazy-testbench.md) done: you have read `add4.sv` and `add5.sv`,
  four hand-typed instances each, and you know why the first one is wrong on 256 of 512 inputs
- Read [Four adders in a row](guide/four-adders-in-a-row.md)
- `yosys -V` says **`0.64`** and `iverilog -V` starts with **`14.0`**

## Objectives

- Replace four repeated instantiations with one `generate for` and know exactly what the
  elaborator did with it
- Read the names the loop generates — `slice[2].fa` — and recognise them later in a tool report
- Have Yosys **prove** two designs equal for every input, and read the counterexample when
  they are not
- Diagnose an undriven wire from a `Z` in a testbench, with one command and no RTL reading
- Say why exhaustive testing works at four bits and is finished at sixteen

## Theory (short)

A `generate for` is **not a loop in your hardware.** Nothing loops. The loop runs once, in
the tool, before simulation or synthesis begins — during a phase called **elaboration** — and
what comes out the other side is four separate `full_adder` instances sitting side by side,
exactly as if you had typed them.

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

> **This is an excerpt.** The complete file is
> [`src/ripple4.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple4.sv)
> in the lab package, and it is the one `make` runs. Nothing on this page needs saving to disk.

Three things to notice.

**`genvar` is not a wire.** It is a compile-time integer that exists only while the loop is
being unrolled. There is no `i` anywhere in the resulting circuit. That is why it gets its own
keyword instead of being `int`.

**The label after `begin :` becomes part of every generated name.** With `begin : slice`, the
four adders are called `slice[0].fa` through `slice[3].fa`. This is not decoration. In
[Lab 05](labs/lab-05-onto-the-fpga.md) the place-and-route tool prints a timing report that
says `slice[2].fa.sum_SB_LUT4_O_I3[2]`, and that string is the only reason you can tell which
of the four bits the delay is in. **Name the block after the thing it is, and the tools will
talk back to you in your own words.**

**The carry chain is written by the indices, not by you.** `c[i]` in, `c[i+1]` out, and
`c` declared one bit wider than the adder. Get the loop's *bound* wrong and it still builds,
quietly, with a piece missing — experiment 3 is exactly that.

## Procedure

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-04-four-adders-in-a-row
yosys -V                 # expect: Yosys 0.64
make                     # all five experiments, under five seconds
```

Each experiment is also a target on its own: `make generate`, `make proof`, `make broken`,
`make gotcha`, `make wide`.

**Nothing in this lab needs `.designinit` or a PDK.** Those two lines are how you get the
*repo*; the tools are already on your `PATH`. If your environment is half-broken, `make` still
runs and still tells you the truth. That is the point of it.

### 1 — One loop, four adders, 512 inputs

```
make generate
```

A 4-bit adder has 4 + 4 + 1 = 9 input bits, so it has $2^9 = 512$ possible inputs, and
`tb/tb_ripple4.sv` drives every one of them:

```
iverilog -g2012 -o results/generate.vvp tb/tb_ripple4.sv src/ripple4.sv src/full_adder.sv
VCD info: dumpfile ripple4.vcd opened for output.

PASS  0 mismatches out of 512
tb/tb_ripple4.sv:48: $finish called at 10240000 (1ps)
```

Then the same target asks Yosys what the loop actually built:

```
--- and what the loop actually built ---
Found and reported 0 problems.
        4   full_adder
        4   full_adder
```

Four. Not one adder used four times — **four adders**, each with its own transistors, sitting
next to each other. The line appears twice because Yosys prints the count once for the module
and once for the whole hierarchy; both say 4.

> `Found and reported 0 problems.` comes from Yosys's `check` pass, which reads the netlist
> and looks for structural mistakes — mainly wires that nothing drives. Remember that it exists.
> You are about to need it.

### 2 — 512 is not the same as "every input"

Here is an uncomfortable fact about the previous step. You tested 512 inputs. That happens to
be *all* of them for a 4-bit adder, so you got away with it. Change the design to 16 bits and
the same 512 cases cover $512 / 2^{33}$ of the input space — **one sixteen-millionth** of it.

There is a stronger tool, and it is one command:

```
make proof
```

`scripts/proof.ys` builds a **miter** — a circuit that holds both your generate version and
`reference/ripple4_hand.sv` (four hand-typed instances, the Lab 03 style), feeds them the same
inputs, and raises one wire called `trigger` if their outputs ever differ. Then it asks a SAT
solver to find any input that makes `trigger` go high.

```
Solving problem with 294 variables and 751 clauses..
SAT proof finished - no model found: SUCCESS!
```

**It could not find one, and it did not give up — it exhausted the possibilities.** There is
no input, at all, ever, for which those two circuits disagree. That is a different and much
stronger claim than "512 tests passed".

> **Yosys prints ASCII art when it wins.** Immediately after `SUCCESS!` you get a large
> banner reading `Q.E.D.` drawn in dollar signs, nine lines of it. Nothing is wrong. It is
> Yosys being pleased with itself, and `make proof` prints it deliberately so it is not a
> surprise.

**Reflex:** two designs, one command —
`miter -equiv -flatten A B m; sat -verify -prove trigger 0 m`. When you refactor RTL and want
to know you did not change its behaviour, that is the question you are actually asking.

### 3 — One character, and every single test fails

`broken/ripple4.sv` is `src/ripple4.sv` with one digit changed: the loop reads
`for (i = 0; i < 3; i = i + 1)`. (`diff` on the two files also shows a different header comment.
The loop bound is the only line that does anything.)

**Before you run anything, write down a number.** Of the 512 inputs, how many do you expect to
fail? The missing slice is bit 3, the top bit. Most people reason that bit 3 only matters some
of the time, and write down something between 128 and 384.

```
make broken
```

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

**512 out of 512.** Including `0 + 0 + 0`, which does not involve bit 3 at all.

Here is the arithmetic that closes the gap. Look at the third column: not a wrong number, but
`Z`. `sum[3]` and `cout` are connected to nothing — the loop never generated the instance that
would drive them — and an undriven wire in Verilog is not `0`. It is `z`, "nobody is driving
this", one of the four values a wire can hold. The testbench compares with `!==`, which
compares all four values, and `z !== 0` is true. So the top bit of *every* answer is wrong,
which makes *every* answer wrong, which is why `0 + 0 + 0` fails.

Your prediction was not sloppy. It was the answer to a different question — "how often does
bit 3 change the result?" — and that question would have been the right one if the loop had
computed bit 3 *wrongly*. It did not compute it at all.

**Reflex: a `Z` in a result is never an arithmetic bug.** It means nothing is driving that
wire. And you do not have to read any RTL to find out which wire:

```bash
yosys -p "read_verilog -sv broken/ripple4.sv src/full_adder.sv; hierarchy -top ripple4; check"
```

```
Warning: Wire ripple4.\sum [3] is used but has no driver.
Warning: Wire ripple4.\c [4] is used but has no driver.
Found and reported 2 problems.
```

Two seconds, no simulation, and it names both wires. `make broken` also prints the instance
count — **3 `full_adder`**, where the good one said 4.

Then the same target runs the proof from experiment 2 against the broken design:

```
yosys exit status 1   (one. this tool DOES tell you.)
  Signal Name             Dec       Hex           Bin
  --------------- ----------- --------- -------------
  \in_a                    14         e          1110
  \in_b                     8         8          1000
  \in_cin                   1         1             1
  \trigger                  1         1             1
```

It did not just say "wrong". It handed you an input: `a = 14`, `b = 8`, `cin = 1`. That sum is
$14 + 8 + 1 = 23$, which is `1_0111` — five bits wide, and the fifth bit is `cout`, one of the
two wires nothing drives.

> **Reading a FAIL is a skill, and the best time to practise is when you caused it on purpose.**
> Three tools just described the same one-character bug three different ways: a simulator said
> `Z`, a structural check named the wires, and a solver produced the input. None of them said
> "line 15".

### 4 — Two things people say about generate loops

```
make gotcha
```

**Claim one: "you cannot write `i++` in a generate for."** You will hear this. It is in forum
answers and in other people's course notes.

```
 4a. FOLKLORE: 'you cannot write i++ in a generate for'
yosys exit status 0
        8   SB_LUT4
    ^ same 8 SB_LUT4 as src/ripple4.sv. On THIS workbench, folklore.
```

`errors/ripple4_incr.sv` is your adder with `i++` instead of `i = i + 1`. On Yosys 0.64 with
`-sv` it reads, elaborates and synthesises to the identical eight lookup tables. Icarus 14.0
accepts it too.

We still write `i = i + 1` in `src/ripple4.sv`, and the reason is honest rather than
technical: that form is Verilog-2001, it works in every tool that has ever existed, and it
costs you six characters. But **the way you settled this question was to run it**, not to
believe a page — including this one.

**Claim two: "you cannot label a generate block `bit`."** This one is true, and it fails hard.

```
 4b. TRUE: 'you cannot label a generate block bit'
yosys exit status 1
errors/ripple4_bit.sv:19: ERROR: syntax error, unexpected TOK_LOGIC, expecting TOK_ID
```

`bit` is a SystemVerilog **data type**, like `logic` or `int`. You cannot use it as a name, and
the parser tells you so in its own vocabulary: it wanted an identifier (`TOK_ID`) and found a
type keyword. `slice`, `stage`, `lane`, `bitslice` are all fine. `bit`, `byte`, `wire`, `reg`
and `logic` are not.

Now the same file through Icarus:

```
--- the same file through Icarus. Brace yourself. ---
iverilog exit status 134
errors/ripple4_bit.sv:19: syntax error
errors/ripple4_bit.sv:26: error: Invalid module item.
errors/ripple4_bit.sv:27: syntax error
errors/ripple4_bit.sv:30: error: Invalid module item.
errors/ripple4_bit.sv:7: assert: pform.cc:1478: failed assertion lexical_scope == cur_module
Aborted (core dumped)
```

**A one-word typo crashed the compiler.** `Aborted (core dumped)`, exit status 134, and a line
naming a C++ source file you have never seen. You have not broken your install, and there is
nothing to reinstall.

Look at the shape of it: **line 19 is the real error, and lines 26, 27, 30, 7 and the crash
are all fallout.** Once a parser loses its place it stays lost, and the noise it makes on the
way down is proportional to how confused it is, not to how bad your mistake was.

**Reflex: fix the first error line, then re-run. Never the last one, and never all of them.**
[Getting started](guide/getting-started.md) said this about pipes; it is the same rule.

### 5 — Change one number, get a different adder

The real payoff of the loop is not that it is shorter. It is that the loop bound can be a
parameter. `src/ripple.sv` is the same design with `parameter int N = 4`, `logic [N-1:0]` on
the ports, and `for (i = 0; i < N; i = i + 1)`.

```
make wide
```

```
  N = 4   ->         8   SB_LUT4
  N = 8   ->        16   SB_LUT4
  N = 16  ->        32   SB_LUT4
  N = 32  ->        64   SB_LUT4
```

Two lookup tables per bit, exactly, at every width — one for the sum, one for the carry. The
file did not get longer. (`SB_LUT4` is the FPGA cell your logic lands on; that is
[Lab 05](labs/lab-05-onto-the-fpga.md)'s whole subject and you can treat it as "a unit of
logic" until then.)

Then the same target runs the exhaustive test twice:

```
N = 4   512 cases
PASS  0 mismatches out of 512
N = 8   131072 cases
PASS  0 mismatches out of 131072
```

**Now do the arithmetic before you type anything.** An $N$-bit adder has $2N + 1$ input bits,
so exhaustive means $2^{2N+1}$ cases. Here is what that costs. These four wall-clock times are
from single runs on the machine these pages were written on — unlike every other number in this
course, yours will be close rather than identical:

| width | cases | time |
|---|---|---|
| 4 bits | 512 | too fast to measure |
| 8 bits | 131,072 | 0.78 s |
| 10 bits | 2,097,152 | 14.77 s |
| 12 bits | 33,554,432 | 264.08 s (`make wide12`, if you want to watch) |

That is roughly 127,000 cases per second at 12 bits, and the rate falls as the adder gets
wider. So a **16-bit** exhaustive test is $2^{33} = 8{,}589{,}934{,}592$ cases —
about **19 hours**, and that estimate is optimistic. A **32-bit** one is $2^{65}$ cases, which
at the same rate is **about 9.2 million years**.

Your 4-bit adder is one of the last designs in your career that you can test by trying
everything. Everything after it is tested by choosing well — the six cases of Lab 03 — or by
proving, as in experiment 2. **That is why the proof was in this lab.**

### The self-check

`make check` re-runs every verdict against the reference numbers without re-running the
experiments:

```
PASS  generate      got PASS 0/512, reference says PASS 0/512   (src/ripple4.sv, all 512 inputs)
PASS  clean         `check` on src/ripple4.sv -- nothing undriven, 4 full adders
PASS  proof         Yosys proved generate == hand-typed, for every input
PASS  broken        got FAIL 512/512, reference says FAIL 512/512   (broken/ripple4.sv, all 512 inputs)
PASS  undriven      `check` names the two undriven wires and counts 3 full adders
PASS  proof_broken  the same proof against broken/ripple4.sv -- fails on purpose
PASS  luts4         ripple #(.N(4))  -> 8 SB_LUT4
PASS  luts8         ripple #(.N(8))  -> 16 SB_LUT4
PASS  luts16        ripple #(.N(16)) -> 32 SB_LUT4
PASS  luts32        ripple #(.N(32)) -> 64 SB_LUT4
PASS  wide4         got PASS 0/512, reference says PASS 0/512   (ripple #(.N(4)), all 512 inputs)
PASS  wide8         got PASS 0/131072, reference says PASS 0/131072   (ripple #(.N(8)), all 131072 inputs)
```

Three of those lines describe a failure that is *supposed* to happen. `broken`, `undriven` and
`proof_broken` say PASS when the broken design fails exactly as hard as the reference run says
it should. A checker that only knows what success looks like cannot tell you that your
deliberate failure stopped working.

## Expected results

Measured on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0, Yosys 0.64, Python 3.12.3.
`make` completes in **under five seconds** and ends with a table of twelve verdicts, all `PASS`.

| what | number |
|---|---|
| inputs a 4-bit adder can have | **512** |
| `full_adder` instances the loop builds | **4** (broken: **3**) |
| SAT problem for the proof | **294 variables, 751 clauses** |
| broken design, exhaustive | **FAIL 512/512** |
| counterexample the solver returns | `a = 14`, `b = 8`, `cin = 1` |
| `iverilog` exit status on `errors/ripple4_bit.sv` | **134**, `Aborted (core dumped)` |
| `SB_LUT4` at N = 4 / 8 / 16 / 32 | **8 / 16 / 32 / 64** |
| exhaustive at 8 bits | **131,072 cases, 0.78 s** |

## If something goes wrong

| What you see | What it means |
|---|---|
| `make: yosys: No such file or directory` | You are not inside the workbench container. Every command here runs in the noVNC terminal, not on your laptop. |
| `FAIL` on any line of `make check` | Something drifted. Paste the whole FAIL line into [Discord](https://discord.gg/hrJnP5UsGz) — it contains both your number and the reference. |
| `Aborted (core dumped)` from `iverilog` | Expected only for `errors/ripple4_bit.sv`. Anywhere else, read the first error line above it. |
| `vvp` says nothing and exits 0 | The testbench did not reach its verdict. Read the log from the top; the first error is the real one. |

## Links

- Lab package:
  [`labs/lab-04-four-adders-in-a-row/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-04-four-adders-in-a-row)
- Guide: [Four adders in a row](guide/four-adders-in-a-row.md) ·
  [The carry has to travel](guide/the-carry-has-to-travel.md)
- Previous lab: [Lab 03 — The lazy testbench](labs/lab-03-the-lazy-testbench.md)
- Next: [Lab 05 — Onto the FPGA](labs/lab-05-onto-the-fpga.md), where this exact file becomes
  a bitstream for a real chip — and you find out that `slice[2].fa` shows up in the timing
  report.
