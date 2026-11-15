# `assign` and `always_comb`

The five `assign` lines on the last two pages sit one under another, so it is natural to ask what
order they run in. They don't run. This catches everyone who has written Python: the five
lines aren't executed in order, or at all. Each one is a permanent connection, a soldered joint,
and all five are live at the same moment for as long as the circuit exists. `assign` doesn't mean
"put this value here". It means "from now on, this wire is that expression".

## Line order

[`src/full_adder_backwards.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_backwards.sv)
is the same five lines in reverse order: `cout`, which depends on everything, comes first, and
`ha1_sum`, which everything depends on, comes last.

```systemverilog
    assign cout      = ha1_carry | ha2_carry;
    assign ha2_carry = ha1_sum & cin;
    assign sum       = ha1_sum ^ cin;
    assign ha1_carry = a & b;
    assign ha1_sum   = a ^ b;
```

It passes all eight rows (`PASS - the lines in reverse order, all 8 rows still match.`), and it
synthesizes to the same 33.7824 µm². In any programming language you have used, reading a
variable four lines before you set it is a bug. Here the question doesn't arise, because there is
no "before". If reordering two lines ever changes what your design does, one of them isn't an
`assign`: you've written something sequential without meaning to, and the rest of this page is
how that happens. You run the backwards file in Lab 01, Part 7.

## Two ways to describe combinational logic

- Use `assign` when the answer is an expression: `sum` is `a ^ b ^ cin`.
- Use `always_comb` when the answer is a list of situations: if this, then that; in this other
  case, this.

Both are combinational: gates, no memory, output follows input, everything at once. The choice
doesn't change what gets built. There is a third keyword, `always_ff`, for building something that
remembers; DD102 doesn't need it and DD103 opens with it.

### The same adder both ways

Here are the five `assign` lines in their usual order, an excerpt of
[`src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder.sv)
(the rest of the file is the port list):

```systemverilog
    assign ha1_sum   = a ^ b;
    assign ha1_carry = a & b;
    assign sum       = ha1_sum ^ cin;
    assign ha2_carry = ha1_sum & cin;
    assign cout      = ha1_carry | ha2_carry;
```

And here is the same adder written as your eight rows, one line each. This is
[`labs/guide-examples/src/full_adder_table.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_table.sv),
complete and runnable as printed:

```systemverilog
module full_adder_table (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    always_comb begin
        case ({a, b, cin})
            3'b000:  {cout, sum} = 2'b00;
            3'b001:  {cout, sum} = 2'b01;
            3'b010:  {cout, sum} = 2'b01;
            3'b011:  {cout, sum} = 2'b10;
            3'b100:  {cout, sum} = 2'b01;
            3'b101:  {cout, sum} = 2'b10;
            3'b110:  {cout, sum} = 2'b10;
            3'b111:  {cout, sum} = 2'b11;
            default: {cout, sum} = 2'b00;
        endcase
    end
endmodule
```

Nothing in that file mentions a gate. It is your DD101 worksheet, transcribed a second time by a
different route. The notation doing the work:

- `{a, b, cin}` is **concatenation**: stick these three 1-bit signals together into one 3-bit
  value, with `a` at the top. So `{1,1,0}` is `3'b110`.
- `{cout, sum} = 2'b10` is the same trick on the left: assign `1` to `cout` and `0` to `sum`, in
  one line, in the order they appear in your table's heading.
- `3'b000` reads "three bits, binary, 000".

The `default:` line can never run: three bits have eight values and all eight are listed. Write
it anyway. It costs nothing here, and the day your list isn't complete it is the difference
between a circuit and an accident. (The latch section below shows the accident.)

### What each spelling costs

The `assign` version looks like a circuit and the `case` version looks like a spreadsheet, so
you might expect them to cost different amounts of silicon. They don't. Synthesized with the
sky130 library, the five-`assign` version, a version with one expression per output, and the
`case` version all come out at 33.7824 µm², to four decimal places, and all three are the same
two cells: one `sky130_fd_sc_hd__xor3_1` and one `sky130_fd_sc_hd__maj3_1`.

The reason is the most useful idea on this page. A synthesizer doesn't read your file as prose.
It reads it as a claim about what the outputs are for every possible input, which is a truth
table, and then it shops for gates that produce that table. Your five `assign`s and your eight
`case` rows make the same claim, so they get the same gates.

In [DD101 Lab 04](https://uoftasic.com/dd101/labs/lab-04-full-adder-overview.html) you learned that one truth
table has infinitely many correct circuits. This is the same fact the other way round: infinitely
many ways of writing the table collapse onto one circuit.

The spellings agree row by row as well. Driving four of them (five `assign`s, one expression per
output, the `case` table and the two-`half_adder` version) from the same eight rows gives
`PASS - four spellings, eight rows, zero disagreements.` You run both checks in Lab 01, Part 7.

## When to use `always_comb`

Use it when writing the logic as an expression would be harder to read, and not before. An adder
is a poor advertisement for `always_comb`, because "sum is a xor b xor cin" is already the
clearest sentence available. `always_comb` earns its place when the logic has cases in it: a mux
choosing between four inputs, a decoder lighting one of eight outputs, a controller deciding what
to do next. The shape is always the same. This is a template, not a file; the angle brackets are
yours to fill:

```systemverilog
    always_comb begin
        y = <a safe default>;          // say what happens when nothing special applies
        if (<some condition>)   y = <this>;
        else if (<another>)     y = <that>;
    end
```

Three rules go with the shape:

1. Inside `always_comb` you write `=`, with no `assign` keyword. (There is also a `<=`, which
   belongs to `always_ff`. DD103's [Blocking vs
   non-blocking](https://uoftasic.com/dd103/guide/blocking-vs-nonblocking.html) settles it with cell
   counts; you don't need it yet.)
2. Anything an `always_comb` block writes must be declared `logic`, which your outputs already
   are.
3. One signal, one driver, still. A signal may be written by one `always_comb` block or by one
   `assign`, and that is the whole list of options.

The default line comes first, and it isn't optional; the next section shows why.

## Driving a signal twice

Rule 3 fails loudly. `errors/both_ways_at_once.sv` drives `sum` from an `always_comb` block and
from an `assign`:

```
--- errors/both_ways_at_once.sv  (Icarus first)
errors/both_ways_at_once.sv:13: error: Cannot perform procedural assignment to variable 'sum' because it is also continuously assigned.
1 error(s) during elaboration.
--- errors/both_ways_at_once.sv  (now Yosys)
    yosys exit 0
Warning: multiple conflicting drivers for both_ways_at_once.\sum:
```

Icarus refuses, and says which variable and why. Yosys exits 0, success, with one warning line in
a log you weren't reading. Two tools, one file, and only one of them stops you. A tool exiting 0
isn't telling you the design is right; when you synthesize, `grep` the log for `Warning` at least
once before you believe the numbers.

## Missing branches and latches

`always_comb` has a trap that `assign` can't have, and it is the reason for the default line.
`errors/forgot_a_branch.sv` is a complete file whose `always_comb` block only says what the
outputs are when `cin` is 1:

```systemverilog
    always_comb begin
        if (cin) begin
            sum  = a ^ b ^ cin;
            cout = (a & b) | (cin & (a ^ b));
        end
        // nothing here says what sum and cout are when cin is 0
    end
```

```
--- errors/forgot_a_branch.sv  (Icarus first)
    iverilog exit 0 - not one word about it
--- errors/forgot_a_branch.sv  (now Yosys)
    yosys exit 1
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process `\forgot_a_branch.$proc$errors/forgot_a_branch.sv:10$1'.
```

A **latch**. You didn't ask for one and you got one, because the description has a hole in it
and only one kind of hardware fits the hole: something that remembers what `sum` was last time,
for the case you didn't describe. That is memory, in a block named `always_comb`. Yosys refuses
outright, with exit 1 and `ERROR` at the start of the line. That refusal helps you; most tools
in this business would have built it.

Every `always_comb` block must assign every signal it writes on every path through it. The
cheapest way to guarantee that is to assign every output once at the top of the block, before any
`if`; then no path can miss. DD103 spends [a whole lab](https://uoftasic.com/dd103/labs/lab-03-three-ways-to-lose-a-latch-overview.html)
on the three ways this bites, including ones where nothing errors at all. You meet it here so the
word `latch` in a log is already familiar when it costs you an afternoon.

## `if` inside an `assign`

The mirror-image mistake is reaching for `if` inside an `assign`. `errors/if_inside_assign.sv` is
one line long and produces this:

```
errors/if_inside_assign.sv:9: syntax error
errors/if_inside_assign.sv:9: error: Syntax error in continuous assignment
errors/if_inside_assign.sv:9: syntax error
errors/if_inside_assign.sv:9: error: Invalid module instantiation
errors/if_inside_assign.sv:9: error: generate else is missing matching if.
```

Five errors for one mistake, and the last three describe things you never wrote: after the parser
trips it keeps guessing. Read the first error, fix only that, and re-run. Error counts in Verilog
don't measure how wrong you are.

`assign` takes an expression. If you want a choice inside an expression, the operator is `? :`.
This line is an excerpt showing the operator, not a file:

```systemverilog
    assign y = sel ? a : b;     // reads: "if sel, then a, otherwise b"
```

If you need more than one or two of those stacked up, use `always_comb` instead.

You see all three of these errors yourself in Lab 01, Part 6.

## Summary

| | `assign` | `always_comb` |
|---|---|---|
| you write | one expression | a block of statements |
| use it when | the answer is a formula | the answer is a list of cases |
| operator inside | `=` after `assign` | plain `=` |
| the trap | none | a path that assigns nothing → latch |
| how many per signal | exactly one | exactly one |
| what it builds | gates | the same gates |

## Check yourself

1. You swap two `assign` lines and your design's behaviour changes. What does that tell you?
2. Why do the five-`assign` version and the `case` version of the full adder cost the same area?
3. An `always_comb` block sets `y` inside `if (en)` and nowhere else. What hardware do you get,
   and what one line prevents it?

Next: [Seeing your adder as a schematic](../guide/seeing-it-come-back.md).
