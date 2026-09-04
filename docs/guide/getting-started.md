# Getting started

**Question this page answers:** *I have a drawing on paper. Where do I type?*

You did the hard part in [IC101](https://uoftasic.com/ic101/): Docker installed, the `workspace`
repo cloned, the noVNC desktop coming up in your browser. This page is three commands, two
version checks, and a short tour of the three browser tabs DD102 uses alongside them.

Nothing here installs anything. DD102 needs **one Docker image and a browser**, and that is the
whole tool story for the course.

If a step below fails, the fix is almost always back in IC101, not here.

## 0. What to have next to you

Before anything else, find two things from DD101 and put them where you can see them:

- your **hand-drawn full-adder diagram**, and
- your **filled-in 8-row truth table**.

They are not decoration and they are not optional. Lab 01 asks you to type your own drawing out
line by line, and Lab 01's testbench checks your module against those exact eight rows. The
handoff from DD101 is deliberately paper — nothing digital crossed the boundary, because
**the transcription is the lesson.**

## 1. Start the desktop

On your own machine, in your `workspace` clone:

```bash
cd workspace
./scripts/start_vnc.sh          # Windows: scripts\start_vnc.bat
```

Then open **http://localhost/** and open a terminal on that desktop. Every command from here
down is typed *inside* that terminal, not on your laptop.

Ports, passwords, resolution, and what to do when the page is blank: [IC101 — Launch the noVNC
desktop](https://uoftasic.com/ic101/#/guide/launch-novnc).

## 2. Load the environment

```bash
. /foss/designs/common/.designinit
```

```
ASIC-EDU: PDK=sky130A  PDK_ROOT=/foss/pdks  designs=/foss/designs
          run 'mod' to list course modules, or 'mod <name>' to enter one.
```

That leading `.` is the shell's `source` command. It runs the file *in your current shell*
instead of a child process, which is the only way a script can change your environment. Typing
the path without the dot and the space does nothing useful.

You must do this **in every new terminal.** It does not stick.

> **DD102 does not care about the PDK.** That banner mentions `sky130A`, and you can ignore it
> here. A PDK describes how to *build* a chip, and DD102 never builds one — it configures a
> chip somebody else already built. Nothing in this course reads a liberty file, and no lab
> here needs `STD_CELL_LIBRARY` set. That conversation starts in DD103, on its first page.
>
> The one thing you need from `.designinit` is the `mod` command in step 3.

## 3. Get the course files

```bash
mod add dd102      # first time only — clones github.com/uoftasic/dd102
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

`mod` is a shell function that `.designinit` defines. `mod` on its own lists what you already
have:

```
Available modules:
dd102
ic101_setup
```

Everything lands under `/foss/designs/modules/`, which is your `workspace` folder bind-mounted
into the container. Your files are on **your** disk. Deleting the container does not delete
your work.

### Three errors you will see at least once

| What you see | What it means |
|---|---|
| `bash: mod: command not found` | You did not run step 2 *in this terminal*. Every new tab starts clean. |
| `mod: no such module: dd102` | You ran `mod dd102` before `mod add dd102`. It prints the list of what you *do* have underneath. |
| `fatal: could not read Username for 'https://github.com'` | git is being asked to log in, which means the repo did not answer anonymously. **That is almost never your spelling.** Open <https://github.com/uoftasic/dd102> in a browser: if it 404s for you, the repo is not published yet and this is on us, not you — say so in [Discord](https://discord.gg/hrJnP5UsGz) and we will fix it. |
| `bash: /foss/designs/common/.designinit: No such file or directory` | The workspace is not mounted. `ls /foss/designs/` should list `common/` and `modules/`; if it is empty you started a bare container instead of the workbench. Relaunch with `start_vnc.sh` from your `workspace` clone — see [IC101](https://uoftasic.com/ic101/). **You can still run every lab: `make` alone needs none of this.** |

## 4. Check your versions

This course is pinned to `hpretl/iic-osic-tools:2026.08`. Two commands confirm you are on it:

```bash
yosys -V
```

```
Yosys 0.68 (git sha1 38e001a6f, Release, GNU /usr/bin/c++ 13.3.0)
```

```bash
iverilog -V
```

```
Icarus Verilog version 14.0 (devel) (s20260301-391-g64f13540-dirty)
```

**Before you scroll: `iverilog -V` prints 73 lines.** The one above is the first; the other 72
are the GNU General Public License and a list of code generators. It exits 0. This is normal
and it is the longest version banner you will meet all course.

> **Do not pipe it into `head`.** `iverilog -V | head -2` cuts the pipe while Icarus is still
> asking its own sub-programs for *their* versions, and Icarus complains about it:
>
> ```
> Unable to get version from "/foss/tools/iverilog/lib/ivl/ivlpp -V"
> ```
>
> The number of those lines changes run to run, and none of them means anything is wrong with
> your install. **Reflex: run version checks unpiped.** More generally — a pipe can hide or
> invent output, and you will see this rule again in
> [When Icarus says syntax error](reference/when-icarus-says-syntax-error.md).

The rest of the set, if you want to check it:

| Tool | Command | Expect |
|---|---|---|
| Yosys | `yosys -V` | `Yosys 0.68` |
| Icarus Verilog | `iverilog -V` | first line `Icarus Verilog version 14.0 (devel)` |
| Verilator | `verilator --version` | `Verilator 5.050 2026-07-01 rev v5.050` |
| nextpnr | `nextpnr-ice40 --version` | `"nextpnr-ice40" -- Next Generation Place and Route (Version nextpnr-0.11.1-9-gb17408e2)` |
| Surfer | `surfer --version` | `surfer 0.6.0 (git: v0.6.0)` |

**`0.64` and `14.0` are the two numbers that matter.** Every printed result in this course came
from a run on those. If you see something else, you are on a different image, and the numbers
on these pages may not be yours.

## The three browser tabs

DD102 is the only course in the track with a genuinely useful browser half. Open all three now;
the first two are load-bearing in Lab 02 and Lab 03.

### DigitalJS Online — the loop-closer

**<https://digitaljs.tilk.eu/>** · no account · nothing to install

Paste SystemVerilog into a `.sv` tab, press **Run**, and switch to the **Circuit** view. You get
a schematic you can click on, with input toggles that actually drive the logic. It is **Yosys
itself, compiled to WebAssembly**, running inside your tab — the "Synthesis mode" setting says
`WebAssembly (faster and local)` and it means exactly that.

This is the fastest way to check a transcription. Your paper drawing is on the desk; the
machine's drawing is on the screen; if they are not the same shape, you typed something you did
not mean. Whole loop, about four seconds. [Seeing it come back as a schematic](guide/seeing-it-come-back.md)
is the page built around it.

> **Its Yosys is not your Yosys, and this can change under you.** DigitalJS pulls its Yosys
> from a public package feed with **no version pinned**. Your workbench is **0.64**; the feed's
> current build is **0.65.176-dev.1145** — checked the day this page was written, and it will
> not stay that number.
>
> **Reflex: use DigitalJS for the *picture*, never for the *count*.** No lab in this course ever
> asks you to compare a DigitalJS cell count against a workbench cell count, and if you do it
> yourself, a difference is not a bug.

Worth knowing about two of its checkboxes, because they map onto things you already know.
**Convert to logic gates → Map into subset of gates** lets you tick `NAND` and nothing else, and
watch your adder rebuild itself out of the one gate you built everything from in DD101.
**Map into LUTs** does the FPGA thing four courses early — that is [The chip is already
there](guide/the-chip-is-already-there.md), in a checkbox.

### EDA Playground — the one you can share

**<https://www.edaplayground.com/>** · **needs a Google login** · nothing to install

Icarus Verilog 12.0, plus **EPWave**, which draws your waveform in the browser. Its real value
is the permalink: you save a playground, paste the link into Discord, and whoever answers is
looking at the *exact* code and the *exact* run you are looking at. That is worth more than any
description of a bug you could type.

Two things to know before your first run:

- The editor gives you two fixed filenames — **`design.sv`** and **`testbench.sv`**. Your
  module can still be called `full_adder`; the file it lives in is just named `design.sv` here.
- **EPWave shows nothing unless your testbench calls `$dumpfile` and `$dumpvars`** *and* you
  tick **"Open EPWave after run"**. An empty waveform window reads like a broken design and is
  almost always neither. [Two lines make the waveform
  appear](guide/two-lines-make-the-waveform-appear.md) is that whole page.

Its Icarus is **12.0** against your workbench's **14.0**, and its Yosys is **0.37** against your
**0.64**. For everything DD102 asks you to write this makes no difference; where it could, the
lab says so.

#### The one account

This is the only account the entire DD digital track asks you for. The site says it plainly on
its own front page:

> *"You can start typing straight away. But to run your code, you'll need to sign or log in.
> Logging in with a Google account gives you access to all non-commercial simulators and some
> commercial simulators."*

You can **read** and **edit** without logging in — the Run button is what needs it. If you would
rather not create one, nothing in DD102 breaks: every simulation EDA Playground runs, your
workbench runs too, and the lab packages are written for the workbench first. What you lose is
the shareable link, which is a genuine loss when you need help. Your call, and it is a real one.

### HDLBits — the drill deck

**<https://hdlbits.01xz.net/wiki/Main_Page>** · no account needed to solve problems

Small, sharply-scoped problems. You write a module; the site simulates it and compares against a
reference. In its own words:

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

An account only exists so you can pick up where you left off: *"If you want to track your
progress or move to another browser, create a username and password so you can log in from
elsewhere."* You can solve every problem without one.

Two problems on it are DD102 in miniature, and the guide pages point you at them by name when
you are ready: [**Fadd**](https://hdlbits.01xz.net/wiki/Fadd) ("Create a full adder… Expected
solution length: Around 2 lines") and
[**Exams/m2014 q4j**](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j), which is a 4-bit ripple
adder built from full adders — the shape of this entire course, as one exercise.

The site calls its language **Verilog**, not SystemVerilog. In practice `logic` and `always_ff`
are accepted, which covers what DD102 asks you to write. If a keyword ever is not, that is the
site being older than your workbench, not you being wrong.

## What you do *not* need

**You do not need Quartus.** If somebody in ECE241 tells you that FPGAs mean Quartus, they are
describing a real and reasonable industrial path, and it is not this one. Quartus Prime Lite is
a **31–40 GB** install on top of the ~20 GB you already have, it has no macOS build at all, and
its simulator wants a licence ritual. DD102 uses the open FPGA flow that is **already sitting in
your workbench** — `yosys synth_ice40` → `nextpnr-ice40` → `icepack` — and it produces a real
bitstream for a real Lattice iCE40. Nothing is being withheld from you.

**You do not need an FPGA board.** Not one lab needs hardware. You will build a genuine
bitstream for a real part, and the fact that it *could* be loaded onto one is the point — owning
one is not a requirement, here or in DD103.

## Getting help

This course is self-paced, which is not the same as alone.

**Ask in the [team Discord](https://discord.gg/hrJnP5UsGz)** — <https://discord.gg/hrJnP5UsGz>.
Same server as DD101, DD103 and DD104. There is no such thing as a question too basic here, and
most of what looks like your mistake is a tool being unhelpful.

- **Paste a link, not a paragraph.** This is the one course where you can hand somebody the
  actual thing: save an EDA Playground playground and post the URL. Ten seconds of your time,
  and the person answering stops guessing.
- **Quote the exact error, and quote it from the top.** Post the first line, the command you
  ran, and what `iverilog -V` says on its first line. Three lines of that beats three paragraphs
  of description.
- **The first error line is the real one. Everything after it is fallout — and the fallout
  lies.** Here is a full adder with one missing semicolon, at the end of the `logic` declaration
  on line 8:

  ```
  full_adder.sv:9: syntax error
  full_adder.sv:1: error: Syntax error in variable list.
  ```

  Two messages, two different line numbers, and **neither of them is line 8**. The first names
  line 9, which is where the parser noticed — one line past the mistake, which is the usual
  offset for a missing semicolon. The second names **line 1**, where nothing whatsoever is
  wrong; it is the parser giving up on the whole module and blaming the door it came in
  through. A student who reads the last line spends the evening staring at a correct
  `module full_adder (`.

  Hand the identical file to Yosys and you get **one** message, and a far better one:

  ```
  full_adder.sv:9: ERROR: syntax error, unexpected TOK_ASSIGN, expecting ',' or ';' or '=' or '['
  ```

  Same line 9, but now with what it wanted there — `expecting ',' or ';'` — which points
  straight at the missing semicolon. **When two tools disagree about how helpful they are being,
  read the more talkative one.** `ERROR:` is also the word to search for in a Yosys log: it
  marks the real failures, and `Warning:` marks the rest. Read from the top, quote from the top.

- **If a command on these pages does not do what the page says it does, that is a bug in the
  course.** Report it. Every command here was run before it was written, so a mismatch means
  something drifted and we want to know. Saying so in the Discord is a contribution, not a
  complaint.

> **Before you ask about a lab, try `make` once more in a fresh terminal.** No DD102 lab reads a
> PDK, a liberty file, or any environment variable, so a package that fails while the guide's
> commands work is nearly always a half-finished shell setup rather than anything you wrote.

## You are ready when

```bash
. /foss/designs/common/.designinit
mod dd102
yosys -V                       # Yosys 0.68
iverilog -V                    # first line: Icarus Verilog version 14.0 (devel)
ls labs/                       # the five lab packages
```

```
lab-01-transcribe-your-adder
lab-02-prove-it
lab-03-the-lazy-testbench
lab-04-four-adders-in-a-row
lab-05-onto-the-fpga
```

…and your DD101 drawing and truth table are on the desk next to you.

Next: [From your drawing to a module](guide/from-your-drawing-to-a-module.md), where you find
out what SystemVerilog actually adds to the picture you already made — and that it is much less
than you are bracing for.
