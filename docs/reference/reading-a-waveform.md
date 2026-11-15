# Reading a waveform

A lookup card to keep open beside the viewer. [Waveforms](../guide/two-lines-make-the-waveform-appear.md)
is the page that teaches this, and [Lab 03, Part 2](../labs/lab-03-the-lazy-testbench-overview.md) is
where you do it.

## The three viewers

| | Where | Version | Takes its signal list from |
|---|---|---|---|
| GTKWave | workbench, noVNC desktop | `GTKWave Analyzer v4.0.0-prealpha (8ba24ab)` | a `.gtkw` save file |
| Surfer | workbench, noVNC desktop | `surfer 0.7.0 (git: v0.7.0)` | a `--command-file` of plain commands |
| EPWave | inside EDA Playground, in the browser | — | the checkbox **Open EPWave after run** |

All three read the same `.vcd` file and draw the same picture, and none of them shows you anything
until you tell it which signals you care about. Knowing that saves more time than anything else on
this page.

## A fresh GTKWave window

```bash
gtkwave results/sweep.vcd
```

![GTKWave immediately after opening a VCD with no save file: the signal tree on the left shows only tb_sweep, the signal list below it is empty, and the wave pane on the right is solid black](../assets/img/dd102-gtkwave-opened.png)

This isn't a broken simulation. The file is about 57 KB and contains 55 signals. The pane is
black because you haven't added any of them yet.

| What | Where | What it is |
|---|---|---|
| SST | top left | the design tree. `tb_sweep` with a triangle to expand: the testbench, and everything under it |
| Type / Signals | bottom left | the signals inside whatever you selected in SST. Drag from here to the wave pane |
| the black pane | right | the waveform. Empty until something is dragged in |
| From: / To: | toolbar | the range of the whole file; here `0 sec` to `10240 ns` |

Look at the ruler across the top of the black pane: it reads `1 ps`, `2 ps`, `3 ps`. GTKWave
opens fully zoomed in, at time zero, on a run that is ten million picoseconds long. Even after you
add signals you'll see only flat lines until you zoom out.

> In a fresh GTKWave window, do `Time → Zoom → Zoom Best Fit` and add signals, in either order,
> before you conclude anything.

To skip all of this, open a save file with the data file, which is what every `make wave` in this
course does:

```bash
gtkwave results/sweep.vcd views/sweep.gtkw
```

## What the marks mean

| Mark | Meaning |
|---|---|
| a line along the top or the bottom | a 1-bit signal, high or low |
| a box with a number in it, pinching at each change | a multi-bit signal. The number is its value over that stretch |
| red, usually reading `x` or `xx` | unknown: nobody has driven this signal yet |
| red and reading `z` | high impedance: nothing is driving it at all. You meet this in [Lab 04](../labs/lab-04-four-adders-in-a-row-overview.md), where a loop bound one too small leaves `sum[3]` and `cout` with no driver and every one of 512 answers comes back `Z` |
| a vertical line you can drag | the marker. Everything in the value column is read at the marker |
| the number after a name, e.g. `cin =1` | not part of the name: that signal's value at the marker |

Red at time zero is normal: every register starts unknown and the first vector fixes it. In a
purely combinational design like this course's adder, red after the first vector is a real bug.
Something is driving nothing, or two things are fighting.

## Reading a bus

The same wire at the same instant, in three notations:

![GTKWave showing the nine-bit signal v three times, as hex 0FA, as decimal 250, and as binary 011111010](../assets/img/dd102-gtkwave-radix.png)

`0FA`, `250` and `011111010` are one value on one set of nine wires; only the notation changed. A
bus never "changes to hex"; you changed how it is written down.

To change it, select the trace, then **Edit → Data Format →** one of:

```
Hex   Decimal   Binary   Octal   ASCII   Time   Enum
```

In a `.gtkw` save file, the format is the `@` number on the line above the signal:

| In the save file | Shows as | This course uses it for |
|---|---|---|
| `@22` | Hex | buses: `a[3:0]`, `sum[3:0]`, `expected[4:0]` |
| `@24` | Decimal | when you want to read the arithmetic directly |
| `@28` | Binary | every 1-bit signal: `cin`, `cout`, `mismatch` |
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

1. Get the time from the log, not the picture. Every testbench in this course prints it:

   ```
   TESTED 512
   ERRORS 256
   FIRST MISMATCH at 30 ns
   VERDICT FAIL
   ```

   Hunting for a failure by eye across 512 vectors wastes an afternoon; the log already knows.

2. Put your verdict in the waveform. `tb_sweep.sv` computes a signal called `mismatch` and dumps
   it like any other wire. It costs one line, and it turns "somewhere in here" into a line that
   goes high exactly where the design broke.

3. Park the marker on that time. In GTKWave, type the time into the **Marker** box in the toolbar,
   or use `Time → Move To Time`. In a save file it is the second field of the `*` line:
   `*-14.4 30000 -1 …` means zoom −14.4, marker at 30000 (the VCD's own units, picoseconds here,
   so 30 ns). In Surfer: `marker_set 1 30000`.

4. Read the value column, not the shapes. With the marker parked, every name on the left carries
   its value at that instant. For the broken ripple adder that is `a[3:0] =0`, `b[3:0] =0`,
   `cin =1`, `sum[3:0] =0`, `cout =0`, `expected[4:0] =01`, `mismatch =1`: the failing case
   stated outright, 0 + 0 + 1, and the adder said 0.

To step to the next disagreement rather than the first, highlight `mismatch` and use
`Markers → Find Next Edge`.

## GTKWave menus

| Want to | Menu |
|---|---|
| see the whole run at once | `Time → Zoom → Zoom Best Fit` |
| zoom in / out one step | `Time → Zoom → Zoom In` / `Zoom Out` |
| undo a zoom | `Time → Zoom → Undo Zoom` |
| jump the marker to a time | `Time → Move To Time` |
| jump to the next change of the highlighted signal | `Markers → Find Next Edge` |
| leave a named marker behind | `Markers → Drop Named Marker` |
| change hex/decimal/binary | `Edit → Data Format → …` |
| insert a gap between groups of signals | `Edit → Insert Blank` |
| find a signal by name in a big design | `Search → Signal Search Regexp` |
| keep the layout you just built | `File → Write Save File As` |
| save the picture | `File → Grab To File` |

`File → Write Save File As` is the one people wish they had known: build the view once, write the
save file, and `gtkwave x.vcd x.gtkw` reproduces it every time. Every `views/*.gtkw` in this repo
was made that way.

## Surfer command files

Surfer takes a plain-text command file instead of a save file:

```bash
surfer --command-file views/sweep.surf results/sweep.vcd
```

| Command | What it does |
|---|---|
| `scope_select tb_sweep` | make that module the current scope |
| `variable_add tb_sweep.mismatch` | add one signal to the view |
| `divider_add carry` | a labelled separator row (one word; extra words are an error) |
| `marker_set 1 30000` | marker number 1, at that time in the file's own units |
| `show_marker_window` | open the marker readout panel |
| `variable_set_name_type Local` | show short names instead of full paths |
| `goto_start` / `goto_end` | jump to either end of the run |
| `zoom_fit` | fit the whole run in the window |

The command is `zoom_fit`, not `zoom_to_fit`. The spelling that reads better doesn't exist, and
Surfer's reaction to a command it doesn't know is the trap:

```
ERROR libsurfer::batch_commands: Error on batch commands line 12: InvalidParameter(
    "zoom_to_fit",
)
```

Surfer prints that and opens anyway: one red line in a scroll of blue `INFO` lines, and a window
that looks fine but isn't doing what your file asked. Nothing exits non-zero. After editing a
`.surf` file, `grep ERROR` your console output before you trust the window.

The blue `INFO` lines themselves are normal. `Looking for user decoders at
/headless/.config/surfer/decoders`, `Looking for user mapping translators at …` and `Watching file
… for changes` are Surfer describing its startup, including four or five paths that don't exist on
your machine; none of it is a problem.

## Symptom → cause

| What you see | What it is |
|---|---|
| the wave pane is completely black | no signals added. Not a failed simulation |
| signals added, but every line is flat | you are zoomed in at time 0. `Zoom Best Fit` |
| `Could not initialize GTK!  Is DISPLAY env var/xhost set?` | you ran GTKWave from a terminal with no desktop. It needs the noVNC desktop |
| no `.vcd` file at all after a run | the testbench has no `$dumpfile`/`$dumpvars` |
| EDA Playground ran fine, no waveform window | pop-ups blocked, or **Open EPWave after run** unticked |
| a bus reads `xx` in red at t = 0 | normal. Nobody has driven it yet |
| a bus reads `x` in red after the first vector | a real bug in a combinational design |
| Surfer opened but ignored half your command file | a mistyped command. Look for the one red `ERROR` line |
| `$finish called at 10240000 (1ps)` | the testbench finishing normally, reported in picoseconds |

## `ping` isn't installed

`ping` isn't installed in the workbench. When a browser tool won't load and you want to know
whether the network is the problem, `ping` answers `command not found`, which looks like a broken
container and isn't. Use `curl`, which is there:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://www.edaplayground.com/
```

```
200
```

[The browser tools](../reference/the-three-browser-tabs.md) says what to do with the answer.

## Summary

| | |
|---|---|
| an empty pane | means no signals added, never that nothing ran |
| a fresh GTKWave window | opens zoomed all the way in at t = 0; Zoom Best Fit first |
| a bus | is a box with a number in it; the notation is yours to choose |
| red | unknown. Fine at t = 0, a bug afterwards |
| the value column | is a readout at the marker, not part of the signal name |
| finding a bug | dump a verdict signal, read the time from the log, park the marker |
| a view worth keeping | `File → Write Save File As`, and commit the `.gtkw` |
| `zoom_fit` | the Surfer spelling. `zoom_to_fit` fails with one easy-to-miss `ERROR` line and the window still opens |
