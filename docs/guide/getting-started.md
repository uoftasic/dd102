# Getting started

This page covers what you need for DD102, how the course is laid out, the three websites it uses
alongside the workbench, and how to get help. You load the course into your workbench in
[Lab 01, Part 1](labs/lab-01-transcribe-your-adder-overview.md).

## What to have next to you

Find two things from DD101 and keep them where you can see them:

- your hand-drawn full-adder diagram, and
- your filled-in 8-row truth table.

Lab 01 asks you to type your drawing out line by line, and its testbench checks your module
against those eight rows. The handoff from DD101 is paper on purpose: nothing digital crosses
over, because typing the drawing out yourself is the lesson.

## How the course works

The [Course path](README.md#course-path) on the home page is the order to work in. Each row is
either reading or a lab:

- Guide pages, like this one, are for reading. They explain the ideas and show worked examples.
  Where a page shows tool output, you run that command yourself later, in the lab the page points
  to.
- Lab writeups are where you do things. Each lab is a list of numbered parts and steps, and each
  part ends with what you should see.

Every lab package under `labs/` runs with `make` and ends in a `PASS`/`FAIL` verdict printed as
text. None of them needs `.designinit`, a PDK variable or any other environment variable, so a
broken shell profile won't stop a lab from running.

## The workbench

DD102 needs one Docker image and a browser. You set up the image in
[IC101](https://uoftasic.com/ic101/): Docker, the `workspace` repo and the noVNC desktop. This
course is pinned to `hpretl/iic-osic-tools:2026.08`, which runs Yosys 0.68, Icarus Verilog 14.0,
Verilator, nextpnr, IceStorm, GTKWave and Surfer. Every printed result in this course came from
that image. If a step fails, the fix is almost always back in IC101.

## The three browser tabs

DD102 is the only course in the track with a useful browser half. It uses three websites
alongside the workbench, and each does one job better than the terminal. Your workbench can do
everything the first two do; HDLBits has no workbench equivalent, and nothing in DD102 requires
it. More detail, including what to do when a site is down, is in
[The browser tools](reference/the-three-browser-tabs.md).

### DigitalJS Online

**<https://digitaljs.tilk.eu/>**: no account, nothing to install.

You paste SystemVerilog into a `.sv` tab, press **Run**, and get a schematic you can click, with
input toggles that drive the logic. It is Yosys compiled to WebAssembly, running inside your tab;
the "Synthesis mode" setting says `WebAssembly (faster and local)` and means it. It is the fastest
way to check a transcription: your paper drawing is on the desk, the machine's drawing is on the
screen, and if they aren't the same shape you typed something you didn't mean. You use it in Lab
01. [Seeing your adder as a schematic](guide/seeing-it-come-back.md) is the page about it.

Its Yosys isn't your Yosys, and it can change under you. DigitalJS pulls Yosys from a public
package feed with no version pinned. Your workbench runs 0.68; the feed's build was
0.65.176-dev.1145 on the day this page was checked, and it won't stay that number. Use DigitalJS
for the picture, never for the count. No lab asks you to compare a DigitalJS cell count with a
workbench one, and if you do, a difference isn't a bug.

Two of its checkboxes map onto things you already know. **Convert to logic gates → Map into
subset of gates** lets you tick `NAND` and nothing else, and watch your adder rebuild itself out
of the one gate you built everything from in DD101. **Map into LUTs** does what an FPGA does, the
subject of [Inside an FPGA](guide/the-chip-is-already-there.md).

### EDA Playground

**<https://www.edaplayground.com/>**: needs a Google login to run code, nothing to install.

It runs Icarus Verilog 12.0 and draws your waveform in the browser with EPWave. Its real value is
the permalink: you save a playground, paste the link into Discord, and whoever answers is looking
at the same code and the same run as you.

Two things to know before your first run:

- The editor gives you two fixed file names, `design.sv` and `testbench.sv`. Your module can
  still be called `full_adder`; the file it lives in is just named `design.sv` there.
- EPWave shows nothing unless your testbench calls `$dumpfile` and `$dumpvars` and you tick
  **Open EPWave after run**. An empty waveform window looks like a broken design and almost never
  is one. [Waveforms](guide/two-lines-make-the-waveform-appear.md) covers this.

Its Icarus is 12.0 against your workbench's 14.0, and its Yosys is 0.37 against your 0.68. For
everything DD102 asks you to write this makes no difference; where it could, the lab says so.

#### The one account

This is the only account the DD digital track asks you for. The site's front page says:

> *"You can start typing straight away. But to run your code, you'll need to sign or log in.
> Logging in with a Google account gives you access to all non-commercial simulators and some
> commercial simulators."*

You can read and edit without logging in; the Run button is what needs it. If you'd rather not
make an account, nothing in DD102 breaks: everything EDA Playground simulates, your workbench
simulates too, and the lab packages are written for the workbench first. What you lose is the
shareable link, which matters when you need help. It's your call.

### HDLBits

**<https://hdlbits.01xz.net/wiki/Main_Page>**: no account needed to solve problems.

Small, tightly scoped problems. You write a module and the site checks it. In its own words:

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

An account only lets you pick up where you left off: *"If you want to track your progress or move
to another browser, create a username and password so you can log in from elsewhere."*

Two of its problems are DD102 in miniature: [Fadd](https://hdlbits.01xz.net/wiki/Fadd) ("Create
a full adder… Expected solution length: Around 2 lines") and
[Exams/m2014 q4j](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j), a 4-bit ripple adder built from
full adders. [Waveforms](guide/two-lines-make-the-waveform-appear.md) has a short list of
problems in the order the course builds.

The site calls its language Verilog, not SystemVerilog. In practice it accepts `logic` and
`always_ff`, which covers what DD102 asks you to write. If a keyword is ever rejected, the site is
older than your workbench; you aren't wrong.

## What you don't need

You don't need Quartus. If somebody in ECE241 tells you FPGAs mean Quartus, they are describing
a real industrial path, and it isn't this one. Quartus Prime Lite is a 31–40 GB install on top of
the ~20 GB you already have, it has no macOS build, and its simulator needs a licence step. DD102
uses the open FPGA flow already in your workbench, `yosys synth_ice40` → `nextpnr-ice40` →
`icepack`, and it produces a real bitstream for a real Lattice iCE40.

You don't need an FPGA board. No lab uses hardware. You build a real bitstream for a real part;
that it could be loaded onto one is the point, and owning one isn't required here or in DD103.

## Getting help

The course is self-paced, which doesn't mean you're on your own. Ask in the
[team Discord](https://discord.gg/hrJnP5UsGz) (<https://discord.gg/hrJnP5UsGz>), the same server
as DD101, DD103 and DD104. No question is too basic, and much of what looks like your mistake is
a tool being unhelpful.

- Paste a link, not a paragraph. Save an EDA Playground playground or a DigitalJS circuit and
  post the URL. It takes ten seconds, and the person answering stops guessing.
- Quote the exact error, from the top. Post the first error line, the command you ran, and the
  first line of `iverilog -V`.
- The first error line is the real one. Everything after it is fallout, and the fallout can point
  at the wrong place. Here is a full adder with one missing semicolon, at the end of the `logic`
  declaration on line 8:

  ```
  full_adder.sv:9: syntax error
  full_adder.sv:1: error: Syntax error in variable list.
  ```

  Neither message names line 8. The first names line 9, where the parser noticed, one line past
  the mistake, which is the usual offset for a missing semicolon. The second names line 1, where
  nothing is wrong: the parser gave up on the whole module and blamed the line it came in through.
  A student who reads the last line spends the evening staring at a correct `module full_adder (`.

  Give the same file to Yosys and you get one message, and a more useful one:

  ```
  full_adder.sv:9: ERROR: syntax error, unexpected TOK_ASSIGN, expecting ',' or ';' or '=' or '['
  ```

  It is the same line 9, but it says what it wanted there, `expecting ',' or ';'`, which points at
  the missing semicolon. When one tool's message is vague, try the other. `ERROR:` is also the
  word to search for in a Yosys log: it marks the real failures, and `Warning:` marks the rest.
- If a command on these pages doesn't do what the page says, that's a bug in the course. Every
  command here was run before it was written, so a mismatch means something drifted. Saying so in
  the Discord helps.

Before you ask about a lab, run `make` once more in a fresh terminal. No DD102 lab needs any
environment setup, so a package that fails while everything else works is nearly always a
half-finished shell setup rather than anything you wrote.
