# Waveforms

Everyone who does this work will sooner or later show you a picture of lines stepping up and
down, and you already have the data for one of those pictures. When you ran the eight-row
testbench in Lab 02, Part 1, the first line it printed was:

```
VCD info: dumpfile eight.vcd opened for output.
```

and it left a waveform file, `eight.vcd`, in the same directory. This page explains how that file
gets written, what's in it, and how to read one in a viewer. You'll open these files yourself in
[Lab 03, Part 2](../labs/lab-03-the-lazy-testbench-overview.md).

## Two lines in the testbench

A waveform file comes from two lines in the testbench. They don't go in your design, which never
knows it is being watched:

```systemverilog
$dumpfile("sweep.vcd");     // what to call the file
$dumpvars(0, tb_sweep);     // what to put in it
```

`$dumpfile` names the output file and does nothing else. `$dumpvars` picks the signals to record. Its first argument says how many levels deep to go, and
its second says which module to start from. The `0` means "this module and everything inside it,
all the way down", so you get the testbench's own wires, everything inside `dut`, and everything
inside the four `full_adder`s inside that. A `1` would mean "this module only". Zero is the one
you want while you're learning, though it's also the setting that makes big files.

If you delete either line, the simulation still runs, still prints, and still passes or fails,
but it produces no waveform. So when a waveform is missing, the cause is almost always one of
these two lines, or a viewer that hasn't been told which signals to show, and almost never the
design.

## What is in a VCD file

A VCD (Value Change Dump) file is plain text, and it's worth looking inside one once so that it
stops being magic. These are the first fifteen lines of `eight.vcd` from the eight-row run. The
whole file is 1,147 bytes and 113 lines long:

```
$date
	Wed Aug 26 04:37:14 2026
$end
$version
	Icarus Verilog
$end
$timescale
	1ps
$end
$scope module tb_eight_rows $end
$var wire 1 ! sum $end
$var wire 1 " cout $end
$var reg 1 # a $end
$var reg 1 $ b $end
$var reg 1 % cin $end
```

(Your `$date` line will say when you ran it. Icarus writes `$timescale` as `1ps` because that is
the precision the testbench asked for with `` `timescale 1ns/1ps ``.)

After the header comes the data:

```
#0
$dumpvars
...
0%
0$
0#
0"
0!
$end
#10000
b1 (
#20000
1!
1%
```

There is nothing more to the format than this. Each signal gets a one-character nickname (`!`,
`"`, `#`, `$`, `%`) so that the file doesn't have to repeat long names thousands of times.
`#20000` is a timestamp: 20,000 ps, or 20 ns. `1!` means "the signal called `!`, which is `sum`,
became 1". Nothing is written while nothing changes, which is why the 512-vector sweep, 10,240 ns
of simulation, fits in about 57 KB. You won't read these files by hand, but when a viewer shows
you nothing, you can open the file and check whether the data is in it, which is a boring
question with a definite answer.

## How a viewer decides what to show

The workbench has two viewers, GTKWave and Surfer, and EDA Playground has a third, EPWave, that
runs in the browser. All three read the same `.vcd` file and draw the same picture, and none of
them shows you anything until you tell it which signals you care about.

- GTKWave takes its signal list from a **save file** (`.gtkw`), a plain-text list of which signals
  to show, in what order and at what zoom. If you open GTKWave without one, it shows a blank pane,
  because it doesn't guess which signals matter and waits for you to drag them across. Every
  viewer in this field behaves this way, and every beginner takes the blank pane to mean
  that the simulation produced nothing.
- Surfer takes its signal list from a **command file**, given with `--command-file`, which has one
  `variable_add` line per signal followed by `zoom_fit`. You can't use a GTKWave save file in
  Surfer, or the other way round.
- EPWave draws whatever the testbench dumped, but only if you tick **Open EPWave after run**. It
  opens in a new browser window, so a pop-up blocker can hide it without telling you.

You can use whichever viewer you prefer, because nothing in DD102 depends on the choice.
[Reading a waveform](../reference/reading-a-waveform.md) is the page to look up the menus and
commands for each one.

## Your first waveform

Here are the eight rows of one full adder, in GTKWave:

![GTKWave showing a, b and cin stepping through all eight combinations while sum and cout follow](../assets/img/dd102-wave-eight-rows.png)

Read it from left to right. Time runs along the top, from 0 to 160 ns, and each of the eight rows
of your truth table takes 20 ns.

Look at the three inputs first. `cin` changes twice as often as `b`, and `b` twice as often as
`a`. The testbench isn't doing anything clever here; this is simply what counting from 0 to 7 in
binary looks like when you draw each bit as a line. The rightmost bit flips every row, the next
one every second row, and the next every fourth. Your DD101 truth table has the same pattern in
its first three columns, so you are looking at your own table turned on its side.

Now look at `sum`. It is 1 on rows 1, 2, 4 and 7 and 0 on the other four, which are the rows where
an odd number of the three inputs are 1; that is what "Xor of three things" means. `cout` is low
for the first 60 ns, high from 60 to 80 ns, low again for 20 ns, and then high for the last 60 ns.
Check that against your paper: rows 3, 5, 6 and 7 are the four rows where `cout` is 1, and at
20 ns per row those are the intervals 60–80 ns and 100–160 ns. `cout` goes high whenever at least
two inputs are high, and that happens much more often once `a` is stuck at 1.

Reading a waveform comes down to this, because a waveform is a truth table with time on the
x-axis.

## Finding the moment something went wrong

This is a broken 4-bit ripple adder that gets 256 of its 512 inputs wrong, opened in GTKWave with
its save file. You run the sweep yourself in Lab 03, Part 1 and open this view in Part 2.

![GTKWave on the 512-vector sweep, zoomed in on the start of the run, with a marker at 30 ns and the mismatch signal going high](../assets/img/dd102-wave-first-mismatch.png)

There are four things to notice here, and it helps to take them in order.

The number after each signal's name is its value at the marker. The marker is the vertical line
parked at 30 000 ps (30 ns), which is where the log said `FIRST MISMATCH at 30 ns`. That makes the
left-hand column a readout rather than a list of labels: `a[3:0] =0`, `b[3:0] =0`, `cin =1`,
`sum[3:0] =0`, `cout =0`, `expected[4:0] =01`, `mismatch =1`. You can read the failing case off it
at a glance: the inputs were 0 + 0 + 1, and the adder said 0. It's the same case as the first
`MISMATCH` line in the log, but now you can also see the inputs that produced it.

`mismatch` is a signal, not a printed message. The testbench computes it and dumps it like any
other wire. That trick is worth copying in every testbench you write: if you put your verdict in
the waveform, its line goes high at exactly the point where the design went wrong.

Multi-bit signals are drawn as boxes with numbers in them rather than as lines. `a[3:0]` is four
bits wide, so a single high-or-low line can't represent it. Instead GTKWave draws a box that
pinches wherever the value changes, and writes the value inside it. `b[3:0]` shows `0`, then `1`,
then `2`, which is `b` counting up one step every two vectors.

For the first few nanoseconds, `expected[4:0]` is drawn in red and reads `xx`, which doesn't
mean anything is broken. At time zero the testbench hasn't assigned `expected` yet, so its value
is unknown, which is what `x` means, and every viewer draws unknown values in red so that you
can't mistake them for a 0. The red goes away when the first vector is applied, and red at t = 0 is normal. In a purely
combinational design like this one, though, red after the first vector is a real bug, and
spotting that is the most useful thing the red does for you.

## The whole run in Surfer

The same file in Surfer, with its command file:

![Surfer showing the whole 512-vector run at once, with the mismatch row striped on for about half the trace](../assets/img/dd102-surfer-sweep.png)

This view shows the whole run rather than the first eighty nanoseconds, so it tells you something
different. Look at the bottom row: `mismatch` is on for about half the picture, in a regular
stripe, rather than as an occasional blip among correct results. You could have guessed "exactly
half" from this image before counting anything.

Surfer labels its time axis in picoseconds (`10000000 ps` at the right-hand end), where GTKWave
writes `10240 ns` in its **To:** box. These describe the same run and the same length in
different units. The VCD header says `$timescale 1ps`, and the two viewers make different choices
about how to display that.

## `sorry:` from an older Icarus

EDA Playground runs Icarus Verilog 12.0, and your workbench runs 14.0. For everything DD102 asks
you to write, the difference doesn't matter. Every testbench in
[`labs/guide-examples-proving-it/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-proving-it)
was run on both, and all five verdicts came out identical:

```
eight: TESTED 8 ERRORS 0 VERDICT PASS
eight_broken: TESTED 8 ERRORS 4 FIRST MISMATCH at 70 ns VERDICT FAIL
six: TESTED 6 ERRORS 0 VERDICT PASS
sweep: TESTED 512 ERRORS 256 FIRST MISMATCH at 30 ns VERDICT FAIL
fixed: TESTED 512 ERRORS 0 VERDICT PASS
```

There is one place where the two versions disagree, and you'll run into it as soon as you try to
tidy up the testbench. This is the compact way to write the eight expected values, and you'll see
it in most of the SystemVerilog you meet:

```systemverilog
logic [1:0] expected [0:7] = '{
    2'b00, 2'b01, 2'b01, 2'b10,
    2'b01, 2'b10, 2'b10, 2'b11
};
```

That is correct SystemVerilog, and on your workbench it prints `VERDICT PASS`. The whole file is
[`src/tb_eight_rows_compact.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples-proving-it/src/tb_eight_rows_compact.sv).
On EDA Playground it gives:

```
testbench.sv:20: sorry: Assignment to an entire array or to an array slice is not yet supported.
Elaboration failed
```

When Icarus says `sorry:`, it is telling you that it hasn't implemented something, not that you
got it wrong. The message means "valid language, unsupported by this version". Nothing in your
file needs fixing; the version you are running just doesn't handle that construct
yet, and `iverilog -V` on EDA Playground says `12.0` where yours says `14.0`. That is why the
shipped `tb_eight_rows.sv` assigns the eight values one line at a time inside the `initial` block,
which is slightly longer but runs everywhere. When a tool says `sorry:`, check the version before
you change the code.

## Optional practice: HDLBits

The techniques on these pages need repetition, and the best set of drills for this material is
[HDLBits](https://hdlbits.01xz.net/wiki/Main_Page). It is a collection of small problems, each
checked by simulating your circuit against a reference, and it needs no account and keeps no
score. It was built by Henry Wong, a UofT ECE PhD who was a TA for ECE241, ECE253 and ECE243,
which are the courses many of you are about to take. In the site's own words:

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

In other words, HDLBits does to you what `tb_eight_rows.sv` does to your adder. Nothing in DD102
requires it, but if any of this hasn't stuck yet, these eight problems cover the course in
miniature, in the order the course builds it up:

| # | Problem | Why this one |
|---|---|---|
| 1 | [Hadd](https://hdlbits.01xz.net/wiki/Hadd) | *"Create a half adder."* Expected solution length: around 2 lines. This is your DD101 Lab 03, written in SystemVerilog. |
| 2 | [Fadd](https://hdlbits.01xz.net/wiki/Fadd) | *"Create a full adder."* Also around 2 lines. This is DD102 Lab 01, checked by somebody else's testbench. |
| 3 | [Module](https://hdlbits.01xz.net/wiki/Module) | You make one instance of a given sub-module, with its ports connected by position. |
| 4 | [Module_name](https://hdlbits.01xz.net/wiki/Module_name) | The same thing with the ports connected by name, which is the `.a(a)` style this course uses, and this problem shows you why it uses it. |
| 5 | [Adder3](https://hdlbits.01xz.net/wiki/Adder3) | *"Make 3 instances of it to create a 3-bit binary ripple-carry adder."* This is `ripple4`, one bit narrower. It also asks for the carry out of each adder, which makes you name the internal carries. |
| 6 | [Exams/m2014 q4j](https://hdlbits.01xz.net/wiki/Exams/m2014_q4j) | *"Implement the following circuit"*, and then it shows you a picture of four FA boxes. Transcribing a drawing into SystemVerilog with nothing else to go on is DD102, set as an exam question. |
| 7 | [Module_add](https://hdlbits.01xz.net/wiki/Module_add) | Two 16-bit adders chained into a 32-bit one. It's the same carry chain, two levels up. |
| 8 | [Adder100](https://hdlbits.01xz.net/wiki/Adder100) | A 100-bit adder. Expected solution length: around 1 line. Its hint says *"There are too many full adders to instantiate, but behavioural code works well here."* Read that after #5 and #7. |

If you enjoyed #5 and #7 and want a stretch, try [Bcdadd4](https://hdlbits.01xz.net/wiki/Bcdadd4),
which uses four instances of a provided BCD adder, with the same ripple structure and different
arithmetic. The site calls its language Verilog, but everything DD102 teaches is within what it
accepts.

## Check yourself

1. Your simulation passes but no `.vcd` file appears. What is missing from the testbench?
2. GTKWave opens with an empty black pane. Is the simulation broken?
3. A bus reads `xx` in red at t = 0 and a real value afterwards. Is that a bug? What if it were
   still red after the first vector?
4. EDA Playground prints `sorry:` on a file that passes on your workbench. What do you check
   first?

Next on the [Course path](../index.md#course-path): do
[Lab 03: The lazy testbench](../labs/lab-03-the-lazy-testbench-overview.md).
