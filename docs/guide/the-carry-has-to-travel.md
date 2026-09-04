# The carry has to travel

**Question this page answers:** *You told me `assign` means everything happens at once. So why
would a wider adder be any slower than a narrow one?*

Because "at once" was a lie of convenience, and this is the page where you get the truth.

It was a *useful* lie. [Everything happens at once](guide/assign-and-always-comb.md) was about
**order in your source file** — that reversing five `assign` lines changes nothing, because
there is no "before" in a wire. That part is completely true, and you proved it:

```
PASS - the lines in reverse order, all 8 rows still match.
```

What is not true is that the answer appears the instant the inputs do. Gates take time. And in
the adder you just built, the time they take **adds up in a line**.

Every number on this page came from `yosys synth_ice40` and `nextpnr-ice40` on the workbench
image, on the parameterised adder shipped as
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv).

## Why your adder is a queue

Look at what adder 3 needs before it can be right.

`sum[3]` is `a[3] ^ b[3] ^ c[3]`. It cannot settle until `c[3]` has settled. `c[3]` comes out of
adder 2, which cannot settle until `c[2]` has. And so on, down to `c[0]`, which is `cin` and is
the only one available immediately.

```
cin ──► fa0 ──c[1]──► fa1 ──c[2]──► fa2 ──c[3]──► fa3 ──► cout
```

Four boxes, and the carry has to **walk through all of them, in order**. Nothing is waiting for
a clock and nothing is taking turns — all four adders are computing continuously, all the time.
But three of them are computing from a carry that is still wrong, and they keep doing so until
the wave arrives.

### Watch it happen

**3 min 12 s**, silent, captioned — the captions are the narration, so read rather than listen.
Four full adders, `1111 + 0001`, and the carry walking the line one stage at a time while the
sum bits correct themselves behind it.

<video controls loop muted playsinline preload="none"
       poster="assets/img/carry-travels.poster.png"
       style="width:100%;max-width:820px;border-radius:8px">
  <source src="assets/img/carry-travels.web.mp4" type="video/mp4">
</video>

**Watch the readout under the adders, not the bits.** For the first quarter of a nanosecond
this circuit reports that fifteen plus one is **fourteen**. Then twelve. Then eight. Then zero.
Only then sixteen. Nothing is broken in any of those frames — three of the four adders are
simply adding a carry that has not arrived yet, exactly as described above.

**The nanoseconds in it are ASIC numbers, not the FPGA numbers on this page.** The animation
measures this same `ripple.sv` mapped to SKY130 standard cells, where one extra bit costs
**0.392 ns**. Below, you measure it on an iCE40 UP5K and get **0.74 ns** per bit. Neither is
wrong. The *shape* is identical and the *size* is not, which is the point the rest of this page
is about to make.

That is what "combinational delay" means. Not *"the circuit runs"* — the circuit is always
running. **The circuit is settling**, and the answer is only trustworthy once it has stopped
changing.

This is the mechanism [Why only two values?](https://uoftasic.com/dd101/#/guide/why-two-values)
described from the other end: every gate re-decides and redraws its output at full strength, and
redrawing takes time.

## Commit to a number

An 8-bit ripple adder on an iCE40 UP5K has a longest path of **35.50 ns**. That is measured,
and you will see the measurement in a moment.

**Now write down what you think a 12-bit one is**, before you scroll. Half again as many
adders, so half again as much delay — most people write down something near 65 ns.

## The measurement

Three widths of the same file, synthesized and placed with no constraints. It ships as a
runnable package — `make` alone, no environment setup, ending in five verdicts:

```bash
cd labs/guide-examples-carry
make
```

Each width is two commands, and this is the 8-bit one. `src/ripple.sv` is the parameterised
adder from Lab 04, unchanged; `src/top8.sv` is a four-line wrapper that fixes its width,
because `nextpnr` places **pins** and pins need a width:

```bash
yosys -p "read_verilog -sv src/top8.sv src/ripple.sv src/full_adder.sv; \
          synth_ice40 -top top -json results/r8.json"
nextpnr-ice40 --up5k --package sg48 --json results/r8.json --asc results/r8.asc
```

> **This is an excerpt of what `make widths` runs** — the complete package is
> [`labs/guide-examples-carry/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-carry),
> and every number below comes out of it. Nothing on this page needs saving to disk.

`nextpnr` ends its run with a critical path report. The last line of it is the summary:

| width | `SB_LUT4` | logic cells | pins | **logic** | **routing** | **total** |
|---|---|---|---|---|---|---|
| 4 bits | 8 | 10 / 5280 | 14 / 39 | 2.98 ns | 23.24 ns | **26.22 ns** |
| 8 bits | 16 | 18 / 5280 | 26 / 39 | 5.24 ns | 30.26 ns | **35.50 ns** |
| 12 bits | 24 | 26 / 5280 | 38 / 39 | 8.20 ns | 30.80 ns | **39.00 ns** |

**39.00 ns, not 65.** Your prediction was too slow, and the gap is worth more than the number.

## Where the prediction went wrong

Split the two columns and they behave completely differently.

**The logic column is the carry.** 2.98 → 5.24 → 8.20. Four more bits costs
$8.20 - 5.24 = 2.96$ ns, and $2.96 / 4 = \mathbf{0.74}$ **ns per bit**. That is one full
adder's worth of delay, per extra adder, exactly as the queue picture says. This column is the
one you predicted correctly.

**The routing column is not the carry at all.** 23.24 → 30.26 → 30.80. It is the time signals
spend travelling down metal between the lookup tables, and it grew by *less* than proportionally
from 8 to 12 bits because the placer had a different problem to solve, not because your adder
got better.

And look at the sizes. On this part, **routing is 89 % of the 4-bit delay** ($23.24/26.22$) and
still **79 % at 12 bits**. The wires cost four to eight times what the gates cost.

> **The reflex, and it is one line:** *"how many gates deep is it?"* is a bad predictor of speed
> on an FPGA. Count the gates to understand the **shape** of the delay; read the tool's report to
> learn the **size** of it. Anyone who quotes you an FPGA speed from a gate count alone has
> guessed.

## The wall you hit before the speed wall

Try sixteen bits — `make wall` in the same package — and something else happens first:

```
       37   SB_LUT4
nextpnr exit status 255   (255. this one does tell you.)
Info: 	         ICESTORM_LC:      34/   5280     0%
Info: 	               SB_IO:      50/     39   128%
ERROR: Unable to find a placement location for cell 'cout$sb_io'
1 warning, 1 error
```

Not a timing failure — a **pin** failure. A 16-bit adder needs 16 + 16 + 1 inputs and 16 + 1
outputs, which is **50** pins, and the sg48 package has **39**. Look back at the table: at 12
bits you were already at 38 of 39.

You have used **34 of 5,280 logic cells**, well under one percent of the chip, and you cannot
fit the design. **On a small FPGA you run out of pins long before you run out of logic**, which
is why real designs send numbers in over a few wires and reassemble them inside rather than
giving every bit its own leg.

> A larger version of this refusal is one of the shipped experiments in
> [Lab 05](labs/lab-05-onto-the-fpga-overview.md): `make fits` runs `src/toobig.sv`, a 16×16 multiplier,
> and its verdict line reads
>
> ```
> PASS  toobig    toobig needs 64 pins, the package has 39, and nextpnr says so
> ```
>
> Reading a tool refuse for a legitimate reason is a skill, and the cheapest time to practise it
> is when you caused it on purpose.

## What you would do about it

Nothing, in this course — but you should know the shape of the answer, because "ripple adder" is
about to become a slightly rude term.

The ripple adder is the **slowest possible correct adder**. It is also the smallest and the
easiest to understand, which is why it is the one everybody builds first and why it is the one
you built. Every faster adder buys speed by computing carries *ahead* of the sum rather than
waiting for them to walk — a carry-lookahead adder works out "will this column carry?" from the
inputs directly, in parallel, and pays for it in gates.

That trade — **area against delay, on the same function** — is not a footnote. It is most of
what a digital designer decides, and DD103 is where you start pricing it in square micrometres.

## The part that trips people up

**"So `assign` really is sequential."** No. Reordering your source still changes nothing;
[the backwards file still passes all 8 rows](guide/assign-and-always-comb.md). Source order and
signal arrival time are unrelated things that both sound like "order". The tool reads your file
in any order it likes and builds the same gates; the *electrons* then take as long as they take.

**"26.22 ns sounds slow."** It is a 4-bit adder with every bit brought out to a physical pin on
a low-power FPGA, placed with no timing constraint at all. It is not a statement about how fast
adders can be. It is a statement about this part, this package, and a placer that was told
nothing about what you wanted. Lab 05 turns it into a frequency and shows you where that number
comes from.

**"The two numbers should agree."** They will not. Lab 05 runs a *second* timing tool over the
same placed design and gets a different total, and neither is lying. Static timing tools use
different delay models over the same silicon. Do not average them.

## What to remember

- Combinational logic **settles**; it does not compute instantly. The answer is only good once
  it has stopped moving.
- In a ripple adder the carry walks through every stage in order, so the **logic** delay grows
  linearly — measured here at **0.74 ns per bit** on an iCE40 UP5K.
- On an FPGA, **routing dominates**: 23.24 ns of wire against 2.98 ns of logic at four bits.
- Gate depth predicts the *shape* of the delay, never its *size*. Read the tool's report.
- Small FPGAs run out of **pins** first: 26 of 5,280 logic cells and 38 of 39 pins, at twelve
  bits.

Runnable package: [`labs/guide-examples-carry/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-carry)
— `make` alone, no setup, and it grades every number on this page.

Next: [The chip is already there](guide/the-chip-is-already-there.md), which explains what those
`SB_LUT4` actually are and why an FPGA can be reprogrammed in three seconds. Then
[Lab 05 — Onto the FPGA](labs/lab-05-onto-the-fpga-overview.md) puts your own `ripple4.sv` on a real part
and prints its critical path with your generate-block labels in the middle of it.
