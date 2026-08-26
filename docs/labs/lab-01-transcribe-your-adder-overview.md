# Lab 01 — Transcribe your adder

Full runnable package:
[`labs/lab-01-transcribe-your-adder/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-01-transcribe-your-adder).

**The question this lab answers:** *I have a drawing on paper. How do I know the file I typed
is the same circuit?*

You have read [From your drawing to a module](guide/from-your-drawing-to-a-module.md). You
know that the five labels on the edge of your drawing are the port list and that each wire
inside becomes one `assign`. This lab is where you type your own drawing out and then find
out — from a machine, not from your own eyes — whether you typed what you meant.

Two things check you, and they check different things. The workbench runs your file and
compares eight rows of numbers. [DigitalJS Online](https://digitaljs.tilk.eu/) draws your
file back as a picture you can hold next to the paper. Neither one is optional and neither
one catches what the other catches.

## Prerequisites

- [IC101](https://uoftasic.com/ic101/) complete, [DD101](https://uoftasic.com/dd101/) complete
- [Getting started](guide/getting-started.md) done — `iverilog -V` says
  `Icarus Verilog version 14.0 (devel)` on its first line
- Read [From your drawing to a module](guide/from-your-drawing-to-a-module.md)
- **Your DD101 hand-drawn full adder and your filled-in eight-row table, on the desk.** They
  are the input to this lab. Nothing digital crossed the boundary from DD101 on purpose.

## Objectives

- Turn a drawing you made into a file a simulator accepts
- Read a column of `x` correctly, the first time, without guessing
- Tell "my file is wrong" apart from "my setup is wrong", using a command instead of a feeling
- Watch a tool that looks authoritative say nothing at all about a completely empty module

## Theory (short)

A module is a box with named holes in its edge. Inside, `assign` makes a permanent connection
— not a step that runs, a joint that is soldered. Everything is live at once, forever, which
is why the order of the lines does not matter and why the language does not need loops to
describe a circuit that does five things simultaneously.

Your full adder has exactly three one-bit inputs. Three one-bit inputs is $2^3 = 8$ possible
situations, and eight is small enough to check **all of them**. That is not a testing strategy
you will get to keep. Enjoy it while it lasts; [Lab 03](labs/lab-03-the-lazy-testbench-overview.md) is
where it stops being possible.

## Procedure

```bash
cd labs/lab-01-transcribe-your-adder
make
```

That is the whole setup. No `.designinit`, no `mod`, no PDK, no liberty file, no environment
variables — this package reads none of them. If your shell profile is broken, this lab still
runs.

---

### 1 — Run it before you write anything

- **Try this:** Before you open the file, **write down what you think an empty module prints.**
  Not what it should print. What it *will* print.

- **What you should see:** `make` runs twice. The shipped answer first:

```
==============================================================
 1. THE SHIPPED ANSWER  --  reference/full_adder.sv
    If this does not say PASS, the problem is your setup.
==============================================================
iverilog -g2012 -o results/reference.vvp tb/print_table.sv reference/full_adder.sv
a b cin | cout sum
0 0  0  |  0    0
0 0  1  |  0    1
0 1  0  |  0    1
0 1  1  |  1    0
1 0  0  |  0    1
1 0  1  |  1    0
1 1  0  |  1    0
1 1  1  |  1    1
tb/print_table.sv:30: $finish called at 8000 (1ps)

--- grading reference/full_adder.sv ---
PASS -- reference/full_adder.sv: all 8 rows match the truth table.
```

  and then your file:

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

**Three things to name before they worry you.**

`tb/print_table.sv:30: $finish called at 8000 (1ps)` appears after **every** run in this lab,
including the ones that pass. It is Icarus saying the testbench reached its last line after 8
nanoseconds of pretend time, one per row. It is not a warning and it never means anything is
wrong.

`x` is not a wrong answer. **`x` means nobody drove this wire.** `logic` carries four values —
`0`, `1`, `x` ("nobody has said"), and `z` ("disconnected") — and the simulator refuses to
invent one. Your module has an edge with five holes in it and nothing in the middle.

The reference passing while yours fails is **the design of this lab, not a bug in it**. Both
files go through the same `iverilog`, the same printer, and the same grader. If the top block
says PASS, your toolchain is fine and the only variable left is your file. That question — *is
it me or is it the setup?* — is the one that ends async courses, and this is how you settle it
in one command.

- **Why an engineer cares:** A column of `x` on an output is not a logic bug and you should
  not debug it like one. It is a **missing line**. Go and find the `assign` that should be
  there and is not. That reflex saves you an hour the first time a 200-line module comes up
  half-`x`.

---

### 2 — Write the two lines, or the five

Open [`src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-01-transcribe-your-adder/src/full_adder.sv).
The ports are done. The commented block in the middle is the shape from
[the guide page](guide/from-your-drawing-to-a-module.md): name the three wires that never
touch the edge of your box, then write one `assign` per wire.

You may also write it as two lines, straight off the truth table — one for `sum`, one for
`cout`. **Both pass.** The grader checks the eight rows, not the shape, and you already know
why: in DD101 you generated a completely different-looking circuit with Combinational Analysis
and it disagreed with yours on zero of eight rows. A truth table does not have *a* circuit.

Run `make` again.

```
==============================================================
 VERDICT
==============================================================
 reference/full_adder.sv : PASS  8/8
 src/full_adder.sv       : PASS  8/8   <-- Lab 01 is done.
```

If a row disagrees, the grader does the arithmetic for you rather than just marking it:

```
       a=0 b=1 cin=1: you printed cout=0 sum=0; the table says cout=1 sum=0.
                     0 + 1 + 1 = 2, which is 10 in binary.
```

> **If it will not compile at all**, the first error line is the real one and everything after
> it is fallout. Two you are likely to meet, both produced by editing this package's own
> `src/full_adder.sv` and running `make`. Your line numbers will not be these ones; the shape
> is what to recognise.
>
> Leave the word `assign` off the first line:
>
> ```
> src/full_adder.sv:21: syntax error
> src/full_adder.sv:21: error: Invalid module instantiation
> ```
>
> Without the keyword, `ha1_sum = a ^ b;` is not an assignment at all, and Icarus's best guess
> is that you were trying to instantiate a module called `ha1_sum`. **"Invalid module
> instantiation" on a line with an `=` in it means a missing `assign`.**
>
> Leave the semicolon off the first line:
>
> ```
> src/full_adder.sv:22: syntax error
> src/full_adder.sv:21: error: Syntax error in left side of continuous assignment.
> ```
>
> The mistake is on **21** and the first message points at **22**, because a parser only
> notices a missing semicolon when it reaches the next word. **Reflex: when a syntax error
> points at a line that looks fine, look at the line above it.**

### 3 — Now look at the picture

Numbers agreeing is not the same as the drawing agreeing. A transcription can be correct and
still not be *your* circuit — you might have typed a different right answer than the one on
your paper, and you would never know from eight rows.

[Seeing it come back as a schematic](guide/seeing-it-come-back.md) is the page about this;
here is the four-second version.

- **Try this:** Open **<https://digitaljs.tilk.eu/>** — no account, nothing to install. Paste
  the **whole finished contents** of `src/full_adder.sv` into the `.sv` tab, press **Run**, and
  switch to the **Circuit** view. Put your paper drawing next to the screen.

- **What you should see:** a schematic with your five port names on it, wired the way you
  wired them. If you wrote the five-`assign` version, the two half-adder halves are visible as
  two Xor/And pairs feeding an Or. If you wrote the two-line version, they are not — and that
  is the picture telling you something true: *you typed a different circuit than you drew, and
  both are correct.*

  Toggle the input switches. They drive the logic live, so you can walk your own eight rows by
  clicking.

> **Do not paste the stub.** An empty module renders as a box with five ports and nothing
> inside, which looks like the tool failed. It did not.
>
> **Use DigitalJS for the picture, never for the count.** It is Yosys compiled to WebAssembly,
> pulled from a feed with no version pinned — a different Yosys from your workbench's 0.64.
> [Getting started](guide/getting-started.md) has the details. No lab in this course ever asks
> you to compare a browser cell count against a workbench cell count.

- **Why an engineer cares:** these two checks fail differently. The simulator catches *wrong
  behaviour*. The schematic catches *right behaviour that is not the design you meant* — a
  swapped port, a wire you connected to the neighbouring net, a gate you typed twice. Reviewing
  a picture of the netlist against the intent is a real step in real design, and this is the
  four-second version of it.

---

### 4 — The dead end: the tool that says nothing

`verilator` is on your `PATH`. It is a serious, widely used, industrial-strength tool, and
"lint your RTL before you simulate it" is real advice that real engineers give. So run it on
the empty stub — a module that drives nothing whatsoever:

```bash
make lint
```

- **What you should see:** first, this.

```
==============================================================
 verilator --lint-only src/full_adder.sv        (the default)
==============================================================
- V e r i l a t i o n   R e p o r t: Verilator 5.046 2026-02-28 rev v5.046
- Verilator: Built from 0.031 MB sources in 2 modules, into 0.002 MB in 3 C++ files needing 0.000 MB
exit status 0
```

  **Exit 0, and not one word about the fact that neither output has a value.** A module that
  cannot possibly work, and the professional tool is happy.

  Then, the same file with one more flag:

```
%Warning-UNUSEDSIGNAL: src/full_adder.sv:12:18: Signal is not used: 'a'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:13:18: Signal is not used: 'b'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:14:18: Signal is not used: 'cin'
%Warning-UNDRIVEN: src/full_adder.sv:15:18: Signal is not driven: 'sum'
%Warning-UNDRIVEN: src/full_adder.sv:16:18: Signal is not driven: 'cout'
%Error: Exiting due to 5 warning(s)
exit status 1
```

  Five warnings and exit 1, from the identical file. (Verilator prints the offending source
  line and a link to its documentation under each warning; the block above is trimmed to the
  headline of each. Run `make lint` for the full text.)

- **Why an engineer cares:** you will spend your career reading tools that answer the question
  you asked instead of the question you meant. `verilator --lint-only` was asked "is this legal
  SystemVerilog?" and truthfully answered yes.

> **Reflex: Verilator's default lint is nearly silent — if you reach for it, reach for
> `-Wall`.** And in this course, lint is never the verdict. `make` is.

## Expected results

Every number here came from a run on `hpretl/iic-osic-tools:2026.04` — Icarus Verilog 14.0,
Python 3.12.3.

| what | result |
|---|---|
| `reference/full_adder.sv`, all 8 rows | **PASS** |
| `src/full_adder.sv` as shipped | **FAIL**, 8 of 8 rows disagree, every output `x` |
| `src/full_adder.sv` once you write it | **PASS**, 8 of 8 |
| `verilator --lint-only` on the stub | 0 warnings, **exit 0** |
| `verilator --lint-only -Wall` on the stub | **5 warnings**, exit 1 |
| `make` exit status | always **0** — the verdict is the text |

`make grade` is the same check with an exit status a script can read; it prints
`make: *** [Makefile:92: grade] Error 1` until you pass, and that line is the point of it.

## Links

- Package: [`labs/lab-01-transcribe-your-adder/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-01-transcribe-your-adder)
- Guide: [From your drawing to a module](guide/from-your-drawing-to-a-module.md) ·
  [What a module actually is](guide/what-a-module-is.md) ·
  [Seeing it come back as a schematic](guide/seeing-it-come-back.md)
- Stuck? [Team Discord](https://discord.gg/hrJnP5UsGz). Save an
  [EDA Playground](https://www.edaplayground.com/) link and paste that instead of describing it.

Next: [Lab 02 — Prove it](labs/lab-02-prove-it-overview.md), where you stop being handed a testbench and
write one — and then find out what it is worth.
