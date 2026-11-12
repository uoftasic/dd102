# Vectors, generate loops and parameters

Your adder handles one bit, and real numbers have more than one. Four-bit addition doesn't need
a bigger adder. It needs four of the one you already have, in a line, each handing its carry to
the next: the picture you drew on paper in
[Where the carry goes](https://uoftasic.com/dd101/#/guide/where-the-carry-goes) before you had seen
any SystemVerilog. This page covers the three pieces of syntax that make that tidy: vectors,
`generate for` and `parameter`. You use all three in
[Lab 04](labs/lab-04-four-adders-in-a-row-overview.md).

## Adding by hand

Line up two four-bit numbers and add them the way you learned in school, in binary:

```
      carries:   1 1 1 0
                 1 0 0 1     (9)
               + 1 0 0 1     (9)
               -----------
               1 0 0 1 0     (18)
```

Column zero has two inputs. Every other column has three: the two digits and whatever the column
to its right handed over. That is a full adder, four times, wired right to left. The new idea is
how to say "four of them" without typing four of them.

## Vectors

Until now every signal you declared held one bit. `logic [3:0] a` declares four wires that travel
together under one name:

- `a` is all four of them
- `a[0]` is the rightmost, the ones column
- `a[3]` is the leftmost, the eights column
- `a[2:1]` is the middle two

`[3:0]` reads "three down to zero". Write it that way round every time. The other order is legal,
means something different, and no design in this course wants it. This is card 2 of
[The DD102 subset](reference/the-dd102-subset.md); for `a = 1001` its file,
[`src/02_logic_and_vectors.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/02_logic_and_vectors.sv),
prints `a=1001 y=0110 a[3]=1 a[2:1]=00`.

## The carry chain as a vector

You need somewhere to put the carry between adders 0 and 1, between 1 and 2, and between 2 and 3,
plus the carry coming in at the bottom and the carry leaving at the top. That is five carries for
four adders, so declare five wires and let the index do the work:

```systemverilog
    logic [4:0] c;
    assign c[0] = cin;
```

Adder `i` reads `c[i]` and drives `c[i+1]`, for every `i`, with no special case at either end. The
bottom carry is `c[0]`, tied to `cin`; the top carry is `c[4]`, which becomes `cout`.

A version with four separately named wires (`c1`, `c2`, `c3`, `c4`) works just as well, and it is
what `add4.sv` in [Lab 03](labs/lab-03-the-lazy-testbench-overview.md) does. But it can't be
written as a loop, and it gives you four chances to type `c2` where you meant `c3`. Indexing a
vector makes the four lines identical, and identical lines are the ones a machine can write for
you.

## Writing it out the long way

This is a complete file: card 8,
[`labs/reference-card/src/08_generate_for.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/08_generate_for.sv),
with its loop expanded by hand. It is also the shape of
[`labs/lab-04-four-adders-in-a-row/reference/ripple4_hand.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/reference/ripple4_hand.sv).

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

Read the four middle lines downwards. Every index goes up by one and nothing else changes. When
four lines differ only by a counter, you are doing a machine's job.

## `generate for`

The same four instances, written once (an excerpt of card 8):

```systemverilog
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : slice
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]),
                           .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
```

Card 8 prints `9+9+0 -> cout=1 sum=2 (= 18)`. Nine plus nine is eighteen: `sum` is 2 and `cout`
is 1, and `{cout, sum}` read together as five bits is `10010`, the same eighteen you added on paper
at the top of this page.

### What elaboration does

`generate for` isn't a loop in your hardware. There is no counter on the chip, nothing happens
four times in sequence, and `i` doesn't exist after synthesis. The loop runs once, inside the
tool, during a phase called **elaboration**, before simulation or synthesis begins. What comes out
is four separate `full_adder` instances side by side, the same as the file you wrote out by hand.
`generate for` is a typing device, and its output is text.

`genvar` isn't a wire either. It is a compile-time integer that exists only while the loop is
being unrolled, which is why it has its own keyword instead of being an `int`.

If you catch yourself asking "how fast does the loop run?", there is no loop. Ask instead "what
four things did it leave behind?" In Lab 04, Yosys proves that the loop and the hand-typed file
build the same circuit for every input, and shows you a counterexample when they don't.

### The block label

`begin : slice` names the block, and the tools use that name to tell the four copies apart: the
second adder is called `slice[1].fa`. That string appears in error messages, in waveform
hierarchies and in place-and-route reports. In
[Lab 05](labs/lab-05-onto-the-fpga-overview.md), nextpnr's list of placed logic cells for your
adder includes `slice[0].fa.sum_SB_LUT4_O_LC` through `slice[3].fa.sum_SB_LUT4_O_LC`. Drop the
`: slice` and those names become anonymous, and the day something is slow or broken you can't
say which of the four it was.

Don't call the block `bit`. `bit` is a SystemVerilog type keyword; Yosys rejects it and Icarus
crashes on it, which you see in Lab 04, Part 5.

## `parameter`

Once the four lines are one line, the `4` is the only thing left. Make it a `parameter`:

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

That is the port list of
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv),
and its header comment says: *"`ripple #(.N(4))` is exactly `src/ripple4.sv`. `ripple #(.N(64))`
is 64 bits and the file does not get any longer."*

You pick the width where you use it, `ripple #(.N(8)) u (...)`, and the default applies when you
don't. Card 9,
[`src/09_parameter.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/09_parameter.sv),
uses both in one file and prints `N=4 -> 00001111   N=6 -> 00111111`.

Here is what that buys on an iCE40 FPGA, measured with `synth_ice40` in Lab 04, Part 6:

| You instantiate | `SB_LUT4` |
|---|---|
| `ripple #(.N(4))` | 9 |
| `ripple #(.N(8))` | 18 |
| `ripple #(.N(16))` | 37 |
| `ripple #(.N(32))` | 74 |

Just over two lookup tables per bit at every width: 2.25 per bit at 4 and 8 bits, and about 2.31
at 16 and 32. Doubling the width doubles the LUTs, near enough, and the source file stays the same length.

## Width truncation

This mistake has no error message at all. Widths are decided by the left-hand side. Add two 4-bit
numbers and the answer can need five bits. Assign it to something four bits wide and the fifth bit
is thrown away silently: `iverilog` exits 0 with no warning.

Card 11,
[`src/11_width_truncation.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/11_width_truncation.sv),
does both in one module and prints `9+9 -> narrow[3:0]=2  wide[4:0]=18`. Same two inputs, same
`+`, and one answer is 18 while the other is 2. The only difference is that `narrow` was declared
`[3:0]` and `wide` was declared `[4:0]`.

You met this in Lab 03 without its name. `add4.sv` computes its top carry correctly and then has
nowhere to put it, which is why it is wrong on 256 of 512 inputs. N bits plus N bits doesn't fit
in N bits. Every adder needs somewhere for the top carry to go, which is why `ripple` has a `cout`
port and `add4` didn't. Count the bits on the left of the `=` before you believe the right.

## How many inputs is "all of them"?

An $N$-bit adder has $2N + 1$ input bits: $N$ for `a`, $N$ for `b` and one for `cin`. So it has
$2^{2N+1}$ possible inputs.

| Width | Input bits | Combinations |
|---|---|---|
| 1 (`full_adder`) | 3 | 8 |
| 4 (`ripple4`) | 9 | 512 |
| 8 | 17 | 131,072 |
| 16 | 33 | 8,589,934,592 |

512 is nothing: the shipped testbench does all of them in under a second, and 131,072 also takes
under a second. At sixteen bits exhaustive testing is finished as a technique, and DD104 is about
what you do instead. Lab 04 runs the 512 and the 131,072 and prints the counts.

## Common misreadings

"`generate` is a loop, so it must be slow." There is no loop. Four adders exist at the same
instant and compute at the same instant. What does cost time is the carry travelling through them
one after another, which is a different mechanism with a different fix; that is the subject of
[Carry delay](guide/the-carry-has-to-travel.md).

"The hand-written and generated versions might not be identical." They are, and you don't have to
take it on trust: Lab 04 hands both files to Yosys's equivalence checker and gets a proof.

"`c` is five bits because of an off-by-one somewhere." It is five bits because four adders have
five carry positions: one in, three between them, one out. Draw the four boxes and count the
arrows crossing the gaps.

## Check yourself

1. Why does a 4-bit ripple adder need `logic [4:0] c` rather than `logic [3:0] c`?
2. After synthesis, how many `full_adder` instances does the `generate for` above leave behind,
   and what happened to `i`?
3. `logic [3:0] s; assign s = a + b;` with `a = 9` and `b = 9`. What is `s`, and what warning do
   you get?
4. What does `begin : slice` give you that an unlabelled block doesn't?

Next on the [Course path](README.md#course-path): do
[Lab 04: Four adders in a row](labs/lab-04-four-adders-in-a-row-overview.md).
