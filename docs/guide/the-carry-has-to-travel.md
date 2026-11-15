# Carry delay

[`assign` and `always_comb`](../guide/assign-and-always-comb.md) said everything happens at once. So
why would a wider adder be any slower than a narrow one?

That page was about order in your source file: reversing five `assign` lines changes nothing,
because a wire has no "before". That part is true, and the backwards file proved it
(`PASS - the lines in reverse order, all 8 rows still match.`). What isn't true is that the answer
appears the instant the inputs do. Gates take time, and in the adder you built, the time they take
adds up in a line.

Every number on this page came from `yosys synth_ice40` and `nextpnr-ice40` on the workbench
image, run on the parameterised adder
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv).
You reproduce them in [Lab 05, Parts 3 and 5](../labs/lab-05-onto-the-fpga-overview.md).

## The carry chain

Look at what adder 3 needs before it can be right. `sum[3]` is `a[3] ^ b[3] ^ c[3]`, so it can't
settle until `c[3]` has settled. `c[3]` comes out of adder 2, which can't settle until `c[2]` has,
and so on down to `c[0]`, which is `cin` and is the only carry available immediately.

```
cin ──► fa0 ──c[1]──► fa1 ──c[2]──► fa2 ──c[3]──► fa3 ──► cout
```

Four boxes, and the carry has to walk through all of them in order. Nothing is waiting for a clock
and nothing is taking turns: all four adders compute continuously. But three of them are computing
from a carry that is still wrong, and they keep doing so until the change reaches them.

### Animation

The video is 3 min 12 s, silent and captioned; the captions are the narration. It shows four full
adders adding `1111 + 0001`, with the carry walking the line one stage at a time and the sum bits
correcting themselves behind it.

<video controls loop muted playsinline preload="none"
       poster="../assets/img/carry-travels.poster.png"
       style="width:100%;max-width:820px;border-radius:8px">
  <source src="../assets/img/carry-travels.web.mp4" type="video/mp4">
</video>

Watch the readout under the adders, not the bits. For the first quarter of a nanosecond the
circuit reports that fifteen plus one is fourteen. Then twelve, then eight, then zero, and only
then sixteen. Nothing is broken in any of those frames; three of the four adders are adding a carry
that hasn't arrived yet.

The nanoseconds in the video are ASIC numbers, not the FPGA numbers on this page. The animation
measures this same `ripple.sv` mapped to SKY130 standard cells, where one extra bit costs 0.392 ns.
On an iCE40 UP5K, below, one extra bit costs 0.74 ns. Neither is wrong. The shape is the same and
the size isn't, which is the point of the rest of this page.

That is what combinational delay means. The circuit is always running; it is settling, and the
answer is only trustworthy once it has stopped changing. This is the mechanism
[Why only two values?](https://uoftasic.com/dd101/#/guide/why-two-values) described from the other
end: every gate re-decides and redraws its output at full strength, and redrawing takes time.

## Three widths on a real part

An 8-bit ripple adder on an iCE40 UP5K has a longest path of 35.50 ns. A 12-bit one has half again
as many adders, so most people expect half again as much delay, about 65 ns.

Here are three widths of the same file, synthesized and placed with no constraints. `src/ripple.sv`
is the parameterised adder from Lab 04; a four-line wrapper such as `src/top8.sv` fixes its width,
because nextpnr places pins and pins need a fixed width. nextpnr ends each run with a critical path
report that splits the longest path into logic and routing. The total is nextpnr's own
end-to-end figure, so at 12 bits it is 38.99 ns rather than the 39.00 you get by adding the rounded
columns:

| Width | `SB_LUT4` | Logic cells | Pins | Logic | Routing | Total |
|---|---|---|---|---|---|---|
| 4 bits | 9 | 11 / 5280 | 14 / 39 | 2.98 ns | 23.24 ns | 26.22 ns |
| 8 bits | 18 | 20 / 5280 | 26 / 39 | 5.24 ns | 30.26 ns | 35.50 ns |
| 12 bits | 28 | 30 / 5280 | 38 / 39 | 8.20 ns | 30.80 ns | 38.99 ns |

38.99 ns, not 65. The prediction was too slow, and the reason matters more than the number.

## Logic delay and routing delay

The logic column is the carry: 2.98, 5.24, 8.20. Four more bits cost $8.20 - 5.24 = 2.96$ ns, and
$2.96 / 4 = 0.74$ ns per bit. That is one full adder's worth of delay per extra adder, as the queue
picture says. This is the column the prediction got right.

The routing column isn't the carry at all: 23.24, 30.26, 30.80. It is the time signals spend
travelling along metal between the lookup tables, and it grew less than proportionally from 8 to
12 bits because the placer had a different problem to solve, not because your adder got better.

Look at the sizes, too. On this part routing is 89 % of the 4-bit delay ($23.24/26.22$) and still
79 % at 12 bits. The wires cost four to eight times what the gates cost.

"How many gates deep is it?" is a poor predictor of speed on an FPGA. Count the gates to
understand the shape of the delay, and read the tool's report to learn its size. Anyone who quotes
you an FPGA speed from a gate count alone has guessed.

## Sixteen bits: the pin limit

At sixteen bits the design runs out of pins before anything else:

```
       37   SB_LUT4
Info: 	         ICESTORM_LC:      39/   5280     0%
Info: 	               SB_IO:      50/     39   128%
ERROR: Unable to find a placement location for cell 'cout$sb_io'
1 warning, 1 error
```

That isn't a timing failure; it is a pin failure. A 16-bit adder needs 16 + 16 + 1 inputs and
16 + 1 outputs, which is 50 pins, and the sg48 package has 39. At 12 bits you were already at 38
of 39. You are using 39 of 5,280 logic cells, under one percent of the chip, and the design
doesn't fit. On a small FPGA you run out of pins long before you run out of logic, which is why
real designs send numbers in over a few wires and reassemble them inside rather than giving every
bit its own pin.

Lab 05 has a larger version of the same refusal: `src/toobig.sv`, a 16×16 multiplier, needs 64
pins. Reading a tool refuse for a legitimate reason is a skill, and the cheapest time to practise
it is when you caused it on purpose.

## Faster adders

You won't build one in this course, but you should know the shape of the answer. The ripple adder
is the slowest correct adder. It is also the smallest and the easiest to understand, which is why
everybody builds it first. Every faster adder buys speed by computing carries ahead of the sum
instead of waiting for them to walk. A carry-lookahead adder works out "will this column carry?"
from the inputs directly, in parallel, and pays for it in gates. That trade, area against delay on
the same function, is most of what a digital designer decides, and DD103 is where you start
pricing it in square micrometres.

## Common misreadings

"So `assign` really is sequential." No. Reordering your source still changes nothing. Source
order and signal arrival time are different things that both sound like "order". The tool reads
your file in any order and builds the same gates; the signals then take as long as they take.

"26.22 ns sounds slow." It is a 4-bit adder with every bit brought out to a physical pin on a
low-power FPGA, placed with no timing constraint. It says nothing about how fast adders can be,
only about this part, this package and a placer that was told nothing about what you wanted.
Lab 05 shows how much of it is wire.

"The two numbers should agree." They won't. Lab 05 runs a second timing tool, `icetime`, over the
same placed design and gets a different total, and neither tool is lying. Static timing tools use
different delay models over the same silicon. Don't average them.

## Check yourself

1. Why does `sum[3]` of a ripple adder settle last?
2. From the table, how much logic delay does each extra bit add on the UP5K, and how much of the
   4-bit total is routing?
3. Why can't a 16-bit adder with every bit on its own pin be placed on the sg48 package, when it
   uses under one percent of the logic cells?

Next: [Inside an FPGA](../guide/the-chip-is-already-there.md).
