# Lab 01: Transcribe your adder

You type your DD101 full-adder drawing into a SystemVerilog file, check it against your
eight-row truth table, and look at it again as a schematic that a machine drew from your text.
Then you run a deliberately broken adder, some files that fail on purpose, and several other
ways of writing the same circuit.

Each lab's files are in a package, a folder under `labs/` with its own `Makefile`. This lab uses
[`labs/lab-01-transcribe-your-adder/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-01-transcribe-your-adder),
and Parts 6 and 7 use [`labs/guide-examples/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples).

## Before you start

- Finish [IC101](https://uoftasic.com/ic101/) and [DD101](https://uoftasic.com/dd101/).
- Read [Getting started](guide/getting-started.md),
  [From your drawing to a module](guide/from-your-drawing-to-a-module.md),
  [Modules and instances](guide/what-a-module-is.md),
  [`assign` and `always_comb`](guide/assign-and-always-comb.md) and
  [Seeing your adder as a schematic](guide/seeing-it-come-back.md).
- Put your DD101 hand-drawn full adder and your filled-in eight-row truth table on the desk.
  They are the input to this lab. Nothing digital comes across from DD101.

Time: about 2 hours. The Going further steps at the end are optional and not counted.

## Part 1: Load the course

If you haven't set up the workbench, do
[IC101 Lab 03](https://uoftasic.com/ic101/#/labs/lab-03-launch-the-workbench-overview) first.
DD102 uses the same image, `hpretl/iic-osic-tools:2026.08`, and installs nothing new.

1. Start the desktop from your `workspace` clone (`./scripts/start_vnc.sh`, or
   `scripts\start_vnc.bat` on Windows), open <http://localhost/> and open a terminal on the
   desktop. Type every command from here on in that terminal, not on your laptop.
2. Load the environment and get the course files:

   ```bash
   . /foss/designs/common/.designinit
   mod add dd102      # first time only: clones github.com/uoftasic/dd102
   ```

   You should see `OK  module ready: /foss/designs/modules/dd102` and then
   `cwd: /foss/designs/modules/dd102`: `mod add` also moves your shell into the repo, where the
   rest of this lab starts. In every new terminal, load `.designinit` again and run `mod dd102`.

   You can ignore the `PDK=sky130A` in the `ASIC-EDU:` banner that `.designinit` prints. A PDK
   describes how to build a chip, and DD102 configures a chip somebody else already built, an
   FPGA. The two steps that price your adder in sky130 cells (`make area` in Part 7 and
   `make contrast` in Lab 05) read the cell library from its fixed path in the image, so you
   never set a PDK variable.
3. Check the two versions every printed result in this course depends on, unpiped:

   ```bash
   yosys -V
   iverilog -V
   ```

   You should see `Yosys 0.68 (git sha1 38e001a6f, Release, GNU /usr/bin/c++ 13.3.0)`, and
   `Icarus Verilog version 14.0 (devel) (s20260301-391-g64f13540-dirty)` as the first of 73 lines,
   exit status 0 (the rest are the GPL and a list of code generators). Any other version means a
   different image, and the numbers on these pages may not match yours. `iverilog -V | head -2`
   closes the pipe while Icarus is still asking its sub-programs for their versions, so it adds
   lines like `Unable to get version from "/foss/tools/iverilog/lib/ivl/ivlpp -V"`, a different
   number each run. They don't mean your install is broken; [Icarus error
   messages](reference/when-icarus-says-syntax-error.md) has more on pipes.

   Three more versions appear in later output: `Verilator 5.050 2026-07-01 rev v5.050`
   (`verilator --version`), `nextpnr-0.11.1-9-gb17408e2` (`nextpnr-ice40 --version`) and
   `surfer 0.7.0 (git: v0.7.0)` (`surfer --version`).
4. Run `ls labs/`. You should see nine folders: `guide-examples`, `guide-examples-carry`,
   `guide-examples-proving-it`, the five `lab-0N-...` packages and `reference-card`.

| If you see | It means |
|---|---|
| `mod: no such module: dd102` | You ran `mod dd102` before `mod add dd102`. It lists the modules you do have underneath. |
| `fatal: could not read Username for 'https://github.com'` | The repo didn't answer anonymously, so git asked you to log in. It is almost never your spelling. If <https://github.com/uoftasic/dd102> 404s in a browser, the repo isn't published yet; that's on us, so say so in [Discord](https://discord.gg/hrJnP5UsGz). |
| `bash: /foss/designs/common/.designinit: No such file or directory` | The workspace isn't mounted (`ls /foss/designs/` should list `common/` and `modules/`), so you started a bare container. Relaunch with `start_vnc.sh` from your `workspace` clone. Or skip `mod` entirely: `git clone https://github.com/uoftasic/dd102.git` and `cd dd102` get the files, and `make` in every lab package needs none of this setup. |

Anything else about Docker, the desktop or `.designinit` is on IC101's
[Troubleshooting](https://uoftasic.com/ic101/#/reference/troubleshooting) page.

## Part 2: Run the package before you write anything

What does the grader say about an adder with nothing inside?

1. Go to the package:

   ```bash
   cd labs/lab-01-transcribe-your-adder
   ```

   This package needs no `.designinit`, no `mod` and no environment variables, so it runs even
   if your shell profile is broken.

2. `src/full_adder.sv`, the file you will write, ships with its ports and nothing inside. Write
   down what you think `make` will print for its two outputs.

3. Run:

   ```bash
   make
   ```

`make` runs two files through the same printer (`tb/print_table.sv`) and the same grader
(`src/check_table.py`). You should see the shipped answer, `reference/full_adder.sv`, first:

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

Then your file, with the same eight input rows and `x` in both output columns on every row,
the grader's note on each row, and at the end:

```
==============================================================
 VERDICT
==============================================================
 reference/full_adder.sv : PASS  8/8   (so your toolchain is fine)
 src/full_adder.sv       : FAIL        <-- this one is yours to write.
```

`tb/print_table.sv:30: $finish called at 8000 (1ps)` appears after every run in this package,
passing or failing (other testbenches print their own file and line). It is Icarus saying the testbench reached its last line after 8 ns of simulated time,
1 ns per row. It is not a warning.

4. Your outputs print `x`, not `0`. What does `x` mean, and what kind of mistake does a column of
   `x` on an output point to?

   <details>
   <summary>Answer</summary>

   `x` means nobody drove this wire. `logic` carries four values: `0`, `1`,
   `x` ("nobody has said") and `z` ("disconnected"), and the simulator won't invent one. A column of `x` on an
   output is a missing line, not a logic bug: go and find the `assign` that should be there.

   </details>

5. The reference passed and yours failed. What does the reference's `PASS` tell you?

   <details>
   <summary>Answer</summary>

   Both files go through the same `iverilog`, the same printer and the same grader. If the top
   block says PASS, your toolchain works and the only thing left to fix is your file. That
   settles "is it me or is it the setup?" in one command.

   </details>

## Part 3: Lint the stub

Does a linter notice a module that drives nothing?

`verilator` is on your `PATH`. It is a widely used industrial tool, and here it works as a
**linter**: it reads your source without simulating it and warns about its shape. "Lint your RTL
(your design's source) before you simulate it" is real advice.

1. Write down whether you expect Verilator to complain about the stub, whose two outputs are never
   given a value.
2. Run:

   ```bash
   make lint
   ```

You should see the default lint pass the stub:

```
==============================================================
 verilator --lint-only src/full_adder.sv        (the default)
==============================================================
- V e r i l a t i o n   R e p o r t: Verilator 5.050 2026-07-01 rev v5.050
- Verilator: Built from 0.031 MB sources in 2 modules, into 0.002 MB in 3 C++ files needing 0.000 MB
exit status 0
```

and then the same file with `-Wall` fail:

```
%Warning-UNUSEDSIGNAL: src/full_adder.sv:12:18: Signal is not used: 'a'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:13:18: Signal is not used: 'b'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:14:18: Signal is not used: 'cin'
%Warning-UNDRIVEN: src/full_adder.sv:15:18: Signal is not driven: 'sum'
%Warning-UNDRIVEN: src/full_adder.sv:16:18: Signal is not driven: 'cout'
%Error: Exiting due to 5 warning(s)
exit status 1
```

(Verilator prints the source line and a documentation link under each warning; this block keeps
only the first line of each.) The `exit status` lines are Verilator's; `make lint` itself
finishes normally.

3. The default lint exits 0 and never mentions the undriven outputs; `-Wall` gives five warnings
   on the identical file. Why does the default pass it?

   <details>
   <summary>Answer</summary>

   `verilator --lint-only` was asked "is this legal SystemVerilog?" and it answered truthfully:
   yes. Tools answer the question you asked, not the one you meant.

   </details>

Verilator's default lint is nearly silent, so if you use it, use `-Wall`. In this course lint is
never the verdict; `make` is.

## Part 4: Write your adder

1. Open `src/full_adder.sv` ([on GitHub](https://github.com/uoftasic/dd102/blob/main/labs/lab-01-transcribe-your-adder/src/full_adder.sv))
   in a text editor. Edit it inside the noVNC desktop, or on your own machine: the file is in
   your `workspace` folder, under `modules/dd102/labs/lab-01-transcribe-your-adder/`. The ports
   are done. The commented block in the middle has the shape from
   [From your drawing to a module](guide/from-your-drawing-to-a-module.md): name the three wires
   that never touch the edge of your box, then write one `assign` for each of the five wires on
   your drawing (those three plus `sum` and `cout`).

   You can also write it as two lines straight off the truth table, one for `sum` and one for
   `cout`. Both pass. The grader checks the eight rows, not the shape. (In DD101, the Combinational
   Analysis tool built a different-looking circuit from your table, and it disagreed with yours on
   zero of eight rows.)

2. Run `make` again.

You should see:

```
==============================================================
 VERDICT
==============================================================
 reference/full_adder.sv : PASS  8/8
 src/full_adder.sv       : PASS  8/8   <-- Lab 01 is done.
```

If a row disagrees, the grader does the arithmetic for you:

```
       a=0 b=1 cin=1: you printed cout=0 sum=0; the table says cout=1 sum=0.
                     0 + 1 + 1 = 2, which is 10 in binary.
```

If the file won't compile at all, the first error line is the real one and the rest are fallout,
though its line number can be one late, as the second example shows. Two you are likely to meet, both made by editing this package's `src/full_adder.sv`. Your line
numbers will differ; recognise the shape.

- The word `assign` left off the first `assign` line:

  ```
  src/full_adder.sv:21: syntax error
  src/full_adder.sv:21: error: Invalid module instantiation
  ```

  Without the keyword, `ha1_sum = a ^ b;` isn't an assignment, and Icarus guesses you were
  instantiating a module called `ha1_sum`. "Invalid module instantiation" on a line with an `=`
  in it means a missing `assign`.

- The semicolon left off the first `assign` line:

  ```
  src/full_adder.sv:22: syntax error
  src/full_adder.sv:21: error: Syntax error in left side of continuous assignment.
  ```

  The mistake is on line 21 and the first message points at 22, because a parser only notices a
  missing semicolon when it reaches the next word. When a syntax error points at a line that
  looks fine, look at the line above it.

## Part 5: Check the picture in DigitalJS

Is the circuit you typed the circuit you drew? Eight rows agreeing doesn't tell you: you might
have typed a different correct circuit from the one on your paper. A schematic would show it.

1. Open **<https://digitaljs.tilk.eu/>**. There is no account and nothing to install. The page
   opens with **Setup** and **I/O** tabs on the left, space for the circuit on the right, and a
   toolbar whose left-most control is a blue **Run** button (tooltip: *Synthesize and
   simulate!*); the rest of the toolbar stays greyed out until you have run something once. On a
   narrow screen the halves stack and two buttons, **`</>` Code** and **Circuit**, switch between
   them. It works on a phone, but use a laptop.
2. On the **Setup** tab, find the row with a `file name` box, a small grey dropdown showing
   **`.sv`** and a blue **Create file** button. Type `full_adder` in the box. Leave the dropdown
   on `.sv` (its full label is *".sv (SystemVerilog, Yosys native)"*).
3. Press **Create file**. A third tab with an editor appears beside *Setup* and *I/O*.
4. Paste the whole finished contents of your `src/full_adder.sv` into it, comments and all. To
   get text out of the noVNC desktop, use the clipboard control in the noVNC sidebar (see
   [IC101](https://uoftasic.com/ic101/#/guide/launch-novnc)), or open the file from your
   `workspace` folder on your own machine. Don't paste the stub: an empty module
   renders as a box with five ports and nothing inside, which looks like the tool failed when it
   didn't.
5. Leave every checkbox at its default. These pages were written against *Simplify diagram*
   ticked, *Optimize in Yosys* unticked, *Convert to logic gates* unticked, *Synthesis mode* on
   *WebAssembly (faster and local)*, and *Lint source code using Verilator* ticked. That last one
   runs Verilator over your file; a correct adder passes silently, and if it didn't you would
   get a message instead of a diagram.
6. Press **Run**, and switch to the circuit view if your screen is narrow. Put your paper drawing
   next to the screen.
7. Click `a`, `b` and `cin` through all eight combinations in the order on your truth table,
   and read the `sum` and `cout` lamps each time. Hover any wire, including the internal wires
   you named (`ha1_sum`, `ha1_carry` and `ha2_carry`, if you used the guide's names), to see its
   value.

You should see your five port names on a schematic wired the way you wired them. If you wrote
the five-`assign` version: five gates (two Xor, two And, one Or), with the two Xors on the path
to `sum` and the And/And/Or on the path to `cout`. If you wrote the two-line version, the two
half adders won't be visible as two Xor/And pairs. That picture is telling you something true:
you typed a different circuit from the one you drew, and both are correct.

The lamps should match the truth table on your paper on all eight rows, the same rows
`reference/full_adder.sv` printed in Part 2.

> Use DigitalJS for the picture, never for the count. Its Yosys comes from a feed with no
> version pinned, so it isn't your workbench's 0.68. No lab in this course asks you to compare a
> browser cell count with a workbench cell count.

## Part 6: Run files that fail on purpose

What do the tools tell you about a design that is wrong, and what do they leave out?

This part and the next use `labs/guide-examples/`, which holds the runnable files printed in the
guide pages you read before this lab. It needs no environment setup either.

1. Go to the package and run its own finished adder (not yours) against the eight rows:

   ```bash
   cd ../guide-examples
   make sim
   ```

   You should see eight `ok` rows, then `PASS - all 8 rows match your DD101 table.` and
   `src/tb_full_adder.sv:46: $finish called at 8000 (1ps)`.

2. Run the same testbench against `broken/full_adder.sv`, which is `src/full_adder.sv` with one
   character changed: the `|` on the last line is an `&`.

   ```bash
   make broken
   ```

   You should see:

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

   followed by `vvp exited 0. Yes. Zero.` (`vvp` is the program that runs the compiled
   simulation.) The first three rows pass: someone testing by hand in a hurry tries `000`,
   `001`, `010`, sees three passes, and ships a design that is half wrong.

3. `vvp` exited 0 after finding four wrong rows. Why, and what should a script trust instead?

   <details>
   <summary>Answer</summary>

   "The simulation ran" and "the design is correct" are different questions, and `vvp` only
   answers the first. The package's `Makefile` decides with `grep -q "^PASS"`: trust a line you
   told the simulator to print, never its exit status.

   </details>

4. Run the files that misbehave on purpose:

   ```bash
   make errors
   ```

   You should see each file's name followed by what the tools say about it. Check these against
   the guide pages:

   | File | What you should see | Guide page |
   |---|---|---|
   | `errors/two_drivers.sv` | `error: Variable 'sum' cannot have multiple drivers.` | [From your drawing to a module](guide/from-your-drawing-to-a-module.md) |
   | `errors/undeclared_wire.sv` | Icarus: `iverilog exit 0 - silent`. Yosys: three `Warning: Identifier ... is implicitly declared.` lines | [From your drawing to a module](guide/from-your-drawing-to-a-module.md) |
   | `errors/call_it_like_a_function.sv` | ``error: No function named `full_adder' found in this context`` | [Modules and instances](guide/what-a-module-is.md) |
   | `errors/both_ways_at_once.sv` | Icarus: `Cannot perform procedural assignment to variable 'sum' because it is also continuously assigned.` Yosys: `yosys exit 0` and one `Warning: multiple conflicting drivers` line | [`assign` and `always_comb`](guide/assign-and-always-comb.md) |
   | `errors/forgot_a_branch.sv` | Icarus: `iverilog exit 0 - not one word about it`. Yosys: `yosys exit 1` and ``ERROR: Latch inferred for signal `\forgot_a_branch.\sum' ...`` | [`assign` and `always_comb`](guide/assign-and-always-comb.md) |
   | `errors/if_inside_assign.sv` | five errors, all on line 9, for one mistake | [`assign` and `always_comb`](guide/assign-and-always-comb.md) |

   You'll also see four lines like `make: [Makefile:92: errors] Error 2 (ignored)`, one for each
   file Icarus refuses to compile. That is `make` reporting that a command failed and that it was
   told in advance not to care. These files are supposed to fail.

## Part 7: Other spellings of the same adder

Do different ways of writing the adder build the same hardware?

1. Run the full adder written with its five lines in reverse order (`cout` first, `ha1_sum`
   last):

   ```bash
   make backwards
   ```

   You should see `PASS - the lines in reverse order, all 8 rows still match.`

2. Drive four spellings (five `assign`s, one expression per output, `always_comb` + `case`, and
   two `half_adder` instances) from the same eight rows:

   ```bash
   make spellings
   ```

   You should see:

   ```
     every column below is cout then sum, on the same eight rows

              drawing  flat  table  boxes
     a b cin |   cs     cs     cs     cs
     --------+---------------------------
     0 0  0  |   00     00     00     00
     0 0  1  |   01     01     01     01
     0 1  0  |   01     01     01     01
     0 1  1  |   10     10     10     10
     1 0  0  |   01     01     01     01
     1 0  1  |   10     10     10     10
     1 1  0  |   10     10     10     10
     1 1  1  |   11     11     11     11

   PASS - four spellings, eight rows, zero disagreements.
   ```

3. Measure the area of each spelling in sky130 standard cells:

   ```bash
   make area
   ```

   You should see:

   ```
   ---- 1. drawing - five assigns, one per wire on your paper
      Chip area for module '\full_adder': 33.782400
   ---- 2. flat - one expression per output
      Chip area for module '\full_adder_flat': 33.782400
   ---- 3. table - always_comb + case, your eight rows
      Chip area for module '\full_adder_table': 33.782400
   ---- 4. half - one half adder, alone
      Chip area for module '\half_adder': 15.014400
   ---- 5. boxes - two half_adder instances + an Or, walls up
      Chip area for module '\half_adder': 15.014400
      Chip area for module '\full_adder_hier': 6.256000
      Chip area for top module '\full_adder_hier': 36.284800
   ---- 6. boxes_flat - the same two boxes, walls knocked down
      Chip area for module '\full_adder_hier': 33.782400
   ```

   Sections 1 to 3 are identical to four decimal places: one `sky130_fd_sc_hd__xor3_1` and one
   `sky130_fd_sc_hd__maj3_1` each. Areas are in square micrometres. Check sections 4 to 6 against
   the arithmetic in [Modules and instances](guide/what-a-module-is.md):
   $15.0144 \times 2 + 6.2560 = 36.2848$ with the walls up, and 33.7824 with them knocked down.

4. Run `make` with no target. It runs most of the steps in Parts 6 and 7, including this
   synthesis, and ends with the area checker's table:

   ```
   file                cells   area (um^2)   verdict  cells used
   ------------------------------------------------------------------------------
   drawing.json            2       33.7824   PASS     1x maj3_1 + 1x xor3_1
   flat.json               2       33.7824   PASS     1x maj3_1 + 1x xor3_1
   table.json              2       33.7824   PASS     1x maj3_1 + 1x xor3_1
   half.json               2       15.0144   PASS     1x and2_0 + 1x xor2_1
   boxes.json              7       36.2848   PASS     2x half_adder + 2x and2_0 + 1x lpflow_inputiso1p_1 + 2x xor2_1
   boxes_flat.json         2       33.7824   PASS     1x maj3_1 + 1x xor3_1

   PASS - every number matches the reference run, to four decimals.
   ```

5. A full adder is five gates on your drawing. Why does `boxes.json` say 7 cells, and why does
   `boxes_flat.json` say 2?

   <details>
   <summary>Answer</summary>

   Yosys counts the two `half_adder` instances as cells and also counts what is inside them: 5
   real gates plus 2 boxes (`lpflow_inputiso1p_1` is the Or gate under an odd catalogue name).
   `boxes_flat.json` says 2 because the Yosys command `flatten` removed the module boundaries and
   let the synthesizer rebuild across them.

   </details>

## Finishing

### You're done when

you have worked through Parts 1 to 7 and `make` in `labs/lab-01-transcribe-your-adder/` prints
`src/full_adder.sv : PASS  8/8   <-- Lab 01 is done.` for the adder you wrote in Part 4.

`make` always exits 0; the verdict is the text. `make grade` is the same check with an exit
status a script can read. It prints `make: *** [Makefile:92: grade] Error 1` until you pass. The
lab's reference numbers are on
[Expected results](reference/expected-results.md#lab-01-transcribe-your-adder).

### Questions

1. Your adder passed two checks: eight rows in Part 4 and a schematic in Part 5. What kind of
   mistake does each one catch that the other doesn't?

   <details>
   <summary>Answer</summary>

   The simulator catches wrong behaviour. The schematic catches right behaviour that isn't the
   design you meant: a swapped port, a wire connected to the neighbouring net, a gate typed
   twice. Reviewing a picture of the netlist against the intent is a real step in real design.

   </details>

### Submit

Nothing to submit.

## Going further (optional)

1. `make picture` in `labs/guide-examples/` draws the schematic in the workbench with the same
   Yosys commands DigitalJS runs. You should see `5 cells`, `2 $and`, `1 $or`, `2 $xor` and
   `wrote results/full_adder_rtl.svg -- open it in a browser`. Open the SVG in a web browser (on
   your own machine it is in your `workspace` folder, under
   `modules/dd102/labs/guide-examples/results/`) and find the wire names you typed (`ha1_sum`,
   `ha1_carry`, `ha2_carry`).
2. In DigitalJS, reload the page so only one file is loaded, create a file named
   `full_adder_table`, paste
   [`src/full_adder_table.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_table.sv)
   (the `always_comb` + `case` version) into it and press **Run**. You should see a single box
   labelled **Memory** with an address input, and no gates. The circuit isn't different;
   [Seeing your adder as a schematic](guide/seeing-it-come-back.md) explains why.
3. Reload the page, create `full_adder_hier` and paste
   [`src/full_adder_hier.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_hier.sv)
   into it, then create a second file, `half_adder`, paste
   [`src/half_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/half_adder.sv)
   into it, and press **Run**. (On its own, `full_adder_hier.sv` won't run, because DigitalJS has
   never heard of `half_adder`.) You should see `half_adder` drawn as one box, twice. Hover one
   box and click the **🔍** that appears above it to descend into its Xor and And. The
   *Additional SystemVerilog files:* picker further down the Setup tab does the same job from
   files on your disk.
4. Reload the page, load your own `full_adder.sv` as in Part 5, tick **Convert to logic gates**
   and then **Map into subset of gates** with its default set, and press **Run**. You should see
   three NANDs and two XORs: Yosys rebuilt your Or and both Ands out of NAND, as you did by hand
   in [DD101 Lab 02](https://uoftasic.com/dd101/#/labs/lab-02-gates-from-one-gate). Ticking only
   **Convert to logic gates** just renames your five gates from `$and`/`$or`/`$xor` to
   `$_AND_`/`$_OR_`/`$_XOR_`. Neither option shows an area or what a factory would build. Untick
   them before you compare anything with your drawing.
5. With a circuit on screen, the 📁 (*Load from file*) and 💾 (*Save to file*) buttons reload and
   save it as JSON, and 🔗 (*Get link*) turns what you are looking at into a URL. When you ask for
   help in [Discord](https://discord.gg/hrJnP5UsGz), post that link rather than a screenshot, so
   whoever answers can click your inputs themselves.

Stuck? Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). Save a DigitalJS link (Going
further, step 5) or an [EDA Playground](https://www.edaplayground.com/) link (see
[Getting started](guide/getting-started.md)) and paste that instead of describing the problem.

Next on the [Course path](README.md#course-path): read [Testbenches](guide/eight-rows-and-no-opinions.md),
then do [Lab 02: Prove it](labs/lab-02-prove-it-overview.md).
