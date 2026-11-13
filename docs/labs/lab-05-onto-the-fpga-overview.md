# Lab 05: Onto the FPGA

You take `ripple4.sv` from Lab 04 (the package ships its own copy, with `full_adder.sv`) and
produce a bitstream you could load into a real Lattice iCE40 UP5K, where it would add numbers.
Along the way you measure what a lookup table costs, watch the carry delay grow with width,
predict the size of the bitstream, run out of pins, and send the same file to an ASIC library for
comparison. At the end you send your own rewritten Lab 04 file through the same flow.

Packages: [`labs/guide-examples/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples)
for Part 1, [`labs/guide-examples-carry/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples-carry)
for Parts 3 and 5, and [`labs/lab-05-onto-the-fpga/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-05-onto-the-fpga)
for the rest.

You don't need a board, and this course doesn't assume you own one. Everything here is synthesis
and place-and-route: real tools, real timing, a real bitstream. If you have an iCEBreaker (a
development board with an iCE40 UP5K on it), `make flash` exists and is optional (see Going
further); nothing in this lab or in DD103 depends on it.

## Before you start

- Finish [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md), including Part 7: your
  `src/ripple4.sv` there has a loop you rewrote and proved equal to the hand-typed version.
- Read [Carry delay](guide/the-carry-has-to-travel.md) and
  [Inside an FPGA](guide/the-chip-is-already-there.md).
- In a terminal on the workbench desktop:

  ```bash
  . /foss/designs/common/.designinit
  mod dd102
  yosys -V                    # expect: Yosys 0.68
  nextpnr-ice40 --version     # expect: ... (Version nextpnr-0.11.1-9-gb17408e2)
  ```

Time: about 2 hours. The Going further steps at the end are optional and not counted.

The three programs in this lab, and the question each answers:

| Tool | Question it answers | What it hands you |
|---|---|---|
| `yosys -p "synth_ice40"` | Which of the chip's cells do I need? | a netlist of `SB_LUT4`s |
| `nextpnr-ice40` | Which physical cells, and how do the wires get between them? | an `.asc`: every cell and every switch, as text |
| `icepack` | What is that as bytes? | a `.bin`: the bitstream |

None of these tools builds anything. The chip already exists, and every one of its 5,280 logic
cells is on the die whether your design uses it or not. You are producing a settings file for a
machine that already exists.

## Part 1: What one lookup table costs

Does a function's cost on an FPGA follow how complicated it is, or how many inputs it has?

1. Synthesize three unrelated four-input functions and one five-input AND for the iCE40:

   ```bash
   cd labs/guide-examples
   make luts
   ```

   The three four-input functions are one line each:
   `a & b & c & d` ([`src/lut_simple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_simple.sv)),
   `a ^ b ^ c ^ d` ([`src/lut_parity.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_parity.sv))
   and `(a ^ b) ? (c & ~d) : (~c | d)` ([`src/lut_weird.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_weird.sv)).
   [`src/lut_five.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/lut_five.sv)
   is `a & b & c & d & e`.

   You should see:

   ```
     lut_simple   1 SB_LUT4
     lut_parity   1 SB_LUT4
     lut_weird    1 SB_LUT4
     lut_five     2 SB_LUT4
   ```

   then four `PASS` lines from the checker, and:

   ```
   PASS - three different 4-input functions cost ONE lookup table each.
          One extra input cost a second one, on the simplest function here.
          On an FPGA the price is the number of inputs, not the difficulty.
   ```

2. Do one by hand, with the same command shape as Lab 04:

   ```bash
   yosys -p "read_verilog -sv src/lut_simple.sv; synth_ice40 -top lut_simple; stat"
   ```

   The `stat` block near the end of what it prints shows `1   SB_LUT4`.

## Part 2: Three commands to a bitstream

What does each tool hand you, and where does the time go on your adder's longest path?

1. Go to the lab package and run the flow on your adder:

   ```bash
   cd ../lab-05-onto-the-fpga
   make fpga
   ```

   `make fpga` runs the three commands in about 0.8 seconds.

First Yosys, with `synth_ice40` instead of `synth`. You should see:

```
yosys -p "read_verilog -sv src/ripple4.sv src/full_adder.sv; synth_ice40 -top ripple4 -json results/r4.json" > results/ys.log 2>&1
    yosys wrote 928 lines to results/ys.log. The answer is one of them:
        9   SB_LUT4
        9   SB_LUT4
```

Yosys writes over 900 lines, which is why `make` sends them to a file; the answer is the
two-word line. It appears twice because Yosys prints statistics for the module and then for the
whole hierarchy. In `results/ys.log` you'll also find 4 `$scopeinfo` next to the nine LUTs.
Those are name tags, one per `full_adder` instance, not hardware; the hand-typed version from
Lab 03 produces the same four.

Then `nextpnr-ice40` decides where everything goes:

```
nextpnr-ice40 --up5k --package sg48 --json results/r4.json --asc results/r4.asc --write results/post.json --freq 50 > results/pnr.log 2>&1
Warning: No PCF file specified; IO pins will be placed automatically
Info: 	         ICESTORM_LC:      11/   5280     0%
Info: 	        ICESTORM_RAM:       0/     30     0%
Info: 	               SB_IO:      14/     39    35%
Info: 	               SB_GB:       0/      8     0%
```

`ICESTORM_LC` counts logic cells and `SB_IO` counts I/O pins. `make` shows four resource rows;
the full table in `results/pnr.log` has fifteen, and you use two of them. The other thirteen
(RAMs, a PLL, an I2C block, an LED driver, two oscillators and more) are on the die whether you
use them or not. Two lines in the log are expected:

- `Warning: No PCF file specified` is the only warning this run produces, and the run ends
  `1 warning, 0 errors`. You didn't say which physical pins your signals use, so nextpnr picked.
  Part 6 is where you say.
- `Info: No Fmax available; no interior timing paths found in design.` appears twice. Your adder
  has no flip-flops, so there is no clock, so the `--freq 50` had nothing to check. Part 4 has a
  design where it means something.

Yosys said nine LUTs and nextpnr placed eleven logic cells. The usual guess is that nextpnr's
packer, the step that fits LUTs, carry logic and flip-flops into logic cells, merged something,
but the packer's own report in `results/pnr.log` says `9 LCs used as LUT4 only` and zero for
every other category. So `make fpga` asks the placed netlist and lists all eleven:

```
--- yosys said 9 SB_LUT4 and nextpnr says 11 cells. Here are all eleven. ---
    cin_SB_LUT4_I1_LC
    cin_SB_LUT4_I1_O_SB_LUT4_O_LC
    cout_SB_LUT4_O_I3_SB_LUT4_O_1_LC
    cout_SB_LUT4_O_I3_SB_LUT4_O_LC
    cout_SB_LUT4_O_LC
    slice[0].fa.sum_SB_LUT4_O_LC
    slice[1].fa.sum_SB_LUT4_O_LC
    slice[2].fa.sum_SB_LUT4_O_LC
    slice[3].fa.sum_SB_LUT4_O_LC
    $PACKER_GND      <- nobody wrote this one
    $PACKER_VCC      <- nobody wrote this one

PASS  lcs       11 logic cells placed: 9 from your RTL + 2 the packer added
```

2. $9 + 2 = 11$. Why does the packer add `$PACKER_GND` and `$PACKER_VCC`?

   <details>
   <summary>Answer</summary>

   The chip has no wire that is permanently 0 and none that is permanently 1, so when the design
   needs a constant, the packer spends a general-purpose logic cell to make one.

   </details>

Look at four of the other names too: `slice[0]` to `slice[3]`, the label written after
`begin :` in Lab 04, still attached to the logic three tools later.

`make fpga` also prints where the time goes on the longest path:

```
Info: 2.98 ns logic, 23.24 ns routing
```

In `results/pnr.log` the critical path report above that line runs from the input pin `cin`
through `cin_SB_LUT4_I1_LC`, `cout_SB_LUT4_O_I3_SB_LUT4_O_1_LC` and `cout_SB_LUT4_O_LC` to the
output pin `cout`, 26.22 ns in total. That is your carry, walking from the bottom input to the
top output. [Carry delay](guide/the-carry-has-to-travel.md) said it would take time; this is the
number on a real part.

Finally `icepack`, the shortest step in the course:

```
icepack results/r4.asc results/r4.bin
  results/r4.asc 708412 bytes
  results/r4.bin 104090 bytes
  results/r4.json 336739 bytes
```

You have a bitstream: `results/r4.bin`, 104,090 bytes. Load it into an iCE40 UP5K and the part
adds four-bit numbers. `r4.json` will differ from yours by a few hundred bytes, because Yosys
records the source path of every wire and that depends on where you cloned the repo. The checker
only asserts the size of `r4.bin`.

## Part 3: Wider adders

How do the logic delay, the routing delay and the pin count grow as the adder gets wider?

[Carry delay](guide/the-carry-has-to-travel.md) printed a table of the same adder at three
widths. Here you produce it, in the `guide-examples-carry` package. Its `src/ripple.sv` is
Lab 04's parameterised adder, unchanged; `src/top8.sv` and its siblings are short wrappers that
fix the width, because nextpnr places pins and pins need a fixed width.

1. Run the three widths:

   ```bash
   cd ../guide-examples-carry
   make widths
   ```

   Each width is two commands. The 8-bit one is:

   ```bash
   yosys -p "read_verilog -sv src/top8.sv src/ripple.sv src/full_adder.sv; \
             synth_ice40 -top top -json results/r8.json"
   nextpnr-ice40 --up5k --package sg48 --json results/r8.json --asc results/r8.asc
   ```

You should see:

```
   4 bits ->  9 SB_LUT4   ICESTORM_LC: 11/ 5280  SB_IO: 14/ 39      2.98 ns logic, 23.24 ns routing
   8 bits -> 18 SB_LUT4   ICESTORM_LC: 20/ 5280  SB_IO: 26/ 39      5.24 ns logic, 30.26 ns routing
  12 bits -> 28 SB_LUT4   ICESTORM_LC: 30/ 5280  SB_IO: 38/ 39      8.20 ns logic, 30.80 ns routing

--- and the longest path, end to end, from nextpnr's own report ---
   4 bits   total 26.22 ns
   8 bits   total 35.50 ns
  12 bits   total 38.99 ns
```

2. Check the guide's arithmetic against your numbers. How much does the logic column grow per
   extra bit from 8 to 12 bits, and what does one bit's worth of that delay correspond to? How
   does the routing column behave?

   <details>
   <summary>Answer</summary>

   The logic column grows by $8.20 - 5.24 = 2.96$ ns over four bits, 0.74 ns per bit: one full
   adder's worth of delay per extra adder. The routing column barely moves from 8 to 12 bits.
   And at four bits, routing is 23.24 of the 26.22 ns.

   </details>

At twelve bits you are already using 38 of the 39 pins.

## Part 4: Bitstream sizes

Does a bigger design make a bigger bitstream?

`make sizes` builds two more designs:

- [`src/one_gate.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/src/one_gate.sv)
  is one AND gate: two inputs, one output.
- [`src/big.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/src/big.sv)
  is a 4000-stage shift register: 4000 flip-flops and three pins (`clk`, `d` and `q`).

1. Your adder's bitstream was 104,090 bytes. Write down how big you think each of these two will
   be.
2. Run:

   ```bash
   cd ../lab-05-onto-the-fpga
   make sizes
   ```

You should see:

```
  one_gate  Info: ICESTORM_LC: 3/ 5280 0%
  big       Info: ICESTORM_LC: 4001/ 5280 75%

  bitstream            bytes
  one_gate.bin         104090
  r4.bin               104090
  big.bin              104090

PASS  sizes     3 designs, all 104090 bytes
```

Identical, to the byte. (`make` with no target also checks the pinned build from Part 6, so its
`sizes` line says 4 designs.) Most people reason proportionally: the AND gate perhaps a hundredth
of the adder, the shift register hundreds of times bigger, something like 1 KB and 20 MB.

3. A design using 3 logic cells and one using 4001, a factor of 1,334, produce files of the same
   length. Why?

   <details>
   <summary>Answer</summary>

   The bitstream isn't a description of your design. It is the setting of every configuration
   bit on the die: all 5,280 logic cells, all 30 block RAMs, the PLL, the I2C blocks and the
   routing switches between them, whether you touched them or not. `one_gate` configures 5,277
   logic cells to do nothing; your adder configures 5,269. Both take the same number of bytes to
   write down, because "do nothing" is a setting like any other.

   </details>

Here is how many bytes actually differ:

```
--- so how many of those 104090 bytes actually differ? ---
  one_gate.bin vs r4.bin : 201 bytes differ
  r4.bin       vs big.bin: 20453 bytes differ
```

201 bytes are the whole difference between "one AND gate" and "a four-bit adder" in a
104,090-byte file, about 0.2 % of it. The rest is the two designs agreeing about the cells
neither uses. A bitstream's size tells you which chip, never which design. If you want to know
how big a design is, read the utilisation report.

`big.sv` has a clock, so nextpnr checks its timing and reports a maximum clock frequency of
202.92 MHz. (nextpnr prints a pre-routing estimate of 180.67 MHz first; the second figure, after
routing, is the one this lab quotes.)

## Part 5: Running out of chip

What runs out first on a small FPGA?

An ASIC design can't run out of area; it just gets bigger, and bigger costs money. An FPGA design
can run out of chip, and what runs out is rarely what you expect.

1. Before you run the next step, work out how many I/O pins a 16-bit ripple adder needs: its
   inputs are `a`, `b` and `cin`, and its outputs `sum` and `cout`. The sg48 package has 39.

   <details>
   <summary>Answer</summary>

   16 + 16 + 1 inputs and 16 + 1 outputs: 50 pins. In general an $N$-bit ripple adder needs
   $3N + 2$, which is why 12 bits used 38 of the 39 in Part 3.

   </details>

2. Try the ripple adder at 16 bits:

   ```bash
   cd ../guide-examples-carry
   make wall
   ```

   You should see:

   ```
          37   SB_LUT4
   nextpnr exit status 125   (255. this one does tell you.)
   Info: 	         ICESTORM_LC:      39/   5280     0%
   Info: 	               SB_IO:      50/     39   128%
   ERROR: Unable to find a placement location for cell 'cout$sb_io'
   1 warning, 1 error
   ```

   It isn't a timing failure; it's a pin failure. You are using 39 of 5,280 logic cells, under
   one percent of the chip, and the design doesn't fit. (The exit status is 125; the
   "(255 ...)" in the same line is fixed text in the Makefile and is out of date. The point it
   makes stands: this time the tool's exit status does tell you something went wrong.)

3. Try a 16 × 16 multiplier,
   [`src/toobig.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/src/toobig.sv),
   which is one `assign`: `p = a * b`. Write down how many pins it needs first.

   ```bash
   cd ../lab-05-onto-the-fpga
   make fits
   ```

   You should see:

   ```
   nextpnr exit status 125
   Info: 	         ICESTORM_LC:     685/   5280    12%
   Info: 	               SB_IO:      64/     39   164%
   ERROR: Unable to find a placement location for cell 'p[29]$sb_io'
   1 warning, 1 error
       The error names ONE pin. The line above it names the real problem.
   ```

The logic fits easily: 685 of 5,280 cells, 12 %. The pins don't: two 16-bit inputs and a 32-bit
output are 64 signals, and the package has 39 usable I/O, `164%`. On a small FPGA you run out of
pins long before you run out of logic, which is why real designs send numbers in over a few wires
and reassemble them inside rather than giving every bit its own pin.

Look at how the tool tells you. The `ERROR` line names one pin, `p[29]`, which isn't special and
isn't where your problem is. The utilisation table just above it is the real message. When a
place-and-route tool fails, read upward from the error: `164%` is the bug, and the `ERROR:` line
is where the tool happened to give up.

## Part 6: Saying which pin is which

Does telling the tool which pin is which change the timing?

The warning from Part 2 has been waiting. A `.pcf` file says which physical pin each signal uses.
[`constraints/r4.pcf`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/constraints/r4.pcf)
is fourteen lines of them:

```
set_io a[0]    2
set_io a[1]    3
...
set_io cout   18
```

Those fourteen pin numbers are valid on a UP5K in the SG48 package and aren't wired to anything
in particular on any board. The file shows the mechanism; it won't light an LED.

1. Your logic won't change, only where its signals enter and leave the chip. Write down whether
   you expect the longest path to get shorter, longer or stay the same.
2. Run:

   ```bash
   make pins
   ```

You should see:

```
Info: Placed 14 cells based on constraints.
Info: 	         ICESTORM_LC:      11/   5280     0%
Info: 	               SB_IO:      14/     39    35%
Info: 2.95 ns logic, 11.16 ns routing
  bitstream: 104090 bytes   (319 bytes differ from the unpinned one)
```

`make pins` writes `results/r4_pinned.bin` and its log, `results/pnr_pinned.log`, and leaves the
unpinned `results/r4.bin` from Part 2 alone. In `results/pnr.log` from Part 2 the same
line reads `Placed 0 cells based on constraints.` Same logic, same eleven cells, same 104,090
bytes; 319 of those bytes moved.

3. In Part 2 the longest path was 2.98 ns of logic and 23.24 ns of routing; here it is 2.95 and
   11.16, 14.11 ns in total. Nothing about your design changed. Where did 12.1 ns go?

   <details>
   <summary>Answer</summary>

   You told the tool where the signals enter and leave the chip, the placer put the logic near
   those pins, and the wires got 12.1 ns shorter.

   </details>

On an FPGA most of your delay is wire: 23.24 against 2.98 is nearly eight to one. That ratio is
why "how many gates deep is it?" predicts FPGA speed poorly, and why DD103 cares so much about
where things physically sit.

## Part 7: The same file on SKY130

What does the same RTL become when the target is a standard-cell library instead of an FPGA?

1. Run:

   ```bash
   make contrast
   ```

   [`scripts/asic.ys`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/scripts/asic.ys)
   reads the same two files, `src/ripple4.sv` and `src/full_adder.sv`, and maps them onto the
   SKY130 standard-cell library instead of an FPGA.

You should see:

```
        4   40.038   sky130_fd_sc_hd__maj3_1
        8   70.067   sky130_fd_sc_hd__xnor2_1
   Area for cell type $scopeinfo is unknown!
   Chip area for module '\ripple4': 110.105600

  FPGA:  9 SB_LUT4, 11 of 5280 cells used, a 104090-byte bitstream.
  ASIC:  12 named cells, 110.1056 um^2, and no chip yet. That is DD103.
```

`Area for cell type $scopeinfo is unknown!` is about the name tags again. They aren't cells and
have no area, so this isn't a problem.

|  | FPGA (iCE40 UP5K) | ASIC (SKY130) |
|---|---|---|
| your logic becomes | 9 × `SB_LUT4` | 4 × `maj3_1` + 8 × `xnor2_1` |
| the report says | 11 of 5,280 cells used | 110.1056 µm² |
| you hand over | a 104,090-byte bitstream | a GDSII, the file a chip is manufactured from |
| how big is that file? | the same for every design | grows with your design |
| to change it | reload it, seconds | manufacture it again, months |

An `SB_LUT4` is sixteen bits of memory and a multiplexer: it could have been any function of
four inputs, and you chose which. A `sky130_fd_sc_hd__maj3_1` is fourteen transistors arranged to
compute "at least two of these three are high", and it will never do anything else, because that
arrangement is the thing being built. The bitstream describes a chip that exists, including
everything on it you didn't use, so it has a fixed size. A GDSII describes only what you built,
because nothing exists yet. DD103 takes the same `ripple4.sv` and builds the second column.

## Part 8: Your own adder through the flow

Does the loop you rewrote in Lab 04 change anything on the FPGA?

1. Keep the bitstream of this package's copy (`results/r4.bin`, the unpinned build from
   Part 2), then copy your Lab 04 file over the package's `src/ripple4.sv`:

   ```bash
   cp results/r4.bin results/r4_shipped.bin
   cp ../lab-04-four-adders-in-a-row/src/ripple4.sv src/ripple4.sv
   ```

   `git checkout -- src/ripple4.sv` puts the shipped copy back if you ever want it.

2. Write down which of these you expect to change: the LUT count, the logic cells, the timing,
   the bitstream, the cell names.
3. Run:

   ```bash
   make fpga
   ```

   You should see the same `9   SB_LUT4`, `ICESTORM_LC:      11/   5280`,
   `2.98 ns logic, 23.24 ns routing` and `results/r4.bin 104090 bytes` as in Part 2, and your
   block label where `slice` was in the cell list. With the label `stage`:

   ```
       stage[0].fa.sum_SB_LUT4_O_LC
       stage[1].fa.sum_SB_LUT4_O_LC
       stage[2].fa.sum_SB_LUT4_O_LC
       stage[3].fa.sum_SB_LUT4_O_LC
   ```

4. Compare the two bitstreams:

   ```bash
   cmp results/r4_shipped.bin results/r4.bin && echo same
   ```

   You should see `same`.

5. Your file is different text from the shipped one, and the cell names changed. Why is the
   bitstream identical?

   <details>
   <summary>Answer</summary>

   `i++` and a block label change spelling, not logic, and the proof in Lab 04 already showed the
   logic is the same. The names live in the placed netlist (`results/post.json`, where the cell
   list comes from), not in the bitstream.

   </details>

6. Run `make`. You should see the twelve verdicts listed under Finishing, all `PASS`.

## Finishing

### You're done when

`make` in `labs/lab-05-onto-the-fpga/`, with your own Lab 04 `ripple4.sv` in `src/` (Part 8),
finishes (well under a minute) with twelve verdicts, all `PASS`:

```
PASS  luts      synth_ice40 mapped ripple4 to 9 SB_LUT4
PASS  util      nextpnr placed 11/5280 logic cells and 14/39 pins
PASS  lcs       11 logic cells placed: 9 from your RTL + 2 the packer added
PASS  path      the critical path is 2.98 ns of logic and 23.24 ns of wire
PASS  nofmax    no flip-flops, so --freq 50 had nothing to check
PASS  bitstream r4.bin is 104090 bytes, reference says 104090
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
PASS  toobig    toobig needs 64 pins, the package has 39, and nextpnr says so
PASS  pins      the .pcf placed all 14 pins; the path got 12.1 ns shorter end to end
PASS  asic      the same RTL on SKY130: 4 maj3_1 + 8 xnor2_1 = 110.1056 um^2
PASS  sizes     4 designs, all 104090 bytes
```

The flow is deterministic: the same input produces the same bitstream, byte for byte, and running
`make` twice gives files that `cmp` reports as identical. If a number here differs on your
machine, something really did change. `make check` re-runs the verdicts on artefacts you already
have. The lab's reference numbers, and what each expected warning or `FAIL` means, are on
[Expected results](reference/expected-results.md#lab-05-onto-the-fpga).

### Questions

1. Someone tells you their design must be big because its bitstream is 104,090 bytes. What do you
   tell them, and where would you look instead?

   <details>
   <summary>Answer</summary>

   On this part every bitstream is 104,090 bytes, from one AND gate to 4,001 logic cells
   (Part 4). A bitstream's size tells you which chip, never which design. Read the utilisation
   report: `ICESTORM_LC` and `SB_IO` out of 5,280 and 39.

   </details>

2. Your adder's longest path was 26.22 ns unpinned and 14.11 ns pinned. What does that say about
   predicting FPGA speed from how many gates deep a design is?

   <details>
   <summary>Answer</summary>

   Most of the delay is wire, not logic (Part 6): 23.24 ns of routing against 2.98 ns of logic
   unpinned, and the logic barely changed when only the placement did. Gate depth predicts FPGA
   speed poorly.

   </details>

### Submit

Nothing to submit.

## Going further (optional)

### Your adder as LUTs in DigitalJS

On [DigitalJS Online](https://digitaljs.tilk.eu/), paste your `full_adder.sv`, tick **Map into
LUTs** and press **Run**. The schematic redraws with lookup tables where your gates were. Use it
for the picture, never the count: its Yosys is unpinned, and its LUTs are a generic drawing, not
iCE40 `SB_LUT4`s.

### `icetime`

`icetime` is on your `PATH`. It is the IceStorm timing analyser, from the same project as
`icepack`, and it is what you would reach for to get timing on your `.asc` file. It doesn't work
out of the box on this device in this image, and the way it fails is worth a minute. Run
`make icetime` in `labs/lab-05-onto-the-fpga/`. You should see three steps:

1. The obvious command, `icetime -d up5k -P sg48 -t results/r4.asc`, fails with a message:
   `Can't find chipdb file for device 5k`.
2. The 5k chip database is in the image, at `/foss/tools/fpga/share/icebox/chipdb-5k.txt.gz`,
   and `icetime` has a `-C` flag for pointing at one. Pointed at that file, it prints
   `Segmentation fault (core dumped)` and `icetime exit status 139 -- 139 means it segfaulted.`
   Exit 139, no message.
3. Uncompressed first (27 MB), the same invocation works, so `icetime` is handing a gzip stream
   to something that expected text. These are the two commands `make icetime` runs for this
   step:

   ```bash
   gunzip -c /foss/tools/fpga/share/icebox/chipdb-5k.txt.gz > results/chipdb-5k.txt
   icetime -d up5k -P sg48 -C results/chipdb-5k.txt -t results/r4.asc | tail -12
   ```

   Its report ends `Total path delay: 27.42 ns (36.46 MHz)`. The full tail is on
   [Expected results](reference/expected-results.md#lab-05-onto-the-fpga).

Three things to take from it:

- You never needed it. nextpnr printed a critical path report in Part 2 as part of a run you were
  doing anyway.
- The two tools disagree, 26.22 ns and 27.42 ns, on the same path from `cin` to `cout`. Neither
  is lying. They use different delay models over the same silicon. Don't average them, and don't
  quote either to three decimal places as if it were measured on a bench.
- Read the exit codes. Step 1 failed with a message; step 2 failed with a segfault. A tool that
  segfaults hasn't told you your input is wrong. It has told you nothing, and the temptation is to
  conclude your file is corrupt. Your file was fine both times.

### If you own an iCEBreaker

This is unchecked. With no board attached, `make flash` should print:

```
init..
Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).
ABORT.
```

and exit status 2. That message is verified; the with-a-board path isn't. Nobody has run these
pages against hardware, and USB pass-through into the container is its own project.

Two caveats if you try it. The iCEBreaker carries an iCE40 UP5K in an SG48 package, the part this
lab targets, so the bitstream is the right shape; confirm that against your own board's
documentation, because we couldn't, having no board. And without a `.pcf` matching the board's
wiring, your `sum` bits come out on pins nextpnr chose, which are probably not the pins the LEDs
are on. Making it visibly add would mean writing a real board `.pcf`, which is outside DD102. If
you do it, say so in [Discord](https://discord.gg/hrJnP5UsGz); we'd like to put it in the course.

Next on the [Course path](README.md#course-path): this lab was its last row. You drew a full adder on
paper in DD101, transcribed it in Lab 01, proved it in Lab 02, tested four of them in Lab 03,
generated four of them in Lab 04, and here turned that file into a bitstream for a chip that
already exists. [DD103](https://uoftasic.com/dd103/) takes the same file and builds the chip.
