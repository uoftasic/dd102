# Vectors, generate loops and parameters

Your adder handles one bit, and real numbers have more than one. To add four-bit numbers you
don't need a bigger adder; you need four of the one you already have, in a line, with each one
handing its carry to the next. That's the picture you drew on paper in
[Where the carry goes](https://uoftasic.com/dd101/guide/where-the-carry-goes.html) before you had seen
any SystemVerilog. This page covers the three pieces of syntax that let you write it down tidily:
vectors, `generate for` and `parameter`. You use all three in
[Lab 04](../labs/lab-04-four-adders-in-a-row-overview.md).

## Adding by hand

Line up two four-bit numbers and add them the way you learned in school, in binary:

```
      carries:   0 0 1 0
                 1 0 0 1     (9)
               + 1 0 0 1     (9)
               -----------
               1 0 0 1 0     (18)
```

Column zero has two inputs. Every other column has three: its two digits and whatever the column
to its right handed over. Adding three bits to get a sum digit and a carry is exactly what a full
adder does, so four-bit addition is four full adders wired right to left. What's new on this page
is how to say "four of them" without typing four of them.

## Vectors

Until now every signal you declared held one bit. `logic [3:0] a` declares four wires that travel
together under one name:

- `a` is all four of them
- `a[0]` is the rightmost, the ones column
- `a[3]` is the leftmost, the eights column
- `a[2:1]` is the middle two

`[3:0]` reads "three down to zero", and you should write it that way round every time. The other
order is legal, but it means something different, and no design in this course needs it. Vectors
are card 2 of [The DD102 subset](../reference/the-dd102-subset.md). With `a = 1001`, that card's
file,
[`src/02_logic_and_vectors.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/02_logic_and_vectors.sv),
prints `a=1001 y=0110 a[3]=1 a[2:1]=00`.

## The carry chain as a vector

You need somewhere to put the carry between adders 0 and 1, between 1 and 2, and between 2 and 3,
plus the carry coming in at the bottom and the carry leaving at the top. That makes five carries
for four adders, so you declare five wires and let the index keep track of which is which:

```systemverilog
    logic [4:0] c;
    assign c[0] = cin;
```

Adder `i` reads `c[i]` and drives `c[i+1]`, for every `i`, with no special case at either end. The
bottom carry is `c[0]`, tied to `cin`; the top carry is `c[4]`, which becomes `cout`.

A version with four separately named wires (`c1`, `c2`, `c3`, `c4`) works just as well, and it's
what `add4.sv` in [Lab 03](../labs/lab-03-the-lazy-testbench-overview.md) does. The trouble is
that it can't be written as a loop, and it gives you four chances to type `c2` where you meant
`c3`. Indexing a vector makes the four adder lines identical except for the number in the
brackets, and lines that differ only by a number are ones a machine can write for you.

## Writing it out the long way

Here is a complete file. It's card 8,
[`labs/reference-card/src/08_generate_for.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/08_generate_for.sv),
with its loop expanded by hand, and it has the same shape as
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

Read the four `full_adder` lines from top to bottom: every index goes up by one from each line to
the next, and nothing else changes, so these are exactly the lines the next section has the tool
write for you.

## `generate for`

Here are the same four instances written once, in an excerpt from card 8:

```systemverilog
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : slice
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]),
                           .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
```

Card 8 prints `9+9+0 -> cout=1 sum=2 (= 18)`. Nine plus nine is eighteen, which doesn't fit in
four bits, so `sum` holds 2 and `cout` holds 1. Read together as five bits, `{cout, sum}` is
`10010`, the same eighteen you added on paper at the top of this page.

### What elaboration does

Although it's written like one, `generate for` doesn't put a loop in your hardware. There is no
counter on the chip, nothing happens four times in sequence, and `i` doesn't exist after
synthesis. The loop runs once, inside the tool, during a phase called **elaboration** that comes
before simulation or synthesis begins. What comes out is four separate `full_adder` instances side
by side, the same as in the file you wrote out by hand. So `generate for` saves you typing, and
what it produces is text, the same text you would otherwise have typed yourself.

Nor is `genvar` a wire. It's a compile-time integer that exists only while the loop is being
unrolled, which is why it has its own keyword instead of being declared as an `int`.

If you catch yourself asking how fast the loop runs, remember that by the time anything runs
there is no loop, and ask instead what four things it left behind. In Lab 04, Yosys proves that
the loop and the hand-typed file build the same circuit for every input, and when they don't, it
shows you a counterexample.

### The block label

`begin : slice` names the block, and the tools use that name to tell the four copies apart: the
second adder is called `slice[1].fa`. That name appears in error messages, in waveform
hierarchies and in place-and-route reports. In
[Lab 05](../labs/lab-05-onto-the-fpga-overview.md), for example, nextpnr's list of placed logic
cells for your adder includes `slice[0].fa.sum_SB_LUT4_O_LC` through
`slice[3].fa.sum_SB_LUT4_O_LC`. If you leave out the `: slice`, those names become anonymous, so on
the day one of the four adders is slow or broken you can't tell which one it was.

Don't call the block `bit`, though. `bit` is a SystemVerilog type keyword, so Yosys rejects it as
a block name and Icarus crashes on it; you'll see both happen in Lab 04, Part 5.

## `parameter`

Once the four lines have become one, the `4` is the only thing left that fixes the width, so you
make it a `parameter`:

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

That's the port list of
[`labs/lab-04-four-adders-in-a-row/src/ripple.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/src/ripple.sv),
and its header comment says: *"`ripple #(.N(4))` is exactly `src/ripple4.sv`. `ripple #(.N(64))`
is 64 bits and the file does not get any longer."*

You choose the width where you instantiate the module, as in `ripple #(.N(8)) u (...)`, and if you
don't choose one you get the default. Card 9,
[`src/09_parameter.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/09_parameter.sv),
does both in one file and prints `N=4 -> 00001111   N=6 -> 00111111`.

Here is what each width costs on an iCE40 FPGA, as measured with `synth_ice40` in Lab 04, Part 6:

| You instantiate | `SB_LUT4` |
|---|---|
| `ripple #(.N(4))` | 9 |
| `ripple #(.N(8))` | 18 |
| `ripple #(.N(16))` | 37 |
| `ripple #(.N(32))` | 74 |

That's just over two lookup tables per bit at every width: 2.25 per bit at 4 and 8 bits, and about
2.31 at 16 and 32. Doubling the width roughly doubles the number of LUTs, while the source file
stays the same length.

## Width truncation

This mistake produces no error message at all. When you add two 4-bit numbers the answer can need
five bits, but how many bits you keep is decided by the left-hand side of the assignment. If you
assign the sum to something four bits wide, the fifth bit is thrown away silently: `iverilog`
exits 0 and gives no warning.

Card 11,
[`src/11_width_truncation.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/11_width_truncation.sv),
does it both ways in one module and prints `9+9 -> narrow[3:0]=2  wide[4:0]=18`. Both results come
from the same two inputs and the same `+`, but one answer is 18 and the other is 2, and the only
difference is that `narrow` was declared `[3:0]` and `wide` was declared `[4:0]`.

You met this twice in Lab 03. `add4.sv` computes its top carry correctly and then has nowhere to
put it, which is why it's wrong on 256 of its 512 inputs, and in Part 8 `add4_wider_inside.sv`
computes all five bits and then drops the fifth at the assignment, which Verilator reported as
`WIDTHTRUNC`. The sum of two N-bit numbers doesn't always fit in N bits, so every adder needs
somewhere for the top carry to go, and that's why `ripple` has a `cout` port and `add4` didn't.
Before you believe the right-hand side of an `=`, count the bits on the left.

## How many inputs is "all of them"?

An $N$-bit adder has $2N + 1$ input bits: $N$ for `a`, $N$ for `b` and one for `cin`. So it has
$2^{2N+1}$ possible inputs.

| Width | Input bits | Combinations |
|---|---|---|
| 1 (`full_adder`) | 3 | 8 |
| 4 (`ripple4`) | 9 | 512 |
| 8 | 17 | 131,072 |
| 16 | 33 | 8,589,934,592 |

512 is a small number: the shipped testbench tries all of them in under a second, and the 131,072 for
eight bits also take under a second. At sixteen bits there are more than eight billion, and
exhaustive testing stops being a usable technique; DD104 is about what you do instead. Lab 04
runs the 512 and the 131,072 and prints the counts.

## Common misreadings

"`generate` is a loop, so it must be slow." By the time anything runs there is no loop: the four
adders exist at the same instant and compute at the same instant. What does take time is the
carry travelling through them one after another, which is a different mechanism with a different
fix, and it's the subject of [Carry delay](../guide/the-carry-has-to-travel.md).

"The hand-written and generated versions might not be identical." They are identical, and you don't
have to take it on trust: Lab 04 hands both files to Yosys's equivalence checker and gets a proof.

"`c` is five bits because of an off-by-one somewhere." It's five bits because four adders have
five carry positions: one in, three between them, one out. Draw the four boxes and count the
arrows crossing the gaps.

## Check yourself

1. Why does a 4-bit ripple adder need `logic [4:0] c` rather than `logic [3:0] c`?
2. After synthesis, how many `full_adder` instances does the `generate for` above leave behind,
   and what happened to `i`?
3. `logic [3:0] s; assign s = a + b;` with `a = 9` and `b = 9`. What is `s`, and what warning do
   you get?
4. What does `begin : slice` give you that an unlabelled block doesn't?

Next on the [Course path](../index.md#course-path): do
[Lab 04: Four adders in a row](../labs/lab-04-four-adders-in-a-row-overview.md).
