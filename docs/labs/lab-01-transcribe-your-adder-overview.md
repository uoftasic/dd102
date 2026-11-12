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

Time: about 2½ hours.

## Part 1: Set up the workbench

You installed everything in IC101: Docker, the `workspace` clone and the noVNC desktop. This
part loads DD102 into it. Nothing here installs anything new. DD102 needs one Docker image,
`hpretl/iic-osic-tools:2026.08` (the one IC101's `start_vnc.sh` pulls), and a browser.

1. On your own machine, in your `workspace` clone, start the desktop:

   ```bash
   cd workspace
   ./scripts/start_vnc.sh          # Windows: scripts\start_vnc.bat
   ```

2. Open **http://localhost/** and open a terminal on that desktop. Type every command from here
   on in that terminal, not on your laptop. Ports, passwords, resolution and what to do when the
   page is blank are in [IC101: Launch the noVNC desktop](https://uoftasic.com/ic101/#/guide/launch-novnc).

3. Load the environment:

   ```bash
   . /foss/designs/common/.designinit
   ```

   ```
   ASIC-EDU: PDK=sky130A  PDK_ROOT=/foss/pdks  designs=/foss/designs
             run 'mod' to list course modules, or 'mod <name>' to enter one.
   ```

   The leading `.` is the shell's `source` command. It runs the file in your current shell
   instead of a child process, which is the only way a script can change your environment.
   Without the dot and the space, the command does nothing useful. You have to do this in every
   new terminal.

   You can ignore the `sky130A` in the banner. A PDK describes how to build a chip, and DD102
   never builds one; it configures a chip somebody else already built. Two steps in the course
   price your adder in sky130 standard cells for comparison, and they read the cell library from
   its fixed path in the image, so you never need to set a PDK or cell-library variable. The one
   thing you need from `.designinit` is the `mod` command in the next step.

4. Get the course files:

   ```bash
   mod add dd102      # first time only: clones github.com/uoftasic/dd102
   mod dd102          # every time after that
   ```

   ```
   Cloning https://github.com/uoftasic/dd102.git
        into /foss/designs/modules/dd102
   Cloning into '/foss/designs/modules/dd102'...
   OK  module ready: /foss/designs/modules/dd102
       run: mod dd102
   cwd: /foss/designs/modules/dd102
   ```

   The output above is from `mod add dd102`: it clones the repo and then moves your shell into
   it (the `cwd:` line), so the first time you don't need `mod dd102` as well. In every later
   terminal, run only `mod dd102`, which prints the same `cwd:` line. The rest of this lab starts
   from that folder.

   `mod` is a shell function that `.designinit` defines. `mod` on its own lists what you have
   (`dd102`, and `ic101_setup` from IC101). Everything lands under `/foss/designs/modules/`, which
   is your `workspace` folder shared into the container, so your files are on your own disk and
   deleting the container does not delete your work.

5. Check the two versions every printed result in this course depends on:

   ```bash
   yosys -V
   iverilog -V
   ```

   ```
   Yosys 0.68 (git sha1 38e001a6f, Release, GNU /usr/bin/c++ 13.3.0)
   Icarus Verilog version 14.0 (devel) (s20260301-391-g64f13540-dirty)
   ```

   `iverilog -V` prints 73 lines and exits 0. The line above is the first; the other 72 are the
   GNU General Public License and a list of code generators. That is normal.

   > Don't pipe it into `head`. `iverilog -V | head -2` closes the pipe while Icarus is still
   > asking its sub-programs for their versions, and Icarus complains with lines like
   > `Unable to get version from "/foss/tools/iverilog/lib/ivl/ivlpp -V"`. How many of those you
   > get changes from run to run, and none of them means your install is broken. Run version
   > checks unpiped. A pipe can hide or add output, and you'll meet that again in
   > [Icarus error messages](reference/when-icarus-says-syntax-error.md).

   The other tools, if you want to check them:

   | Tool | Command | Expect |
   |---|---|---|
   | Verilator | `verilator --version` | `Verilator 5.050 2026-07-01 rev v5.050` |
   | nextpnr | `nextpnr-ice40 --version` | `"nextpnr-ice40" -- Next Generation Place and Route (Version nextpnr-0.11.1-9-gb17408e2)` |
   | Surfer | `surfer --version` | `surfer 0.7.0 (git: v0.7.0)` |

   If `yosys` doesn't say `0.68` or `iverilog` doesn't say `14.0`, you are on a different image
   and the numbers on these pages may not match yours.

6. List the lab packages:

   ```bash
   ls labs/
   ```

You should see these nine folders:

```
guide-examples
guide-examples-carry
guide-examples-proving-it
lab-01-transcribe-your-adder
lab-02-prove-it
lab-03-the-lazy-testbench
lab-04-four-adders-in-a-row
lab-05-onto-the-fpga
reference-card
```

If something fails:

| What you see | What it means |
|---|---|
| `bash: mod: command not found` | You didn't run step 3 in this terminal. Every new tab starts clean. |
| `mod: no such module: dd102` | You ran `mod dd102` before `mod add dd102`. It lists the modules you do have underneath. |
| `fatal: could not read Username for 'https://github.com'` | git is being asked to log in, which means the repo didn't answer anonymously. It is almost never your spelling. Open <https://github.com/uoftasic/dd102> in a browser. If it 404s, the repo isn't published yet; that's on us, so say so in [Discord](https://discord.gg/hrJnP5UsGz). |
| `bash: /foss/designs/common/.designinit: No such file or directory` | The workspace isn't mounted. `ls /foss/designs/` should list `common/` and `modules/`; if it's empty you started a bare container instead of the workbench. Relaunch with `start_vnc.sh` from your `workspace` clone ([IC101](https://uoftasic.com/ic101/)). You can still run every lab: `git clone https://github.com/uoftasic/dd102.git` and then `cd dd102` gets the files without `mod`, and `make` needs none of this setup. |

## Part 2: Run the package before you write anything

1. Go to the package and run it:

   ```bash
   cd labs/lab-01-transcribe-your-adder
   make
   ```

   This package needs no `.designinit`, no `mod` and no environment variables, so it runs even
   if your shell profile is broken.

2. `src/full_adder.sv`, the file you will write, ships with its ports and nothing inside. Before
   you read the output, write down what you think that empty module will print.

`make` runs two files through the same printer (`tb/print_table.sv`) and the same grader
(`src/check_table.py`). First the shipped answer, `reference/full_adder.sv`:

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

Then your file, `src/full_adder.sv`, which has its ports and nothing else:

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

then the grader's note on each of the eight rows, and it ends:

```
==============================================================
 VERDICT
==============================================================
 reference/full_adder.sv : PASS  8/8   (so your toolchain is fine)
 src/full_adder.sv       : FAIL        <-- this one is yours to write.
```

Three things in that output to understand before they worry you:

- `tb/print_table.sv:30: $finish called at 8000 (1ps)` appears after every run in this lab,
  passing or failing. It is Icarus saying the testbench reached its last line after 8 ns of
  simulated time, 1 ns per row. It is not a warning.
- `x` is not a wrong answer. It means nobody drove this wire. `logic` carries four values: `0`,
  `1`, `x` ("nobody has said") and `z` ("disconnected"), and the simulator won't invent one. A
  column of `x` on an output is a missing line, not a logic bug: go and find the `assign` that
  should be there.
- The reference passing while yours fails is how this lab is designed. Both files go through
  the same `iverilog`, the same printer and the same grader. If the top block says PASS, your
  toolchain works and the only thing left to fix is your file. That settles "is it me or is it
  the setup?" in one command.

## Part 3: Lint the stub

`verilator` is on your `PATH`. It is a widely used industrial tool, and here it works as a
linter: it reads your source without simulating it and warns about its shape. "Lint your RTL
(your design's source) before you simulate it" is real advice. Run it on the stub while it is
still empty, a module that drives nothing at all:

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

Exit 0, and no mention that neither output is ever given a value. `make lint` then runs the same file
with `-Wall`:

```
%Warning-UNUSEDSIGNAL: src/full_adder.sv:12:18: Signal is not used: 'a'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:13:18: Signal is not used: 'b'
%Warning-UNUSEDSIGNAL: src/full_adder.sv:14:18: Signal is not used: 'cin'
%Warning-UNDRIVEN: src/full_adder.sv:15:18: Signal is not driven: 'sum'
%Warning-UNDRIVEN: src/full_adder.sv:16:18: Signal is not driven: 'cout'
%Error: Exiting due to 5 warning(s)
exit status 1
```

Five warnings and exit 1 from the identical file. (Verilator prints the source line and a
documentation link under each warning; this block keeps only the first line of each.)

`verilator --lint-only` was asked "is this legal SystemVerilog?" and it answered truthfully:
yes. Tools answer the question you asked, not the one you meant. Verilator's default lint is
nearly silent, so if you use it, use `-Wall`. In this course lint is never the verdict; `make`
is.

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

If the file won't compile at all, the first error line is the real one and the rest are fallout.
Two you are likely to meet, both made by editing this package's `src/full_adder.sv`. Your line
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

Eight rows agreeing doesn't mean the drawing agrees. You might have typed a different correct
circuit from the one on your paper, and eight rows would never tell you; a schematic would.

1. Open **<https://digitaljs.tilk.eu/>**. There is no account and nothing to install. The page
   opens split down the middle: a panel with **Setup** and **I/O** tabs on the left, empty space
   for the circuit on the right, and a toolbar whose left-most control is a blue **Run** button
   (tooltip: *Synthesize and simulate!*). The rest of the toolbar stays greyed out until you have
   run something once. On a narrow screen the halves stack and two buttons, **`</>` Code** and
   **Circuit**, switch between them. It works on a phone, but use a laptop.
2. On the **Setup** tab, find the row with a `file name` box, a small grey dropdown showing
   **`.sv`** and a blue **Create file** button. Type `full_adder` in the box. Leave the dropdown
   on `.sv` (its full label is *".sv (SystemVerilog, Yosys native)"*).
3. Press **Create file**. A third tab with an editor appears beside *Setup* and *I/O*.
4. Paste the whole finished contents of your `src/full_adder.sv` into it, comments and all. To
   get text out of the noVNC desktop, use the clipboard control in the noVNC sidebar (see
   [IC101](https://uoftasic.com/ic101/#/guide/launch-novnc)), or open the file from your
   `workspace` folder on your own machine.
   Don't paste the stub: an empty module renders as a box with five ports and nothing inside,
   which looks like the tool failed when it didn't.
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

The lamps should match your table on all eight rows:

| a | b | cin | cout | sum |
|---|---|-----|------|-----|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 0 | 1 |
| 0 | 1 | 0 | 0 | 1 |
| 0 | 1 | 1 | 1 | 0 |
| 1 | 0 | 0 | 0 | 1 |
| 1 | 0 | 1 | 1 | 0 |
| 1 | 1 | 0 | 1 | 0 |
| 1 | 1 | 1 | 1 | 1 |

The two checks catch different mistakes. The simulator catches wrong behaviour. The schematic
catches right behaviour that isn't the design you meant: a swapped port, a wire connected to the
neighbouring net, a gate typed twice. Reviewing a picture of the netlist against the intent is a
real step in real design.

> Use DigitalJS for the picture, never for the count. Its Yosys comes from a feed with no
> version pinned, so it isn't your workbench's 0.68. No lab in this course asks you to compare a
> browser cell count with a workbench cell count.

## Part 6: Run files that fail on purpose

The rest of this lab uses `labs/guide-examples/`, which holds the runnable files printed in the
guide pages you read before this lab. It needs no environment setup either.

1. Run the package's own finished adder, `src/full_adder.sv` in `guide-examples` (not yours),
   against the eight rows:

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
   simulation.)

   The first three rows pass. Someone testing by hand in a hurry tries `000`, `001`, `010`, sees
   three passes, and ships a design that is half wrong. And `vvp` exited 0 after finding four
   wrong rows, because "the simulation ran" and "the design is correct" are different questions
   and `vvp` only answers the first. The package's `Makefile` decides with `grep -q "^PASS"`:
   trust a line you told the simulator to print, never its exit status.

3. Run the files that misbehave on purpose:

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
   `sky130_fd_sc_hd__maj3_1` each. Areas are in square micrometres. Check sections 4 to 6 against the
   arithmetic in
   [Modules and instances](guide/what-a-module-is.md): $15.0144 \times 2 + 6.2560 = 36.2848$
   with the walls up, and 33.7824 with them knocked down.

   `make` with no target in `guide-examples` runs most of the steps in Parts 6 and 7, including
   this synthesis, and ends with the area checker's table:

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

   `boxes.json` says 7 cells because Yosys counts the two `half_adder` instances as cells and
   also counts what is inside them: 5 real gates plus 2 boxes (`lpflow_inputiso1p_1` is the Or
   gate under an odd catalogue name). `boxes_flat.json` says 2 because the Yosys command `flatten`
   removed the module boundaries and let the synthesizer rebuild across them.

4. Draw the schematic in the workbench with the same Yosys commands DigitalJS runs:

   ```bash
   make picture
   ```

   You should see `5 cells`, `2 $and`, `1 $or`, `2 $xor` and
   `wrote results/full_adder_rtl.svg -- open it in a browser`. Open the SVG in a web browser (on
   your own machine it is in your `workspace` folder, under
   `modules/dd102/labs/guide-examples/results/`) and find the wire names you typed (`ha1_sum`, `ha1_carry`, `ha2_carry`).

5. Back in DigitalJS, reload the page so only one file is loaded. Type `full_adder_table` in the
   file-name box, press **Create file**, paste
   [`src/full_adder_table.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_table.sv)
   (the `always_comb` + `case` version) into it and press **Run**. You should see a
   single box labelled **Memory** with an address input, and no gates. The circuit isn't
   different; [Seeing your adder as a schematic](guide/seeing-it-come-back.md) explains why.

6. Load the two-file version. Reload the DigitalJS page first so only these two files are loaded.
   Type `full_adder_hier` in the file-name box, press **Create file** and paste
   [`src/full_adder_hier.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_hier.sv)
   into it, then type `half_adder` in the box and press **Create file** again for a second file, paste
   [`src/half_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/half_adder.sv)
   into it, and press **Run**. On its own, `full_adder_hier.sv` won't run, because DigitalJS has
   never heard of `half_adder`. You should see `half_adder` drawn as one box, twice. Hover one
   box, click the **🔍** that appears above it, and the view descends into the box to show its Xor
   and And. (The *Additional SystemVerilog files:* picker further down the Setup tab does the
   same job from files on your disk.)

7. Optional, about two minutes: reload the page and load your own `full_adder.sv` again as in
   Part 5, then tick **Convert to logic gates**
   and then **Map into subset of gates** with its default set, and press **Run**. You should see
   three NANDs and two XORs; Yosys rebuilt your Or and both Ands out of NAND, as you did by hand
   in [DD101 Lab 02](https://uoftasic.com/dd101/#/labs/lab-02-gates-from-one-gate). Ticking only
   **Convert to logic gates** just renames your five gates from `$and`/`$or`/`$xor` to
   `$_AND_`/`$_OR_`/`$_XOR_`. Neither option shows an area or what a factory would build. Untick
   them before you compare anything with your drawing.

8. With a circuit on screen, the 📁 (*Load from file*), 💾 (*Save to file*) and 🔗 (*Get link*)
   buttons wake up. The first two save and reload the circuit as JSON. 🔗 turns what you are
   looking at into a URL. When you ask for help in [Discord](https://discord.gg/hrJnP5UsGz), post
   that link rather than a screenshot, so whoever answers can click your inputs themselves.

## Finishing

You're done when `make` in `labs/lab-01-transcribe-your-adder/` prints
`src/full_adder.sv : PASS  8/8   <-- Lab 01 is done.`

`make` always exits 0; the verdict is the text. `make grade` is the same check with an exit
status a script can read. It prints `make: *** [Makefile:92: grade] Error 1` until you pass.

Reference numbers, from `hpretl/iic-osic-tools:2026.08` (Icarus Verilog 14.0, Python 3.12.3):

| What | Result |
|---|---|
| `reference/full_adder.sv`, all 8 rows | PASS |
| `src/full_adder.sv` as shipped | FAIL, 8 of 8 rows disagree, every output `x` |
| `src/full_adder.sv` once you write it | PASS, 8 of 8 |
| `verilator --lint-only` on the stub | 0 warnings, exit 0 |
| `verilator --lint-only -Wall` on the stub | 5 warnings, exit 1 |

Stuck? Ask in the [team Discord](https://discord.gg/hrJnP5UsGz). Save a DigitalJS link (Part 7,
step 8) or an [EDA Playground](https://www.edaplayground.com/) link (see
[Getting started](guide/getting-started.md)) and paste that instead of describing the problem.

Next on the [Course path](README.md#course-path): read [Testbenches](guide/eight-rows-and-no-opinions.md),
then do [Lab 02: Prove it](labs/lab-02-prove-it-overview.md).
