# Reading a waveform

**Question this page answers:** *There is a window full of lines. What am I looking at, and how
do I find the exact moment it went wrong?*

A lookup card. [Two lines make the waveform appear](guide/two-lines-make-the-waveform-appear.md)
is the page that teaches this; this one is what you keep open beside the viewer.

## The three viewers, and the one idea

| | Where | Version | Takes its signal list from |
|---|---|---|---|
| **GTKWave** | workbench, noVNC desktop | `GTKWave Analyzer v4.0.0-prealpha (8ba24ab)` | a `.gtkw` **save file** |
| **Surfer** | workbench, noVNC desktop | `surfer 0.6.0 (git: v0.6.0)` | a `--command-file` of plain commands |
| **EPWave** | inside EDA Playground, browser | — | the checkbox **Open EPWave after run** |

All three read the same `.vcd` file, all three draw the same picture, and **none of them shows
you anything until you tell it which signals you care about.** That is the single fact that
saves the most time.

## What you see the moment it opens

```bash
gtkwave results/sweep.vcd
```

![GTKWave immediately after opening a VCD with no save file: the signal tree on the left shows only tb_sweep, the signal list below it is empty, and the wave pane on the right is solid black](assets/img/dd102-gtkwave-opened.png)

**This is not a broken simulation.** The file is 57,207 bytes and contains 55 signals. The pane
is black because you have not added any of them yet.

Four things in that picture, named:

| What | Where | What it is |
|---|---|---|
| **SST** | top left | the design tree. `tb_sweep` with a triangle to expand — the testbench, and everything under it |
| **Type / Signals** | bottom left | the signals *inside* whatever you selected in SST. Drag from here to the wave pane |
| the black pane | right | the waveform. Empty until something is dragged in |
| **From: / To:** | toolbar | the range of the whole file. Here, `0 sec` to `10240 ns` |

And one thing that catches everybody: **look at the ruler across the top of the black pane. It
reads `1 ps`, `2 ps`, `3 ps`.** GTKWave opens fully zoomed *in*, at time zero, on a run that is
ten million picoseconds long. Even after you add signals you will see nothing but flat lines
until you zoom out.

> **Reflex: the first thing you do in a fresh GTKWave window is `Time → Zoom → Zoom Best Fit`.**
> The second is add signals. In either order — but do both before you conclude anything.

The way to skip all of this is to open a save file with the data file, which is what every
`make wave` in this course does:

```bash
gtkwave results/sweep.vcd views/sweep.gtkw
```

## What the marks mean

| Mark | Meaning |
|---|---|
| a line along the top or the bottom | a **1-bit** signal, high or low |
| a box with a number in it, pinching at each change | a **multi-bit** signal. The number is its value over that stretch |
| **red**, usually reading `x` or `xx` | **unknown.** Nobody has driven this signal yet |
| red and reading `z` | **high impedance** — nothing is driving it at all. You meet this in [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md), where a loop bound one too small leaves `sum[3]` and `cout` with no driver and every one of 512 answers comes back `Z` |
| a vertical line you can drag | the **marker**. Everything in the value column is read at the marker |
| the number after a name, e.g. `cin =1` | not part of the name — that signal's **value at the marker** |

**Red at time zero is normal.** Every register starts unknown; the first vector fixes it. In a
purely combinational design like this course's adder, **red after the first vector is a real
bug** — something is driving nothing, or two things are fighting.

## Reading a bus

The same wire, at the same instant, in three notations:

![GTKWave showing the nine-bit signal v three times, as hex 0FA, as decimal 250, and as binary 011111010](assets/img/dd102-gtkwave-radix.png)

`0FA` and `250` and `011111010` are **one value on one set of nine wires**. Only the notation
changed. If you ever find yourself thinking a bus "changed to hex", it did not; you changed how
it is written down.

Change it: select the trace, then **Edit → Data Format →** one of

```
Hex   Decimal   Binary   Octal   ASCII   Time   Enum
```

In a `.gtkw` save file, the format is the `@` number on the line above the signal:

| In the save file | Shows as | This course uses it for |
|---|---|---|
| `@22` | Hex | buses — `a[3:0]`, `sum[3:0]`, `expected[4:0]` |
| `@24` | Decimal | when you want to read the arithmetic directly |
| `@28` | Binary | every 1-bit signal — `cin`, `cout`, `mismatch` |
| `@200` then a line containing only `-` | a blank spacer row | separating inputs from outputs |

The figure above came from
[`views/radix.gtkw`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/views/radix.gtkw):

```bash
cd labs/guide-examples-proving-it
make sweep                                  # if results/sweep.vcd is not there yet
gtkwave results/sweep.vcd views/radix.gtkw
```

> A save file can also rename a trace for display, which is how that figure labels three copies
> of one signal: `+{v[8:0]  Hex}tb_sweep.v[8:0]`. The wire is untouched; only the label changes.

## Finding the moment something went wrong

Four steps, in this order. They work in every viewer.

**1 · Get the time out of the log, not out of the picture.** Every testbench in this course
prints it:

```
TESTED 512
ERRORS 256
FIRST MISMATCH at 30 ns
VERDICT FAIL
```

Hunting for a failure by eye across 512 vectors is a waste of an afternoon. The log already
knows.

**2 · Put your verdict in the waveform.** `tb_sweep.sv` computes a signal called `mismatch` and
dumps it like any other wire. It costs one line and it converts "somewhere in here" into a line
that goes high exactly where you broke it. Steal this forever.

**3 · Park the marker on that time.** In GTKWave, type the time into the **Marker** box in the
toolbar, or `Time → Move To Time`. In a save file it is the second field of the `*` line —
`*-14.4 30000 -1 …` means zoom −14.4, marker at 30000 (the VCD's own units, picoseconds here,
so 30 ns). In Surfer: `marker_set 1 30000`.

**4 · Read the value column, not the shapes.** With the marker parked, every name on the left
carries its value at that instant. For the broken ripple adder that is
`a[3:0] =0`, `b[3:0] =0`, `cin =1`, `sum[3:0] =0`, `cout =0`, `expected[4:0] =01`,
`mismatch =1` — which is the failing case stated outright: **0 + 0 + 1, and the adder said 0.**

To step to the next disagreement rather than the first: highlight `mismatch`, then
`Markers → Find Next Edge`.

## The GTKWave menus you will actually use

| Want to | Menu |
|---|---|
| see the whole run at once | `Time → Zoom → Zoom Best Fit` |
| zoom in / out one step | `Time → Zoom → Zoom In` / `Zoom Out` |
| undo a zoom you regret | `Time → Zoom → Undo Zoom` |
| jump the marker to a time | `Time → Move To Time` |
| jump to the next change of the highlighted signal | `Markers → Find Next Edge` |
| leave a named marker behind | `Markers → Drop Named Marker` |
| change hex/decimal/binary | `Edit → Data Format → …` |
| insert a gap between groups of signals | `Edit → Insert Blank` |
| find a signal by name in a big design | `Search → Signal Search Regexp` |
| **keep the layout you just built** | `File → Write Save File As` |
| save the picture | `File → Grab To File` |

That last-but-one is the one people wish they had known: build the view once, write the save
file, and `gtkwave x.vcd x.gtkw` reproduces it forever. Every `views/*.gtkw` in this repo was
made that way.

## Surfer, in one file

Surfer takes a plain-text command file instead of a save file:

```bash
surfer --command-file views/sweep.surf results/sweep.vcd
```

| Command | What it does |
|---|---|
| `scope_select tb_sweep` | make that module the current scope |
| `variable_add tb_sweep.mismatch` | add one signal to the view |
| `divider_add carry` | a labelled separator row (one word — extra words are an error) |
| `marker_set 1 30000` | marker number 1, at that time in the file's own units |
| `show_marker_window` | open the marker readout panel |
| `variable_set_name_type Local` | show short names instead of full paths |
| `goto_start` / `goto_end` | jump to either end of the run |
| `zoom_fit` | fit the whole run in the window |

**`zoom_fit`, not `zoom_to_fit`.** The spelling that reads better is the one that does not
exist, and Surfer's reaction to a command it does not know is the trap:

```
ERROR libsurfer::batch_commands: Error on batch commands line 12: InvalidParameter(
    "zoom_to_fit",
)
```

**Surfer prints that and opens anyway.** One red line in a scroll of blue `INFO` lines, and a
window that looks fine but is not doing what your file asked. Nothing exits non-zero.

> **Reflex: after editing a `.surf` file, `grep ERROR` your own console before you trust the
> window.**

The blue `INFO` wall itself is normal. `Looking for user decoders at
/headless/.config/surfer/decoders`, `Looking for user mapping translators at …`, `Watching file
… for changes` — Surfer narrating its startup, four or five paths that do not exist on your
machine, none of it a problem.

## Symptom → cause

| What you see | What it is |
|---|---|
| the wave pane is completely black | no signals added. Not a failed simulation |
| signals added, but every line is flat | you are zoomed in at time 0. `Zoom Best Fit` |
| `Could not initialize GTK!  Is DISPLAY env var/xhost set?` | you ran GTKWave from a terminal with no desktop. It needs the noVNC desktop |
| no `.vcd` file at all after a run | the testbench has no `$dumpfile`/`$dumpvars` |
| EDA Playground ran fine, no waveform window | pop-ups blocked, or **Open EPWave after run** unticked |
| a bus reads `xx` in red at t = 0 | normal. Nobody has driven it yet |
| a bus reads `x` in red *after* the first vector | a real bug in a combinational design |
| Surfer opened but ignored half your command file | a typo'd command. Look for the one red `ERROR` line |
| `$finish called at 10240000 (1ps)` | the testbench finishing normally, reported in picoseconds |

## The dead end

**`ping` is not installed in the workbench.** When a browser tool will not load and you want to
know whether the network is the problem, `ping` answers `command not found`, which reads like a
broken container and is not. Use `curl`, which is there:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://www.edaplayground.com/
```

```
200
```

[The three services](reference/the-three-browser-tabs.md) is the page about what to do with the
answer.

## What to carry forward

| | |
|---|---|
| an empty pane | means no signals added, never that nothing ran |
| a fresh GTKWave window | opens zoomed all the way in at t = 0. Zoom Best Fit first |
| a bus | is a box with a number in it; the notation is yours to choose |
| red | unknown. Fine at t = 0, a bug afterwards |
| the value column | is a readout at the marker, not part of the signal name |
| finding a bug | dump a verdict signal, read the time from the log, park the marker |
| a view worth keeping | `File → Write Save File As`, and commit the `.gtkw` |
| `zoom_fit` | the Surfer spelling. `zoom_to_fit` fails silently-ish and the window still opens |
