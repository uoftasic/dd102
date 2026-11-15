# Carry delay

[`assign` and `always_comb`](../guide/assign-and-always-comb.md) said that everything happens at
once, so you may well wonder why a wider adder should be any slower than a narrow one.

That page was about the order of the lines in your source file. Reversing five `assign` lines
changes nothing, because a wire has no "before", and the backwards file proved it
(`PASS - the lines in reverse order, all 8 rows still match.`). It doesn't follow, though, that
the answer appears the instant the inputs do. Gates take time, and in the adder you built, the
time each one takes adds to the time of the one before it, all the way along a line.

Every number on this page came from `yosys synth_ice40` and `nextpnr-ice40` on the workbench
image, run on the parameterised adder
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv).
You'll reproduce them yourself in [Lab 05, Parts 3 and 5](../labs/lab-05-onto-the-fpga-overview.md).

## The carry chain

Look at what adder 3 needs before its output can be right. `sum[3]` is `a[3] ^ b[3] ^ c[3]`, so
it can't settle until `c[3]` has settled. `c[3]` comes out of adder 2, which can't settle until `c[2]` has,
and so on down to `c[0]`, which is `cin` and is the only carry available immediately.

```
cin ──► fa0 ──c[1]──► fa1 ──c[2]──► fa2 ──c[3]──► fa3 ──► cout
```

The carry has to pass through all four boxes, in order. That doesn't mean anything is waiting for
a clock or taking turns, because all four adders compute continuously. Three of them are simply
computing from a carry that is still wrong, and they keep doing so until the change reaches them.

### Animation

The video runs for 3 min 12 s and is silent, so the captions carry the narration. It shows four
full adders adding `1111 + 0001`, with the carry moving along the line one stage at a time and the
sum bits correcting themselves behind it.

<video controls loop muted playsinline preload="none"
       poster="../assets/img/carry-travels.poster.png"
       style="width:100%;max-width:820px;border-radius:8px">
  <source src="../assets/img/carry-travels.web.mp4" type="video/mp4">
</video>

Watch the readout under the adders rather than the individual bits. For the first quarter of a
nanosecond the circuit reports that fifteen plus one is fourteen, and after that it reports
twelve, then eight, then zero, before it finally settles on sixteen. Nothing is broken in any of
those frames. The totals are wrong because three of the four adders are still adding a carry that
hasn't arrived yet.

The times in the video are ASIC numbers, not the FPGA numbers used on the rest of this page. The
animation measures this same `ripple.sv` mapped to SKY130 standard cells, where one extra bit
costs 0.392 ns, while on the iCE40 UP5K below one extra bit costs 0.74 ns. Both figures are
correct for their own technology. The delay grows in the same way on both, but the size of each
step is different, and that difference is what the rest of this page is about.

What the animation shows is what combinational delay means. The circuit is always running, and
after its inputs change it spends a while settling, so you can trust the answer only once it has
stopped changing. [Why only two values?](https://uoftasic.com/dd101/guide/why-two-values.html)
described the same mechanism from the other end: every gate re-decides its output and redraws it
at full strength, and redrawing takes time.

## Three widths on a real part

An 8-bit ripple adder on an iCE40 UP5K has a longest path of 35.50 ns. A 12-bit one has half again
as many adders, so most people expect half again as much delay, about 65 ns.

Here are three widths of the same file, synthesized and placed with no constraints. `src/ripple.sv`
is the parameterised adder from Lab 04, and a four-line wrapper such as `src/top8.sv` fixes its
width. The wrapper is needed because nextpnr places pins, and it can only do that once the width
is fixed. nextpnr ends each run with a report on the critical path, which splits the longest path
into the time spent in logic and the time spent in routing. The Total column is nextpnr's own
end-to-end figure rather than the sum of the other two, so at 12 bits it reads 38.99 ns, not the
39.00 you'd get by adding the rounded columns:

| Width | `SB_LUT4` | Logic cells | Pins | Logic | Routing | Total |
|---|---|---|---|---|---|---|
| 4 bits | 9 | 11 / 5280 | 14 / 39 | 2.98 ns | 23.24 ns | 26.22 ns |
| 8 bits | 18 | 20 / 5280 | 26 / 39 | 5.24 ns | 30.26 ns | 35.50 ns |
| 12 bits | 28 | 30 / 5280 | 38 / 39 | 8.20 ns | 30.80 ns | 38.99 ns |

The 12-bit adder takes 38.99 ns, not 65, so the prediction made it much slower than it really is.
Why the prediction was wrong matters more than the number itself, and the next section explains it.

## Logic delay and routing delay

The Logic column is the carry: 2.98, 5.24 and 8.20 ns. Going from 8 to 12 bits costs
$8.20 - 5.24 = 2.96$ ns, and $2.96 / 4 = 0.74$ ns per bit. That is one full adder's worth of delay
for each extra adder, just as the carry chain above predicts, so this is the column the prediction
got right.

The Routing column (23.24, 30.26 and 30.80 ns) has nothing to do with the carry. It is the time
signals spend travelling along metal between the lookup tables. It grew much less than in
proportion from 8 to 12 bits, but that's because the placer had a different problem to solve,
not because your adder got any better.

The sizes are worth a look too. On this part, routing is 89 % of the 4-bit delay ($23.24/26.22$)
and still 79 % at 12 bits, so the wires cost four to eight times as much time as the gates do.

That's why "How many gates deep is it?" is a poor predictor of speed on an FPGA. Count the gates
to understand how the delay grows with width, and read the tool's report to learn how big it
actually is. Anyone who quotes you an FPGA speed from a gate count alone has guessed.

## Sixteen bits: the pin limit

At sixteen bits the design runs out of pins before it runs out of anything else, and placement
fails:

```
       37   SB_LUT4
Info: 	         ICESTORM_LC:      39/   5280     0%
Info: 	               SB_IO:      50/     39   128%
ERROR: Unable to find a placement location for cell 'cout$sb_io'
1 warning, 1 error
```

The design fails because it needs more pins than the package has, and timing never comes into it.
A 16-bit adder needs 16 + 16 + 1 inputs and 16 + 1 outputs, which is 50 pins, and the sg48 package
has 39. At 12 bits you were already using 38 of the 39. The design doesn't fit even though it uses
only 39 of the 5,280 logic cells, under one percent of the chip. On a small FPGA you run out of
pins long before you run out of logic, which is why real designs send numbers in over a few wires
and reassemble them inside rather than giving every bit its own pin.

Lab 05 has a larger version of the same refusal: `src/toobig.sv`, a 16×16 multiplier, which needs
64 pins. Recognising that a tool has refused for a legitimate reason is a skill, and the cheapest
time to practise it is on an error you caused on purpose.

## Faster adders

You won't build a faster adder in this course, but you should know roughly how they work. The
ripple adder is the slowest correct adder. It is also the smallest and the easiest to understand,
which is why everybody builds it first. Every faster adder gains its speed by computing the
carries ahead of the sum instead of waiting for them to pass along the chain. A carry-lookahead
adder, for example, works out "will this column carry?" directly from the inputs, in parallel, and
pays for that in extra gates. Trading area against delay for the same function is most of what a
digital designer decides, and DD103 is where you start pricing that trade in square micrometres.

## Common misreadings

"So `assign` really is sequential." It isn't, and reordering your source still changes nothing.
The order of lines in your source and the time at which signals arrive are different things that
both get called "order". The tool reads your file in any order and builds the same gates, and
once they're built, the signals take as long as they take to get through them.

"26.22 ns sounds slow." That's the figure for a 4-bit adder on a low-power FPGA, with every bit
brought out to a physical pin and placed with no timing constraint. It tells you nothing about
how fast adders can be, only about this part, this package and a placer that was told nothing
about what you wanted. Lab 05 shows how much of it is wire.

"The two numbers should agree." They won't. Lab 05 runs a second timing tool, `icetime`, over the
same placed design and gets a different total, and neither tool is lying: different static timing
tools use different delay models of the same silicon. Don't average them.

## Check yourself

1. Why does `sum[3]` of a ripple adder settle last?
2. From the table, how much logic delay does each extra bit add on the UP5K, and how much of the
   4-bit total is routing?
3. Why can't a 16-bit adder with every bit on its own pin be placed on the sg48 package, when it
   uses under one percent of the logic cells?

Next: [Inside an FPGA](../guide/the-chip-is-already-there.md).
