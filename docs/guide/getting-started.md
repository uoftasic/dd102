# Getting started

This page tells you what you need for DD102, how the course is laid out, which three websites it
uses alongside the workbench, and how to get help when you're stuck. You won't load the course
into your workbench until [Lab 01, Part 1](../labs/lab-01-transcribe-your-adder-overview.md).

## What to have next to you

Find two things from DD101 and keep them where you can see them:

- your hand-drawn full-adder diagram, and
- your filled-in 8-row truth table.

Lab 01 asks you to type your drawing out line by line, and its testbench checks your module
against those eight rows. The handoff from DD101 is on paper, and nothing digital carries over.
We did that on purpose, because typing the drawing out yourself is what the lab is teaching.

## How the course works

The [Course path](../index.md#course-path) on the home page is the order to work in. Each row is
either reading or a lab:

- Guide pages, like this one, are for reading. They explain the ideas and show worked examples.
  Where a page shows tool output, you run that command yourself later, in the lab the page points
  to.
- Lab writeups are where you do things. Each lab is a list of numbered parts and steps, and each
  part ends with what you should see.

Every lab package under `labs/` runs with `make`, and it ends by printing a `PASS`/`FAIL` verdict
as text. None of them needs `.designinit`, a PDK variable or any other environment variable, so a
broken shell profile won't stop a lab from running.

## The workbench

DD102 needs one Docker image and a browser. You already set up the image in
[IC101](https://uoftasic.com/ic101/), along with Docker itself, the `workspace` repo and the noVNC
desktop. The course is pinned to `hpretl/iic-osic-tools:2026.08`, which comes with Yosys 0.68,
Icarus Verilog 14.0, Verilator, nextpnr, IceStorm, GTKWave and Surfer, and every printed result
in the course came from that image. If a step fails, the fix is almost always back in IC101.

## The three browser tabs

DD102 is the only course in the track where browser tools do useful work alongside the
workbench. It uses three websites, and each one does one job better than the terminal does. Your
workbench can do everything the first two sites do. HDLBits has no workbench equivalent, but
nothing in DD102 requires it. [The browser tools](../reference/the-three-browser-tabs.md) has
more detail on all three, including what to do when a site is down.

### DigitalJS Online

**<https://digitaljs.tilk.eu/>**: no account, nothing to install.

You paste SystemVerilog into a `.sv` tab, press **Run**, and get a schematic you can click, with
input toggles that drive the logic. Underneath, it's Yosys compiled to WebAssembly and running
inside your browser tab. It's the fastest way to check a transcription: your paper drawing is on
the desk, the machine's drawing is on the screen, and if they aren't the same shape, you typed
something you didn't mean. You'll use it in Lab 01, and
[Seeing your adder as a schematic](../guide/seeing-it-come-back.md) is the page about it.

DigitalJS doesn't run the same Yosys as your workbench, and because it fetches Yosys with no
version pinned, its version can change without warning. So use DigitalJS for the picture, and
never for the cell count. [Its Yosys version](../reference/the-three-browser-tabs.md#its-yosys-version)
on the browser tools page gives the two versions and what to make of a difference.

Two of its checkboxes map onto things you already know. **Convert to logic gates → Map into
subset of gates** lets you tick `NAND` and nothing else, and then watch your adder rebuild itself
out of the one gate you built everything from in DD101. **Map into LUTs** does what an FPGA does,
which is the subject of [Inside an FPGA](../guide/the-chip-is-already-there.md).

### EDA Playground

**<https://www.edaplayground.com/>**: needs a Google login to run code, nothing to install.

It runs Icarus Verilog 12.0 and draws your waveform in the browser with EPWave. What makes it
worth using is the permalink: once you save a playground you can paste its link into Discord, and
whoever answers is then looking at the same code and the same run as you.

Two things to know before your first run:

- The editor gives you two fixed file names, `design.sv` and `testbench.sv`. Your module can
  still be called `full_adder`; the file it lives in is just named `design.sv` there.
- EPWave shows nothing unless your testbench calls `$dumpfile` and `$dumpvars` and you tick
  **Open EPWave after run**. If either is missing you get an empty waveform window, which looks
  like a broken design, although it almost never is one.
  [Waveforms](../guide/two-lines-make-the-waveform-appear.md) covers this.

EDA Playground's Icarus is 12.0, against 14.0 in your workbench, and its Yosys is 0.37 against
your 0.68. That makes no difference for anything DD102 asks you to write, and where it could
matter, the lab says so.

#### EDA Playground account

This is the only account the DD digital track asks you for, and only the **Run** button needs it.
If you'd rather not make one, nothing in DD102 breaks, because your workbench can simulate
everything EDA Playground can, and the lab packages are written for the workbench first. What you
give up is the shareable link, which matters most when you need help. Whether that's worth an
account is your call. [The browser tools](../reference/the-three-browser-tabs.md#eda-playground)
quotes what the site's front page says about logging in.

### HDLBits

**<https://hdlbits.01xz.net/wiki/Main_Page>**: no account needed to solve problems.

HDLBits is a set of small, tightly scoped problems: you write a module, and the site checks it.
In its own words:

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

An account does nothing more than keep track of your progress, so that you can pick up where you
left off from another browser.

Two of its problems are DD102 in miniature: [Fadd](https://hdlbits.01xz.net/wiki/Fadd) ("Create
a full adder… Expected solution length: Around 2 lines") and
[Exams/m2014 q4j](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j), a 4-bit ripple adder built from
full adders. [Waveforms](../guide/two-lines-make-the-waveform-appear.md) has a short list of
problems, in the same order the course builds up the material.

The site calls its language Verilog rather than SystemVerilog, but in practice it accepts
SystemVerilog keywords such as `logic` and `always_ff`, and everything DD102 asks you to write
falls within what it accepts. If it ever rejects a keyword, that's because the site is older than
your workbench, and your code is fine.

## What you don't need

You don't need Quartus. If somebody in ECE241 tells you that FPGAs mean Quartus, they're
describing a real industrial path, just not the one this course takes. Quartus Prime Lite is a
31–40 GB install on top of the ~20 GB you already have, it has no macOS build, and its simulator
needs a licence step. DD102 uses the open FPGA flow already in your workbench, `yosys synth_ice40` → `nextpnr-ice40` →
`icepack`, and it produces a real bitstream for a real Lattice iCE40.

You don't need an FPGA board either, because no lab uses hardware. You build a real bitstream for
a real part, and the point is that it could be loaded onto one, but you don't have to own a board,
here or in DD103.

## Getting help

The course is self-paced, but that doesn't mean you're on your own. Ask in the
[team Discord](https://discord.gg/hrJnP5UsGz) (<https://discord.gg/hrJnP5UsGz>), the same server
as DD101, DD103 and DD104. No question is too basic, and much of what looks like your mistake is
a tool being unhelpful.

- Paste a link rather than a paragraph. Save an EDA Playground playground or a DigitalJS circuit
  and post its URL. It takes ten seconds, and it means the person answering doesn't have to guess
  what your code looks like.
- Quote the exact error, starting from the top: post the first error line, the command you ran,
  and the first line of `iverilog -V`.
- The first error line is where the real problem is. Everything after it is fallout from the first
  error, and the fallout can point at the wrong place. Here is what your workbench's Icarus 14.0
  says about a full adder with one missing semicolon, at the end of the `logic` declaration on
  line 8:

  ```
  full_adder.sv:9: syntax error
  full_adder.sv:8: error: Syntax error in variable list.
  ```

  The first message names line 9, where the parser noticed the problem; that's one line past the
  mistake, which is the usual offset for a missing semicolon. The second names line 8, where the
  declaration starts, so this time the fallout happens to land in the right place, but don't count
  on it. Icarus 12.0, the version EDA Playground runs, prints the same two messages with line 1 in
  the second one, where nothing is wrong at all: the parser gave up on the whole module and blamed
  the line where the module starts. If you read only the last line there, you can spend the
  evening staring at a perfectly correct `module full_adder (`.

  Give the same file to Yosys and you get one message, and a more useful one:

  ```
  full_adder.sv:9: ERROR: syntax error, unexpected TOK_ASSIGN, expecting ',' or ';' or '=' or '['
  ```

  It names the same line 9, but it also says what it expected to find there,
  `expecting ',' or ';'`, which points straight at the missing semicolon. So when one tool's
  message is vague, try the other one. `ERROR:` is also the word to search for in a Yosys log,
  because it marks the real failures, and `Warning:` marks everything else.
- If a command on these pages doesn't do what the page says, that's a bug in the course, and
  saying so in the Discord helps. We ran every command in the course before writing it down, so a
  mismatch means something has changed since.

Before you ask about a lab, run `make` once more in a fresh terminal. No DD102 lab needs any
environment setup, so a fresh terminal is a clean test: it starts without anything you changed in
the old one, and if the package fails the same way there, the cause is in the package's files
rather than in your shell.
