# Lab 05 — Onto the FPGA

Full runnable package:
[`labs/lab-05-onto-the-fpga/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-05-onto-the-fpga).

**The question this lab answers:** *Where does it actually go?*

You have a file. It simulates. Yosys has proved it correct. None of that is a chip.

This lab takes `ripple4.sv` — the file you wrote in
[Lab 04](labs/lab-04-four-adders-in-a-row.md), unchanged — and produces **a binary you could
load into a real Lattice iCE40 UP5K and it would add numbers**. Three commands, and `make fpga`
runs all three in **0.8 seconds**.

Then it does something more interesting than that, which is to make you predict the size of
the binary.

> **You do not need a board, and this course does not assume you own one.** Everything here
> is synthesis and place-and-route: real tools, real timing, a real bitstream. If you happen to
> have an iCEBreaker, `make flash` exists and is optional, and nothing in this lab or in DD103
> depends on it.

## Prerequisites

- [IC101](https://uoftasic.com/ic101/) complete — the workbench desktop launches
- DD102 cloned under `workspace/modules/dd102`
- [Lab 04](labs/lab-04-four-adders-in-a-row.md) done: you have a `ripple4.sv` built from one
  `generate for`, and a proof that it is correct
- Read [The chip is already there](guide/the-chip-is-already-there.md)
- `yosys -V` says **`0.64`** and `nextpnr-ice40 --version` says **`Version nextpnr-0.10-33-ge6ecd8fa`**

## Objectives

- Turn RTL into a loadable bitstream with three commands and no vendor software
- Read a utilisation report and account for **every** cell in it, including the two you did
  not write
- Explain why an FPGA bitstream is the same size for a design of 3 cells and a design of 4001
- Recognise what running out of chip looks like, and which line of the failure is the real one
- Send the same source file to a completely different kind of target, and say what changed

## Theory (short)

Three programs, three questions.

| Tool | Question it answers | What it hands you |
|---|---|---|
| `yosys -p "synth_ice40"` | *Which of the chip's cells do I need?* | a netlist of `SB_LUT4`s |
| `nextpnr-ice40` | *Which physical cells, and how do the wires get between them?* | an `.asc` — every cell and every switch, in text |
| `icepack` | *What is that as bytes?* | a `.bin` — the bitstream |

The thing to hold on to is that **none of these tools build anything**. The chip exists. It came
out of a factory a long time before you opened your laptop, in millions, all identical. Every
one of those 5,280 logic cells is already sitting on the die whether your design uses it or not.

What you are producing is a **settings file** for a machine that already exists. That single
fact explains every surprising number in this lab.

## Procedure

```bash
. /foss/designs/common/.designinit
mod dd102
cd labs/lab-05-onto-the-fpga
yosys -V                 # expect: Yosys 0.64
make                     # all five steps, well under a minute
```

Individual steps: `make fpga`, `make sizes`, `make fits`, `make pins`, `make contrast`.
`make icetime` and `make flash` are optional and are discussed at the end.

### 1 — Three commands

```
make fpga
```

The first is Yosys, in the same shape you have used since Lab 02, with one word changed —
`synth_ice40` instead of `synth`:

```
yosys -p "read_verilog -sv src/ripple4.sv src/full_adder.sv; synth_ice40 -top ripple4 -json results/r4.json" > results/ys.log 2>&1
    yosys wrote 910 lines to results/ys.log. The answer is one of them:
        8   SB_LUT4
        8   SB_LUT4
```

> **Yosys writes 910 lines and says nothing about it.** That is normal, it is why `make`
> redirects it to a file, and the answer is the two-word line above. The count appears twice
> because Yosys prints statistics for the module and then for the whole hierarchy. If you open
> `results/ys.log` you will also find **4 `$scopeinfo`** next to the eight LUTs: those are name
> tags, one per `full_adder` instance, not hardware. The hand-typed version from Lab 03
> produces exactly the same four.

**Eight lookup tables.** Two per bit of adder — one for `sum`, one for `cout` — which is the
same 2-per-bit you measured at four widths in Lab 04.

Then `nextpnr-ice40` decides *where*:

```
nextpnr-ice40 --up5k --package sg48 --json results/r4.json --asc results/r4.asc --write results/post.json --freq 50 > results/pnr.log 2>&1
Warning: No PCF file specified; IO pins will be placed automatically
Info: 	         ICESTORM_LC:      10/   5280     0%
Info: 	        ICESTORM_RAM:       0/     30     0%
Info: 	               SB_IO:      14/     39    35%
Info: 	               SB_GB:       0/      8     0%
```

> **Three pieces of output to name before you meet them.**
>
> `Warning: No PCF file specified` is the **only** warning this run produces, and the run ends
> `1 warning, 0 errors`. It means you did not say which physical pins your signals should come
> out on, so nextpnr picked. Step 4 is where you say.
>
> `make` shows four rows; the full table in `results/pnr.log` has **fifteen** resource types,
> and you are using two of them. The other thirteen — RAMs, a PLL, an I2C block, an LED driver,
> two oscillators — are on the die. They are always on the die.
>
> `Info: No Fmax available; no interior timing paths found in design.` appears **twice**, and
> it means your adder has no flip-flops, so there is no clock, so the `--freq 50` you typed had
> nothing to check. It is not a failure. Step 2 has a design where it does mean something.

**`10 / 5280`.** Yosys said eight. Where did two more come from?

The usual answer is that the packer merged something, and that answer is wrong here — the
packer's own report says `8 LCs used as LUT4 only` and zero for every other category. So
`make fpga` asks the placed netlist directly and lists all ten by name:

```
--- yosys said 8 SB_LUT4 and nextpnr says 10 cells. Here are all ten. ---
    cin_SB_LUT4_I1_LC
    cout_SB_LUT4_O_I3_SB_LUT4_O_LC
    cout_SB_LUT4_O_LC
    slice[0].fa.sum_SB_LUT4_O_LC
    slice[1].fa.sum_SB_LUT4_O_LC
    slice[2].fa.sum_SB_LUT4_O_I3_SB_LUT4_O_LC
    slice[2].fa.sum_SB_LUT4_O_LC
    slice[3].fa.sum_SB_LUT4_O_LC
    $PACKER_GND      <- nobody wrote this one
    $PACKER_VCC      <- nobody wrote this one

PASS  lcs       10 logic cells placed: 8 from your RTL + 2 the packer added
```

$8 + 2 = 10$, and the two are `$PACKER_GND` and `$PACKER_VCC`. **The chip has no wire that is
permanently 0 and no wire that is permanently 1**, so when the design needs a constant, the
packer spends a general-purpose logic cell to manufacture one. A hard `0` costs you a cell in
the warehouse. That is the kind of thing that is true of rented buildings and not of
architecture.

Look at the other eight names, too: `slice[0]`, `slice[1]`, `slice[2]`, `slice[3]`. That is the
label you wrote after `begin :` in Lab 04, still attached to your logic three tools later.

Finally `icepack`, which is the shortest step in the course:

```
icepack results/r4.asc results/r4.bin
  results/r4.asc 707718 bytes
  results/r4.bin 104090 bytes
  results/r4.json 336437 bytes
```

**You have a bitstream.** `results/r4.bin`, 104,090 bytes. Load that into an iCE40 UP5K and the
part adds four-bit numbers.

> `r4.json` is about **336 KB** and yours will differ by a few hundred bytes — Yosys records
> the source path of every wire, so the number moves depending on where you cloned the repo.
> `r4.asc` (**707,718 bytes**) and `r4.bin` (**104,090 bytes**) are stable, and the checker only
> asserts the one that matters.

### 2 — The number nobody predicts

`make sizes` builds two more designs and you are going to guess wrong about both, so write your
guesses down first.

- **`src/one_gate.sv`** is one AND gate. Two inputs, one output, three lines of logic.
- **`src/big.sv`** is a 4000-stage shift register — 4000 flip-flops, three pins.

Your adder's bitstream was 104,090 bytes. **How big is each of these?**

Most people reason proportionally: the AND gate is maybe a hundredth the size of the adder, and
the shift register is hundreds of times bigger, so something like 1 KB and 20 MB.

```
make sizes
```

```
  one_gate  Info: ICESTORM_LC: 3/ 5280 0%
  big       Info: ICESTORM_LC: 4001/ 5280 75%

  bitstream            bytes
  one_gate.bin         104090
  r4.bin               104090
  big.bin              104090

PASS  sizes     3 designs, all 104090 bytes
```

**Identical. To the byte.** A design using 3 logic cells and a design using 4001 — a factor of
1,334 — produce files of exactly the same length.

Here is the arithmetic that closes it, and it is the whole lesson of this lab. **The bitstream
is not a description of your design.** It is the setting of every configuration bit on the
entire die: all 5,280 logic cells, all 30 block RAMs, the PLL, the I2C blocks, the routing
switches between them, whether you touched any of them or not. `one_gate` configures 5,277
logic cells to do nothing. Your adder configures 5,270 of them to do nothing. Both statements
take the same number of bytes to write down, because "do nothing" is a setting like any other.

So what *is* different between them?

```
--- so how many of those 104090 bytes actually differ? ---
  one_gate.bin vs r4.bin : 187 bytes differ
  r4.bin       vs big.bin: 20479 bytes differ
```

**187 bytes.** That is the entire difference between "one AND gate" and "a four-bit adder", in
a 104,090-byte file — 0.18 % of it. The other 99.82 % is the two designs agreeing about the
5,270-odd cells neither of them uses.

**Reflex: an FPGA bitstream's size tells you which chip, never which design.** If somebody
hands you a bitstream and asks how big the design is, the file size cannot answer. The
utilisation report can.

### 3 — Running out of chip

An ASIC design cannot run out of area — it just gets bigger, and bigger costs money. An FPGA
design absolutely can run out of chip. What it runs out of is rarely what you expect.

`src/toobig.sv` is a 16 × 16 multiplier: one `assign`, and `p = a * b`.

```
make fits
```

```
nextpnr exit status 255
Info: 	         ICESTORM_LC:     692/   5280    13%
Info: 	               SB_IO:      64/     39   164%
ERROR: Unable to find a placement location for cell 'p[17]$sb_io'
1 warning, 1 error
    The error names ONE pin. The line above it names the real problem.
```

The logic fits easily — 692 of 5,280 cells, 13 %. What does not fit is the **pins**: two 16-bit
inputs and a 32-bit output is 64 signals, and the SG48 package has 39 usable I/O. `164 %`.

Notice how the tool tells you. The `ERROR` line names one arbitrary pin, `p[17]`, which is not
special in any way and is not where your problem is. **The utilisation table printed just above
it is the real message.** This is a general habit worth forming: when a place-and-route tool
fails, read *upward* from the error.

**Reflex: `164%` in a utilisation table is the bug. The `ERROR:` line below it is just where
the tool happened to give up.**

### 4 — Saying which pin is which

The warning from step 1 has been waiting. `constraints/r4.pcf` is fourteen lines that answer it:

```
set_io a[0]    2
set_io a[1]    3
...
set_io cout   18
```

> **This is an excerpt** — the complete file is
> [`constraints/r4.pcf`](https://github.com/uoftasic/dd102/blob/main/labs/lab-05-onto-the-fpga/constraints/r4.pcf)
> in the lab package. Those fourteen pin numbers are **valid** on a UP5K in the SG48 package
> and are **not** wired to anything in particular on any board. The file is here to show you
> what the mechanism is, not to light an LED.

```
make pins
```

```
Info: Placed 14 cells based on constraints.
Info: 	         ICESTORM_LC:      10/   5280     0%
Info: 	               SB_IO:      14/     39    35%
Info: 3.50 ns logic, 12.67 ns routing
  bitstream: 104090 bytes   (295 bytes differ from the unpinned one)
```

`Placed 14 cells based on constraints` — open `results/pnr.log` from step 1 and the same line
reads `Placed 0 cells based on constraints.` Same logic, same ten cells, same 104,090 bytes.
**295** of those bytes moved.

And look at the timing. In step 1 the longest path was **3.85 ns of logic and 19.01 ns of
routing**; here it is **3.50 and 12.67**. Nothing about your design changed. You told the tool
where the signals had to enter and leave the chip, the placer put the logic near those pins,
and the wires got 6.3 ns shorter.

**On an FPGA, most of your delay is wire.** 19.01 against 3.85 is roughly five to one. That
ratio is why "how many gates deep is it?" is a poor prediction of speed on an FPGA and why the
next course cares so much about where things physically sit.

The longest path in step 1, in full, reads: input pin `cin` → `cin_SB_LUT4_I1_LC` →
`slice[1].fa` → `slice[2].fa` → `cout` → output pin, totalling **22.86 ns**. That is your carry,
walking. [The carry has to travel](guide/the-carry-has-to-travel.md) said it would take time;
this is the number, on a real part, with your generate-block label printed in the middle of it.

### 5 — The same file, somewhere else entirely

```
make contrast
```

`scripts/asic.ys` reads **the same two files** — `src/ripple4.sv` and `src/full_adder.sv`,
untouched — and sends them somewhere that is not an FPGA:

```
        4   40.038   sky130_fd_sc_hd__maj3_1
        8   70.067   sky130_fd_sc_hd__xnor2_1
   Area for cell type $scopeinfo is unknown!
   Chip area for module '\ripple4': 110.105600

  FPGA:  8 SB_LUT4, 10 of 5280 cells used, a 104090-byte bitstream.
  ASIC:  12 named cells, 110.1056 um^2, and no chip yet. That is DD103.
```

> `Area for cell type $scopeinfo is unknown!` is those name tags again. They are not cells and
> they have no area; the message is Yosys being pedantic, and it is not a problem.

Two answers from one file, and the difference is not quality.

|  | FPGA (iCE40 UP5K) | ASIC (SKY130) |
|---|---|---|
| your logic becomes | 8 × `SB_LUT4` | 4 × `maj3_1` + 8 × `xnor2_1` |
| the report says | 10 of 5,280 cells used | 110.1056 µm² |
| you hand over | a 104,090-byte **bitstream** | a **GDSII** |
| how big is that file? | the same for every design | grows with your design |
| to change it | reload it, seconds | manufacture it again, months |

An `SB_LUT4` is sixteen bits of memory and a multiplexer: it *could have been* any function of
four inputs, and you chose which. A `sky130_fd_sc_hd__maj3_1` is fourteen transistors arranged
to compute "at least two of these three are high", and it will never do anything else, because
that arrangement is the thing being built.

**That is why one file is a fixed size and the other is not.** The bitstream describes a chip
that exists — including everything on it you did not use. A GDSII describes only what you
built, because nothing exists yet.

**DD103 is where the second column becomes real.** Same `ripple4.sv`, and a flow that ends in a
picture of your own silicon.

### The self-check

```
PASS  luts      synth_ice40 mapped ripple4 to 8 SB_LUT4
PASS  util      nextpnr placed 10/5280 logic cells and 14/39 pins
PASS  lcs       10 logic cells placed: 8 from your RTL + 2 the packer added
PASS  path      the critical path is 3.85 ns of logic and 19.01 ns of wire
PASS  nofmax    no flip-flops, so --freq 50 had nothing to check
PASS  bitstream r4.bin is 104090 bytes, reference says 104090
PASS  one_gate  one_gate placed 3/5280 logic cells and 3/39 pins
PASS  big       big placed 4001/5280 logic cells and closes timing at 202.92 MHz
PASS  toobig    toobig needs 64 pins, the package has 39, and nextpnr says so
PASS  pins      the .pcf placed all 14 pins; the path got 6.7 ns shorter end to end
PASS  asic      the same RTL on SKY130: 4 maj3_1 + 8 xnor2_1 = 110.1056 um^2
PASS  sizes     4 designs, all 104090 bytes
```

Every run of this flow is **deterministic** — the same input produces the same bitstream, byte
for byte, and re-running `make` twice gives files that `cmp` reports as identical. If a number
here differs on your machine, something really did change.

## The dead end: `icetime`

There is a program called `icetime` on your `PATH`. It is part of the same IceStorm project as
`icepack`, it is the IceStorm timing analyser, and it is exactly what you would reach for if
you wanted timing on your `.asc` file. **It does not work out of the box on this device in this
image**, and the way it does not work is worth twenty seconds of your attention:

```
make icetime
```

```
  step 1: the obvious command
icetime -d up5k -P sg48 -t results/r4.asc
// Reading input .asc file..
// Reading 5k chipdb file..
Can't find chipdb file for device 5k
```

The chip database for the 5k family *is* in the image, at
`/foss/tools/fpga/share/icebox/chipdb-5k.txt.gz`. `icetime` has a `-C` flag for pointing at one
directly. So you point it at the file that is obviously right there:

```
  step 2: the obvious fix, pointing -C straight at the file
// Reading input .asc file..
// Reading 5k chipdb file..
Segmentation fault (core dumped)
    ^ icetime exit status 139 -- 139 means it segfaulted.
```

**It crashes.** Exit 139, no message, no hint. The difference between that and the command
that works is the `.gz`: uncompress the database first and the identical invocation is fine, so
`icetime` is handing a gzip stream to something that expected text.

```
  step 3: what actually works (27 MB of chipdb, unpacked)
gunzip -c /foss/tools/fpga/share/icebox/chipdb-5k.txt.gz > results/chipdb-5k.txt
icetime -d up5k -P sg48 -C results/chipdb-5k.txt -t results/r4.asc | tail -12
```

```
    24.258 ns io_pad_12_31_1_din

Resolvable net names on path:
     1.105 ns ..  5.966 ns a[0]$SB_IO_IN
     7.251 ns ..  9.661 ns slice[1].fa.sum_SB_LUT4_O_I3[2]
    10.866 ns .. 13.820 ns slice[2].fa.sum_SB_LUT4_O_I3[2]
    15.025 ns .. 20.005 ns cout_SB_LUT4_O_I3[2]
    21.210 ns .. 24.071 ns cout$SB_IO_OUT

Total number of logic levels: 5
Total path delay: 24.26 ns (41.22 MHz)
```

Three observations, in order of usefulness.

**You never needed it.** `nextpnr` already printed a critical path report in step 1, for free,
as part of a run you were doing anyway. The tool that looks like the answer was a detour around
a number you already had.

**The two tools disagree: 22.86 ns and 24.26 ns.** They also disagree about where the path
starts — nextpnr traced it from `cin`, icetime from `a[0]`. Neither is lying. They use
different delay models over the same silicon, and a 6 % spread between two static timing tools
is ordinary. **Do not average them, and do not quote one to three decimal places as if it were
measured on a bench.**

**Read the exit codes.** Step 1 failed with a *message*. Step 2 failed with a *segfault*. A
tool that segfaults has not told you that your input is wrong — it has told you nothing at all,
and the temptation is to conclude that your file is corrupt. Your file was fine both times.

## If you own an iCEBreaker

Optional, unchecked, and genuinely fun.

```
make flash
```

With no board attached:

```
init..
Can't find iCE FTDI USB device (vendor_id 0x0403, device_id 0x6010 or 0x6014).
ABORT.
```

Exit status 2. That message is verified; **the with-a-board path is not** — nobody has run
these pages against hardware, and USB pass-through into the container is its own adventure.

Two honest caveats if you try it. The iCEBreaker carries an iCE40 UP5K in an SG48 package — the
part this lab targets — so the bitstream is the right *shape*. (Confirm that against your own
board's documentation; we could not, having no board.) But without a `.pcf` matching that
board's wiring, your `sum` bits come out on pins nextpnr chose at random, which are probably
not the pins the LEDs are on. Making it visibly add would mean writing a real board `.pcf`, and
that is outside DD102. Come and say so in [Discord](https://discord.gg/hrJnP5UsGz) if you do
it — we would like to put it in the course.

## Expected results

Measured on `hpretl/iic-osic-tools:2026.04` — Yosys 0.64, nextpnr-ice40 0.10-33-ge6ecd8fa,
IceStorm, Python 3.12.3. `make` completes in **well under a minute** and ends with a table of
twelve verdicts, all `PASS`.

| what | number |
|---|---|
| `synth_ice40` on `ripple4` | **8 × `SB_LUT4`** (+ 4 `$scopeinfo`) |
| nextpnr logic cells | **10 / 5280** — 8 yours, `$PACKER_GND` and `$PACKER_VCC` |
| nextpnr I/O | **14 / 39** |
| longest path | **22.86 ns** = 3.85 ns logic + 19.01 ns routing |
| with `constraints/r4.pcf` | **16.17 ns** = 3.50 + 12.67, and `Placed 14 cells based on constraints` |
| **bitstream** | **104,090 bytes** |
| `one_gate` / `big` bitstreams | **104,090 bytes** each — 3 and 4001 logic cells |
| bytes that differ, `one_gate` vs `r4` | **187** |
| `toobig` | 692/5280 logic, **64/39 pins**, `ERROR: Unable to find a placement location` |
| the same file on SKY130 | 4 `maj3_1` + 8 `xnor2_1`, **110.1056 µm²** |
| `icetime` step 2 | **exit 139**, `Segmentation fault (core dumped)` |

## If something goes wrong

| What you see | What it means |
|---|---|
| `nextpnr-ice40: command not found` | You are not inside the workbench container. |
| `Warning: No PCF file specified` | Expected in steps 1, 2 and 3. It is the only warning the good runs produce. |
| `No Fmax available` | Expected. Your adder has no clock. `src/big.sv` in step 2 does, and reports 202.92 MHz. |
| `ERROR: Unable to find a placement location` | Expected in step 3 only. Read the utilisation table above it. |
| `Segmentation fault (core dumped)` | Expected from `make icetime` step 2 only. |
| `FAIL` on any line of `make check` | Paste the whole line into [Discord](https://discord.gg/hrJnP5UsGz) — it has your number and the reference side by side. |

## Links

- Lab package:
  [`labs/lab-05-onto-the-fpga/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-05-onto-the-fpga)
- Guide: [The chip is already there](guide/the-chip-is-already-there.md) ·
  [The carry has to travel](guide/the-carry-has-to-travel.md)
- Previous lab: [Lab 04 — Four adders in a row](labs/lab-04-four-adders-in-a-row.md)
- **Next course: DD103.** You are finished with DD102. You drew a full adder on paper in DD101,
  transcribed it in Lab 01, proved it in Lab 02, watched its carry in Lab 03, generated four of
  them in Lab 04, and here you turned that file into a bitstream for a chip that already
  exists. DD103 takes the *same file* and builds the chip.
