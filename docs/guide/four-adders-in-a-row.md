# Four adders in a row

**Question this page answers:** *My adder handles one bit. Real numbers have more than one
bit. What do I actually change?*

Almost nothing, and that is the point of this page.

You have a `full_adder` that is proven on all eight of its rows. Four-bit addition does not
need a bigger adder. It needs **four of the one you already have**, standing in a line, each
one handing its carry to the next — which is exactly the picture you drew on paper in
[Where the carry goes](https://uoftasic.com/dd101/#/guide/where-the-carry-goes) before you had
ever seen a line of SystemVerilog.

Every command and every number below was run on the workbench. Where a number comes from a lab
package, the package is named.

## The thing you already know how to do

Line up two four-bit numbers and add them the way you were taught in school, except in binary:

```
      carries:   1 1 1 0
                 1 0 0 1     (9)
               + 1 0 0 1     (9)
               -----------
               1 0 0 1 0     (18)
```

Column zero has two inputs. **Every other column has three** — the two digits and whatever the
column to its right handed over. That is a full adder, four times, wired right-to-left.

The only genuinely new idea in this part of the course is how you say "four of them" without
typing four of them.

## First, a wire can be more than one wire

Up to now every signal you declared held one bit. `logic [3:0] a` declares **four** wires that
travel together and answer to one name:

- `a` is all four of them
- `a[0]` is the rightmost — the ones column
- `a[3]` is the leftmost — the eights column
- `a[2:1]` is the middle two

This is card 2 of [The DD102 subset](reference/the-dd102-subset.md), and the shipped file is
[`src/02_logic_and_vectors.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/02_logic_and_vectors.sv).
Run `make` in `labs/reference-card` and it prints, for `a = 1001`:

```
PASS  02_logic_and_vectors   a=1001 y=0110 a[3]=1 a[2:1]=00
```

`[3:0]` is read "three down to zero". Write it that way round every time. The other order is
legal, it means something different, and no design in this course wants it.

## The carry chain is one vector too

Here is the move that makes the whole thing tidy. You need somewhere to put the carry between
adder 0 and adder 1, between 1 and 2, and between 2 and 3 — plus the carry coming in at the
bottom and the carry leaving at the top. That is **five** carries for four adders.

So declare five wires, and let the index do the talking:

```systemverilog
    logic [4:0] c;
    assign c[0] = cin;
```

Now adder `i` reads `c[i]` and drives `c[i+1]`, for every `i`, with no exceptions and no
special case at either end. The bottom carry is `c[0]`, which you tied to `cin`; the top carry
is `c[4]`, which becomes `cout`.

**Why an engineer cares:** the version of this with four separately named wires — `c1`, `c2`,
`c3`, `c4` — works exactly as well and is what `add4.sv` in
[Lab 03](labs/lab-03-the-lazy-testbench-overview.md) does. It also cannot be written as a loop, and it
gives you four chances to type `c2` where you meant `c3`. Indexing a vector is how you make
the four lines *identical*, and identical lines are the ones a machine can write for you.

## Writing it out the long way, once

This is a complete file. It is
[`labs/reference-card/src/08_generate_for.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/08_generate_for.sv)
with the loop expanded by hand, and it is also, character for character, the shape of
[`labs/lab-04-four-adders-in-a-row/reference/ripple4_hand.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/reference/ripple4_hand.sv):

```systemverilog
module ripple4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);
    logic [4:0] c;
    assign c[0] = cin;

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));

    assign cout = c[4];
endmodule
```

Read the four middle lines downwards. **Every index goes up by exactly one and nothing else
changes.** When four lines differ only by a counter, you are doing a machine's job.

## The same thing, written once

```systemverilog
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : slice
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]),
                           .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
```

**This is an excerpt** — the complete, runnable file it comes from is
[`labs/reference-card/src/08_generate_for.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/08_generate_for.sv),
which is card 8 and which `make` in `labs/reference-card` runs for you:

```
PASS  08_generate_for        9+9+0 -> cout=1 sum=2 (= 18)
```

Nine plus nine is eighteen, `sum` is 2 and `cout` is 1, and `{cout, sum}` read together as five
bits is `10010` — the same eighteen you added on paper at the top of this page.

### Nothing in there loops

This is the sentence to keep. **`generate for` is not a loop in your hardware.** There is no
counter on the chip, nothing happens four times in sequence, and `i` does not exist after
synthesis.

The loop runs **once, inside the tool**, during a phase called **elaboration**, before
simulation or synthesis begins. What comes out is four separate `full_adder` instances sitting
side by side — precisely the file you wrote by hand in the previous section. `generate for` is a
typing device, and its output is text.

> **The reflex:** if you catch yourself asking *"how fast does the loop run?"*, the answer is
> that there is no loop. Ask instead *"what four things did it leave behind?"* —
> [Lab 04](labs/lab-04-four-adders-in-a-row-overview.md) makes Yosys **prove** the two files build the
> same circuit, for every one of their inputs, and shows you the counterexample when they do not.

### `begin : slice` is not decoration

`begin : slice` names the block, and the tool uses that name to tell the four copies apart. The
second adder is called `slice[1].fa`. That string is not trivia — it is what appears in error
messages, in waveform hierarchies, and in timing reports. In
[Lab 05](labs/lab-05-onto-the-fpga-overview.md) the FPGA's critical path prints as

```
Info: 2.98 ns logic, 23.24 ns routing
```

with `slice[1].fa` and `slice[2].fa` named in the middle of the path. **Drop the `: slice` and
those become anonymous**, and the day something is slow you will not be able to say which of
the four it was.

## One file, every width

Once the four lines are one line, the `4` is the only thing left to argue with. Make it a
`parameter` and it stops being an argument:

```systemverilog
module ripple #(
    parameter int N = 4
) (
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    input  logic         cin,
    output logic [N-1:0] sum,
    output logic         cout
);
```

**This is an excerpt of the port list.** The complete file is
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv),
and its own header comment makes the promise: *"`ripple #(.N(4))` is exactly `src/ripple4.sv`.
`ripple #(.N(64))` is 64 bits and the file does not get any longer."*

You pick the width where you *use* it — `ripple #(.N(8)) u (...)` — and the default applies when
you do not. Card 9,
[`src/09_parameter.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/09_parameter.sv),
runs both in one file:

```
PASS  09_parameter           N=4 -> 00001111   N=6 -> 00111111
```

Here is what that buys, measured with `synth_ice40` on the workbench. One `full_adder` on its
own maps to **2 `SB_LUT4`**, and the packer adds a few more on top. So:

| you instantiate | `SB_LUT4` |
|---|---|
| `ripple #(.N(4))` | **8** |
| `ripple #(.N(8))` | **16** |
| `ripple #(.N(16))` | **32** |
| `ripple #(.N(32))` | **64** |

Two lookup tables per bit, exactly, all the way up — and every one of those four rows is a
`PASS` line printed by `make` in
[`labs/lab-04-four-adders-in-a-row/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-04-four-adders-in-a-row):

```
PASS  luts4         ripple #(.N(4))  -> 9 SB_LUT4
PASS  luts8         ripple #(.N(8))  -> 18 SB_LUT4
PASS  luts16        ripple #(.N(16)) -> 37 SB_LUT4
PASS  luts32        ripple #(.N(32)) -> 74 SB_LUT4
```

The source file did not get longer. The hardware did.

## The trap, and it is silent

This one has cost more first-year afternoons than every syntax error combined, and it has no
error message at all.

**Widths are decided by the left-hand side.** Add two 4-bit numbers and the answer can need
five bits. If you assign it to something four bits wide, the fifth bit is thrown away —
silently, with `iverilog` exit 0, no warning, nothing.

Card 11,
[`src/11_width_truncation.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/11_width_truncation.sv),
is a complete file that does both in one module and prints the difference:

```
PASS  11_width_truncation    9+9 -> narrow[3:0]=2  wide[4:0]=18
```

**Same two inputs. Same `+`. One answer is 18 and the other is 2.** The only difference is that
`narrow` was declared `[3:0]` and `wide` was declared `[4:0]`.

You have already been bitten by this without knowing its name. `add4.sv` in
[Lab 03](labs/lab-03-the-lazy-testbench-overview.md) computes its top carry correctly and then has
nowhere to put it, which is why it is wrong on **256 of 512** inputs — exactly half, because the
carry out is 1 exactly half the time.

> **The reflex, and it is one line:** *N bits plus N bits does not fit in N bits.* Every adder
> you write needs somewhere for the top carry to go, which is why `ripple` has a `cout` port and
> `add4` did not. Count the bits on the **left** of the `=` before you believe the right.

## How many inputs is "all of them"?

An $N$-bit adder has $2N + 1$ input bits: $N$ for `a`, $N$ for `b`, one for `cin`. So it has
$2^{2N+1}$ possible situations.

| width | input bits | combinations |
|---|---|---|
| 1 (`full_adder`) | 3 | **8** |
| 4 (`ripple4`) | 9 | **512** |
| 8 | 17 | **131,072** |
| 16 | 33 | **8,589,934,592** |

512 is nothing — the shipped testbench does all of them in under a second. 131,072 also takes
under a second. At sixteen bits, exhaustive testing is finished as a technique, and the whole
of DD104 is about what you do instead.

**Do not take 512 on faith.** `make` in
[`labs/lab-04-four-adders-in-a-row/`](https://github.com/uoftasic/dd102/tree/main/labs/lab-04-four-adders-in-a-row)
prints the count as it goes:

```
PASS  wide4         got PASS 0/512, reference says PASS 0/512   (ripple #(.N(4)), all 512 inputs)
PASS  wide8         got PASS 0/131072, reference says PASS 0/131072   (ripple #(.N(8)), all 131072 inputs)
```

## The part that trips people up

**"`generate` is a loop, so it must be slow."** There is no loop. Four adders exist at the same
instant and compute at the same instant. What *does* cost you time is the carry travelling
through them one after another, and that is a different mechanism with a different fix — it is
[The carry has to travel](guide/the-carry-has-to-travel.md), the next page.

**"The hand-written and generated versions might not be identical."** They are, and you are not
going to be asked to believe it. Lab 04 hands both files to Yosys's equivalence checker and
gets a proof:

```
PASS  proof         Yosys proved generate == hand-typed, for every input
```

**"`c` is five bits because of an off-by-one somewhere."** It is five bits because four adders
have five carry positions: one coming in, three between them, one going out. Draw the four
boxes and count the arrows crossing the gaps.

## What to remember

- `logic [3:0] a` is four wires with one name. `[3:0]`, in that order, always.
- Four adders need **five** carry positions — `logic [4:0] c`, with `c[0] = cin` and
  `cout = c[4]`.
- **`generate for` is elaboration-time typing, not hardware.** It leaves four instances behind
  and then it is gone.
- `begin : slice` is what makes `slice[1].fa` appear in reports. Keep it.
- `parameter int N = 4` makes one file every width, at **just over 2 `SB_LUT4` per bit** on iCE40.
- **N bits plus N bits does not fit in N bits.** The left-hand side decides, and truncation is
  silent.

Next: [Lab 04 — Four adders in a row](labs/lab-04-four-adders-in-a-row-overview.md), where you write the
loop, prove it equals the hand-typed version, and get two predictions wrong on purpose. Then
[The carry has to travel](guide/the-carry-has-to-travel.md) puts a nanosecond count on the chain
you just built.
