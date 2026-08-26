# What a module actually is

**Question this page answers:** *It has a name, it has arguments, it has a body. Why isn't
a module just a function?*

Because a function is a **verb** and a module is a **noun**.

When you write `sqrt(x)` in Python, nothing exists until the moment the line runs, and
nothing survives after it. You can call `sqrt` a million times and there is still only one
`sqrt` — one recipe, reused a million times, one at a time.

A module is the opposite of every one of those things. It is a **box that exists**: a
physical rectangle of silicon with wires poking out of it, sitting there, powered on, doing
its job continuously whether anyone is looking or not. If you want two of them, you build
two of them, and they both cost money.

The rest of this page is that sentence, made concrete four different ways.

## You cannot call it

Start with the mistake. `errors/call_it_like_a_function.sv` in
[`labs/guide-examples`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples)
is a complete file that tries the obvious thing:

```systemverilog
    assign sum  = full_adder(a, b, cin);
```

```bash
make errors
```

```
--- errors/call_it_like_a_function.sv
errors/call_it_like_a_function.sv:8: error: No function named `full_adder' found in this context (call_it_like_a_function).
errors/call_it_like_a_function.sv:8: error: Unable to elaborate r-value: full_adder(a, b, cin)
```

**"No function named `full_adder`."** Not "wrong number of arguments", not "modules take
different syntax" — the tool looked for a *function*, which is a thing that computes and
returns, and there is no such thing here. Your `full_adder` is furniture, not a verb.

> **The reflex:** if you catch yourself wanting a return value from a module, what you
> actually want is a **wire connected to one of its output ports**. Declare the wire,
> instantiate the box, connect them.

## What you write instead

You do not call a module. You **instantiate** it — you place one — and then you name the
wire that runs to each of its ports.

Your DD101 drawing had a `half_adder` subcircuit that you dropped in twice with
`Shift + C`. Here is that drawing, taken completely literally. The module below is the
whole of
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

Read one of those lines out loud in the right order and it stops being syntax:

> `half_adder` — *place one of these.*
> `ha1` — *and the one I just placed is called `ha1`.*
> `.a(a)` — *its port called `a` is wired to my wire called `a`.*

`ha1` and `ha2` are **instance names**. They are not variables and you never assign to
them; they are the labels you would write on the two boxes if you were drawing this with a
pen — which is exactly what they were on your paper.

The `.port(wire)` form is called **named port connection**, and it is the only form this
course uses.

> **The dot side is theirs; the bracket side is yours.** `.sum(ha1_sum)` means "the port
> named `sum`, which belongs to `half_adder`, connects to my wire named `ha1_sum`". The
> other form — `half_adder ha1 (a, b, ha1_sum, ha1_carry);` — is legal, matches by
> position, and silently builds the wrong circuit the day somebody reorders the port list
> in `half_adder.sv`. Do not use it. Nothing in this course will.

## Two instances are two pieces of hardware

This is where the noun/verb difference stops being philosophy and starts costing money.

`ha1` and `ha2` are two separate half adders. Not one half adder used twice — **two**.
There is no "used twice" available: a wire cannot be somewhere else and then come back.

You can watch that on the price tag. First, one half adder alone:

```bash
cd labs/guide-examples
make area
```

```
---- 4. half - one half adder, alone
   Chip area for module '\half_adder': 15.014400
```

**15.0144 µm²** — one `xor2_1` (8.7584 µm²) and one `and2_0` (6.2560 µm²).

**Predict before you scroll.** `full_adder_hier` is two of those plus one Or gate. An Or
gate in this library, `or2_0`, costs 6.2560 µm². Write down your number.

```
---- 5. boxes - two half_adder instances + an Or, walls up
   Chip area for module '\half_adder': 15.014400
   Chip area for module '\full_adder_hier': 6.256000
   Chip area for top module '\full_adder_hier': 36.284800
```

$$15.0144 \times 2 + 6.2560 = 36.2848$$

**To the last digit.** Two instances cost exactly twice one instance, plus the Or you added
on top — and Yosys reports it in exactly that shape: `full_adder_hier`'s *own* contents are
the 6.2560 µm² Or gate, and the `top module` line is that plus everything inside the boxes
it contains.

> The Or gate shows up in the report as `sky130_fd_sc_hd__lpflow_inputiso1p_1`, which is an
> alarming name for something you drew with two curved lines. Look it up in the library and
> its logic is `X = A | SLEEP` — it is an Or gate, sold as a power-isolation part, and it
> costs **exactly the same 6.2560 µm²** as the plainly-named `or2_0`. A cell's name is a
> catalogue number, not a description of your intent.

## The walls are yours, not the silicon's

Here is the part that will not fit in the "box" metaphor, and it is worth meeting now
rather than in DD103.

Ask the same two files to be synthesized with one extra command — `flatten`, which erases
the module boundaries first:

```
---- 6. boxes_flat - the same two boxes, walls knocked down
   Chip area for module '\full_adder_hier': 33.782400
```

**33.7824 µm², down from 36.2848.** The design got *smaller* by 2.5024 µm² and not one
character of SystemVerilog changed.

The whole difference is accounted for, exactly:

| | walls up | walls down | change |
|---|---|---|---|
| the sum path | 2 × `xor2_1` = 17.5168 | 1 × `xor3_1` = 23.7728 | +6.2560 |
| the carry path | 2 × `and2_0` + 1 Or = 18.7680 | 1 × `maj3_1` = 10.0096 | −8.7584 |
| **total** | **36.2848** | **33.7824** | **−2.5024** |

$$6.2560 - 8.7584 = -2.5024 \qquad 36.2848 - 33.7824 = 2.5024$$

With the walls up, the synthesizer is only allowed to optimize *inside* each box, so the
two half adders each keep their own Xor and And. With the walls down, it can see all three
inputs at once, and sky130 happens to sell a single three-input Xor and a single
three-input **majority** gate — "at least two of these are 1", which is precisely what a
carry-out is.

> **The reflex:** a module boundary is a *drawing convention*. It organises your thinking
> and it decides who can optimize across what. It does **not** decide what gets built. If
> a tool tells you two designs have different areas and identical behaviour, the
> boundaries are usually why.

Whether to keep the walls up is a real engineering decision with real consequences, and
DD103's [Reading `stat` like a receipt](https://uoftasic.com/dd103/#/guide/reading-stat)
is the page that argues it properly. For now: know that the choice exists.

## The four things a module has that a function does not

| | a Python function | a SystemVerilog module |
|---|---|---|
| exists when | it is called | always |
| **ports** have | order | order **and a direction** — `input` or `output` |
| calling it twice | costs nothing extra | **builds a second one**, at full price |
| finishes | when it returns | never; it is a machine, not an errand |

The **direction** row is the one with no software equivalent at all. A function argument
goes one way. A module port has a direction burned into its declaration, and it is part of
the contract: an `output` is a wire your box drives, and nobody else is allowed to drive
it. That is the same rule that made `two_drivers.sv` fail on the previous page, seen from
the other end.

## Where this goes

You now have a `full_adder` box with five ports and a contract. In the
four-adder lab you will place **four** of them in a row,
wire each one's `cout` to the next one's `cin`, and have a 4-bit
adder — the thing this course is aimed at. You will not rewrite the adder to do it. You
will place four boxes, exactly the way you placed two `half_adder`s here, and the four of
them will cost four times as much, because there are four of them.

Next: [Everything happens at once](guide/assign-and-always-comb.md) — five lines that
are not five steps, a second way to write the inside of a box that looks alarmingly like a
program, and the rule for choosing between them.
