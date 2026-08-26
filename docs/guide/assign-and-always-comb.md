# Everything happens at once

**Question this page answers:** *Five lines, one under another. What order do they run in?*

None of them. They do not run.

Here is the thing that catches everyone who has ever written Python. The five `assign`
lines you typed on the last page are **not** executed in order. They are not executed at
all. Each one is a permanent connection — a soldered joint — and all five are live at the
same moment, forever. `assign` does not mean "put this value here". It means **"from now
on, this wire *is* that expression."**

You do not have to take that on faith.
[`src/full_adder_backwards.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_backwards.sv)
is the same five lines in exactly the reverse order — `cout`, which depends on everything,
written first, and `ha1_sum`, which everything depends on, written last:

```systemverilog
    assign cout      = ha1_carry | ha2_carry;
    assign ha2_carry = ha1_sum & cin;
    assign sum       = ha1_sum ^ cin;
    assign ha1_carry = a & b;
    assign ha1_sum   = a ^ b;
```

```bash
cd labs/guide-examples
make backwards
```

```
==============================================================
 3b. THE SAME FIVE LINES, WRITTEN BACKWARDS
==============================================================

PASS - the lines in reverse order, all 8 rows still match.
```

Eight rows out of eight, and it prices out at the same **33.7824 µm²**, to the last digit.
In any programming language you have used, using a variable four lines before you set it
is a bug. Here it is not even a question, because there is no "before".

> **The reflex:** if reordering two lines changes what your design does, one of them is not
> an `assign`. Go and look — you have written something sequential without meaning to, and
> the rest of this page is how that happens.

## Two ways to fill in a box

There are two ways to describe combinational logic, and the choice between them is the
second half of this page:

- **`assign`** when the answer is an **expression**. `sum` *is* `a ^ b ^ cin`.
- **`always_comb`** when the answer is a **list of situations**. "If this, then that; in
  this other case, this."
- **The choice does not change what gets built.** We are going to prove that with a number.

Both are combinational — gates, no memory, output follows input, everything at once, which
is what the title of this page is about. There is a third keyword, `always_ff`, which is
how you build something that *remembers*; DD102 does not need it and DD103 opens with it.

### The same adder, both ways

You already have the `assign` version. Here are its five lines the right way round, lifted
out of
[`src/full_adder.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder.sv)
— **an excerpt**, the rest of that file is the port list you already wrote:

```systemverilog
    assign ha1_sum   = a ^ b;
    assign ha1_carry = a & b;
    assign sum       = ha1_sum ^ cin;
    assign ha2_carry = ha1_sum & cin;
    assign cout      = ha1_carry | ha2_carry;
```

And here is the same adder written the other way — as your **eight rows**, one line each.
This is
[`labs/guide-examples/src/full_adder_table.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/src/full_adder_table.sv),
complete and runnable exactly as printed:

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

Nothing in that file mentions a gate. It is your DD101 worksheet, transcribed a second
time by a different route. Two pieces of notation are doing the work:

- `{a, b, cin}` is **concatenation** — stick these three 1-bit signals together into one
  3-bit value, `a` at the top. So `{1,1,0}` is `3'b110`.
- `{cout, sum} = 2'b10` is the same trick on the left: assign `1` to `cout` and `0` to
  `sum`, in one line, in the same order they appear in your table's heading.
- `3'b000` reads "three bits, binary, 000".

The `default:` line can never run — three bits have exactly eight values and all eight are
already listed. Write it anyway. It costs nothing here, and the day your list is *not*
complete it is the difference between a circuit and an accident. (The last section of this
page is what that accident looks like.)

## Predict: which one is bigger?

Before you run anything, commit to an answer.

The `assign` version is five lines of gate names. The `case` version is eight rows of
lookup table plus a default. One of them looks like a circuit and one of them looks like
a spreadsheet. **Write down which one you think costs more silicon, and roughly how much
more.**

```bash
cd labs/guide-examples
make area
```

```
---- 1. drawing - five assigns, one per wire on your paper
   Chip area for module '\full_adder': 33.782400
---- 2. flat - one expression per output
   Chip area for module '\full_adder_flat': 33.782400
---- 3. table - always_comb + case, your eight rows
   Chip area for module '\full_adder_table': 33.782400
```

**Identical. To four decimal places.** All three are two cells: one
`sky130_fd_sc_hd__xor3_1` and one `sky130_fd_sc_hd__maj3_1`.

Here is why, and it is the most useful idea on this page:

> A synthesizer does not read your file as prose. It reads it as **a claim about what the
> outputs are for every possible input** — which is a truth table — and then it goes
> shopping for gates that produce that table. Your five `assign`s and your eight `case`
> rows make *the same claim*. So they get *the same gates*.

In [DD101 Lab 04](https://uoftasic.com/dd101/#/labs/lab-04-full-adder) you learned that one
truth table has infinitely many correct circuits. This is the same fact standing on its
head: infinitely many ways of writing it collapse onto one circuit. The table is the
specification, both times.

And they agree row by row, too — `make spellings` drives all four spellings from the same
eight rows at once:

```
  every column below is cout then sum, on the same eight rows

           drawing  flat  table  boxes
  a b cin |   cs     cs     cs     cs
  --------+---------------------------
  0 0  0  |   00     00     00     00
  0 0  1  |   01     01     01     01
  0 1  0  |   01     01     01     01
  0 1  1  |   10     10     10     10
  1 0  0  |   01     01     01     01
  1 0  1  |   10     10     10     10
  1 1  0  |   10     10     10     10
  1 1  1  |   11     11     11     11

PASS - four spellings, eight rows, zero disagreements.
```

## So when do you actually reach for `always_comb`?

When writing it as an expression would be *worse to read*, and never before.

An adder is a bad advertisement for `always_comb`, because "sum is a xor b xor cin" is
already the clearest possible sentence. `always_comb` earns its keep the moment your logic
has **cases** in it — a mux choosing between four inputs, a decoder lighting one of eight
outputs, a controller deciding what to do next. You will meet all three. The shape is
always the same — this is a **template**, not a file; the angle brackets are yours to fill:

```systemverilog
    always_comb begin
        y = <a safe default>;          // say what happens when nothing special applies
        if (<some condition>)   y = <this>;
        else if (<another>)     y = <that>;
    end
```

**Why the default line comes first, and why it is not optional**, is the rest of this page.

Three mechanical rules that go with the shape:

1. Inside `always_comb` you write `=`, with no `assign` keyword. (There is a `<=` and it
   belongs to `always_ff`. DD103's [Blocking vs
   non-blocking](https://uoftasic.com/dd103/#/guide/blocking-vs-nonblocking) settles it
   with cell counts; you do not need it yet.)
2. Anything an `always_comb` block writes must be declared `logic` — which your outputs
   already are.
3. **One signal, one driver, still.** A signal may be written by one `always_comb` block,
   or by one `assign`, and that is the entire list of options.

## The thing that goes wrong, and the one-line check

Rule 3 first, because it fails loudly and is quickly dealt with.
`errors/both_ways_at_once.sv` drives `sum` from an `always_comb` block *and* from an
`assign`:

```
--- errors/both_ways_at_once.sv  (Icarus first)
errors/both_ways_at_once.sv:13: error: Cannot perform procedural assignment to variable 'sum' because it is also continuously assigned.
1 error(s) during elaboration.
--- errors/both_ways_at_once.sv  (now Yosys)
    yosys exit 0
Warning: multiple conflicting drivers for both_ways_at_once.\sum:
```

Read those two blocks against each other. Icarus **refuses**, and tells you exactly which
variable and why. Yosys **exits 0** — success — with one warning line buried in a log you
were not reading. Two tools, one file, and only one of them stops you.

> **The reflex:** a tool exiting 0 is not a tool telling you the design is right. When you
> synthesize, `grep` the log for `Warning` at least once before you believe the numbers.

Now the important one. `always_comb` has a trap that `assign` cannot have, and it is the
reason for the default line.

`errors/forgot_a_branch.sv` is a complete file whose `always_comb` block only says what
the outputs are when `cin` is 1:

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

**A latch.** You did not ask for one, and you got one, because you wrote a description with
a hole in it and there is only one kind of hardware that fits: something that *remembers*
what `sum` was last time, for the case you did not describe. Memory. In a block you named
`always_comb`.

Yosys refuses outright — exit 1, and the word `ERROR` at the start of the line. That
refusal is a gift; most tools in this business would have built it. The lesson is not
"Yosys is strict", it is **what the hole in your description means**.

> **The reflex, and it is one line:** every `always_comb` block must assign **every**
> signal it writes, on **every** path through it. The cheapest way to guarantee that is to
> assign every output once at the top of the block, before any `if`. Then no path can miss.

DD103 spends [a whole lab](https://uoftasic.com/dd103/#/labs/lab-03-three-ways-to-lose-a-latch)
on the three ways this bites, including the ones where nothing errors at all. You are
meeting it here so that the word `latch` in a log is already familiar when it costs you an
afternoon.

## And the trap in the other direction

The mirror-image mistake is reaching for `if` when you have an `assign`.
`errors/if_inside_assign.sv` is one line long and produces this:

```
errors/if_inside_assign.sv:9: syntax error
errors/if_inside_assign.sv:9: error: Syntax error in continuous assignment
errors/if_inside_assign.sv:9: syntax error
errors/if_inside_assign.sv:9: error: Invalid module instantiation
errors/if_inside_assign.sv:9: error: generate else is missing matching if.
```

**Five errors, one mistake, and the last three are nonsense.** After the parser trips it
keeps guessing, and "invalid module instantiation" and "generate else" describe things you
never wrote.

> **The reflex:** read the **first** error and fix only that. Then re-run. Error counts in
> Verilog are not a measure of how wrong you are.

`assign` takes an *expression*. If you want a choice inside an expression, the expression
that does it is `? :`. **This next line is an excerpt, not a file** — it is one line,
showing you an operator:

```systemverilog
    assign y = sel ? a : b;     // reads: "if sel, then a, otherwise b"
```

If you want more than one or two of those stacked up, stop and use `always_comb`. That is
the whole decision procedure.

## What to remember

| | `assign` | `always_comb` |
|---|---|---|
| you write | one expression | a block of statements |
| use it when | the answer *is* a formula | the answer is a list of cases |
| operator inside | `=` after `assign` | plain `=` |
| the trap | there isn't one | a path that assigns nothing → **latch** |
| how many per signal | exactly one | exactly one |
| what it builds | gates | the same gates |

The last row is the one to keep. **33.7824 µm², three ways.**

Next: [Seeing it come back as a schematic](guide/seeing-it-come-back.md) — you have typed a drawing
into text and proved it with numbers. Now paste that text into a browser and watch it turn
back into a drawing you can click.
