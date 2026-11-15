# Modules and instances

A module has a name, arguments and a body, so it looks a lot like a function, but the two are
different kinds of thing. A function is a verb and a module is a noun.

When you write `sqrt(x)` in Python, nothing exists until the line runs, and nothing survives
after it. You can call `sqrt` a million times and there is still only one `sqrt`: one recipe,
reused one call at a time. A module, on the other hand, is a box that exists. It's a rectangle of
silicon with wires coming out of it, powered on and doing its job continuously whether anyone is
looking or not. If you want two of them you have to build two, and both cost money. This page
shows you that difference in four ways.

## Calling a module like a function

`errors/call_it_like_a_function.sv` in
[`labs/guide-examples`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples) is a
complete file that calls a module like a function:

```systemverilog
    assign sum  = full_adder(a, b, cin);
```

Icarus says:

```
errors/call_it_like_a_function.sv:8: error: No function named `full_adder' found in this context (call_it_like_a_function).
errors/call_it_like_a_function.sv:8: error: Unable to elaborate r-value: full_adder(a, b, cin)
```

The first line says "No function named `full_adder`" because Icarus went looking for a function,
something that computes and returns a value, and there isn't one. Your `full_adder` is closer to
a piece of furniture than to a calculation. If you catch yourself wanting a return value from a
module, what you actually want is a wire connected to one of its output ports, so you declare the
wire, instantiate the box and connect the two. (You'll see this error for yourself in Lab 01,
Part 6.)

## Instantiating a module

Instead of calling a module, you **instantiate** it: you place one, and then name the wire that
runs to each of its ports.

Your DD101 drawing had a `half_adder` subcircuit that you dropped in twice with `Shift + C`, and
the module below is that drawing written out literally. It is all of
[`src/full_adder_hier.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_hier.sv)
apart from its header comment, and it needs
[`src/half_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/half_adder.sv)
compiled alongside it:

```systemverilog
module full_adder_hier (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    logic ha1_sum, ha1_carry, ha2_carry;

    half_adder ha1 (.a(a),       .b(b),   .sum(ha1_sum), .carry(ha1_carry));
    half_adder ha2 (.a(ha1_sum), .b(cin), .sum(sum),     .carry(ha2_carry));

    assign cout = ha1_carry | ha2_carry;
endmodule
```

It helps to read one of those instance lines aloud, in order:

> `half_adder`: place one of these.
> `ha1`: the one I just placed is called `ha1`.
> `.a(a)`: its port called `a` is wired to my wire called `a`.

`ha1` and `ha2` are **instance names**. They aren't variables, and you never assign to them.
They're the labels you would write on the two boxes if you drew this circuit with a pen, which is
exactly what they were on your paper.

The `.port(wire)` form is called **named port connection**, and it's the only form this course
uses. The name after the dot (the dot side) is a port of the module you placed, and the name in
the brackets (the bracket side) is one of your own wires, so `.sum(ha1_sum)` means "the port
named `sum`, which belongs to `half_adder`, connects to my wire named `ha1_sum`". There is
another form,
`half_adder ha1 (a, b, ha1_sum, ha1_carry);`,
which is legal and matches ports by position instead of by name. The trouble is that it silently
builds the wrong circuit on the day somebody reorders the port list in `half_adder.sv`, so don't
use it; nothing in this course does.

## The cost of two instances

`ha1` and `ha2` are two separate half adders. Using one half adder twice isn't an option in
hardware, because a wire can't go off to be somewhere else and then come back.

You can see this in the area. Synthesized against the sky130 cell library, one half adder on its
own is 15.0144 µm², made of one `xor2_1` (8.7584 µm²) and one `and2_0` (6.2560 µm²).
`full_adder_hier` is two of those plus one Or gate, and an Or gate in this library, `or2_0`, is
6.2560 µm². Here is what Yosys reports:

```
---- 5. boxes - two half_adder instances + an Or, walls up
   Chip area for module '\half_adder': 15.014400
   Chip area for module '\full_adder_hier': 6.256000
   Chip area for top module '\full_adder_hier': 36.284800
```

$$15.0144 \times 2 + 6.2560 = 36.2848$$

Two instances cost exactly twice what one instance costs, plus the Or you added on top, and the
numbers agree to the last digit. Yosys breaks the area down the same way: the line for
`full_adder_hier` counts only its own contents, which is the 6.2560 µm² Or gate, and the
`top module` line is that plus everything inside the boxes it contains. You run this yourself in
Lab 01, Part 7.

> In the cell list the Or gate appears as `sky130_fd_sc_hd__lpflow_inputiso1p_1`, which is an
> alarming name for something you drew with two curved lines. If you look it up in the library,
> its logic is `X = A | SLEEP`, so it's an Or gate sold as a power-isolation part, and it costs
> the same 6.2560 µm² as the plainly named `or2_0`. A cell's name is a catalogue number, and it
> says nothing about what you meant the gate to do.

## Module boundaries and optimization

This is where the "box" picture stops fitting. Synthesize the same two files with one extra
command, `flatten`, which erases the module boundaries before anything else happens:

```
---- 6. boxes_flat - the same two boxes, walls knocked down
   Chip area for module '\full_adder_hier': 33.782400
```

The area is now 33.7824 µm², down from 36.2848, so the design got 2.5024 µm² smaller even though
no SystemVerilog changed. The table accounts for the whole difference:

| | Walls up | Walls down | Change |
|---|---|---|---|
| the sum path | 2 × `xor2_1` = 17.5168 | 1 × `xor3_1` = 23.7728 | +6.2560 |
| the carry path | 2 × `and2_0` + 1 Or = 18.7680 | 1 × `maj3_1` = 10.0096 | −8.7584 |
| total | 36.2848 | 33.7824 | −2.5024 |

$$6.2560 - 8.7584 = -2.5024 \qquad 36.2848 - 33.7824 = 2.5024$$

With the walls up, the synthesizer is only allowed to optimize inside each box, so each half
adder keeps its own Xor and And. With the walls down it can see all three inputs at once, and
sky130 sells a single three-input Xor and a single three-input **majority** gate ("at least two
of these are 1"), and a majority of three inputs is exactly what a carry-out is.

A module boundary is a drawing convention. It organizes your thinking and decides which parts
the tool may optimize across, but it doesn't decide what logic gets built. So if a tool tells you
two designs have different areas and identical behaviour, the module boundaries are usually the
reason. Whether to keep them is a real engineering decision, and DD103's
[Reading `stat` like a receipt](https://uoftasic.com/dd103/guide/reading-stat.html) makes the
case properly. For now, it's enough to know that the choice exists.

## Modules and functions compared

| | A Python function | A SystemVerilog module |
|---|---|---|
| exists when | it is called | always |
| ports have | order | order and a direction, `input` or `output` |
| calling it twice | costs nothing extra | builds a second one, at full price |
| finishes | when it returns | never; it is a machine, not an errand |

Direction has no equivalent in software. A module port has a direction fixed in its declaration,
and that direction is part of the contract: an `output` is a wire your box drives, and nothing
else may drive it. It's the same rule that made `two_drivers.sv` fail on the previous page, seen
from the other end.

In Lab 04 you place four `full_adder`s in a row and wire each one's `cout` to the next one's
`cin` to get a 4-bit adder. You don't rewrite the adder to do it; you place four boxes the way
you placed two `half_adder`s here, and they cost four times as much, because there are four of
them.

## Check yourself

1. Why does `full_adder(a, b, cin)` fail, and what do you write instead?
2. `full_adder_hier` costs 36.2848 µm² with its walls up and 33.7824 µm² flattened. Which cells
   does flattening replace, and with which two?
3. What does the dot side of `.sum(ha1_sum)` refer to, and what does the bracket side refer to?

Next: [`assign` and `always_comb`](../guide/assign-and-always-comb.md).
