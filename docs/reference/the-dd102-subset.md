# The DD102 subset

This page is a lookup card. When you know what you want to write but not exactly how to spell it,
find the construct here and copy its shape.

DD102 asks you to write twelve pieces of SystemVerilog and no others. The language has hundreds
more, and you'll meet them later, but you don't need any of them to transcribe a drawing, prove
that it works and put it on an FPGA.

## Running the cards

Each card below comes from a complete file that compiles and runs on its own, and all twelve
files ship in
[`labs/reference-card/`](https://github.com/uoftasic/dd102/tree/main/labs/reference-card), so
you can run all of them at once:

```bash
cd /foss/designs/modules/dd102/labs/reference-card
make
```

```
VERDICT PASS  — all 12 cards match the reference run.
```

The run takes about 0.3 seconds, and it doesn't need `.designinit`, `mod`, a PDK or any
environment variables. If one of the lines on this page doesn't match what your machine prints,
`make` tells you which line it is, in the same words this page uses.

The outputs on this page came from Icarus Verilog 14.0 in `hpretl/iic-osic-tools:2026.08`. You
can check your version with `iverilog -V`, and the first line it prints should be:

```
Icarus Verilog version 14.0 (devel) (s20260301-391-g64f13540-dirty)
```

That is the first of 73 lines, and the rest are the GPL licence text and a list of code
generators, which is normal.
[Lab 01, Part 1](../labs/lab-01-transcribe-your-adder-overview.md) has the details.

## The twelve

| # | Construct | What it is | It printed |
|---|---|---|---|
| 1 | `module` … `endmodule` | a box with labelled edges, using the same labels as your drawing | `a=1 b=1 y=1` |
| 2 | `logic`, `logic [3:0]` | the only type you need, one bit or several | `a=1001 y=0110 a[3]=1 a[2:1]=00` |
| 3 | `assign` with `& \| ^ ~` | a soldered connection, which holds all the time | `and=0 or=1 xor=1 not_a=0` |
| 4 | `{cout, sum}` | glue bits into one wider bus | `{cout=1, sum=2} = 10010 = 18` |
| 5 | `always_comb` + `if`/`else` | the same hardware, described in words instead of an expression | `sel=1 -> 9   sel=0 -> 4` |
| 6 | `case` … `default:` | a truth table you can read | `00->0001 01->0010 10->0100 11->1000` |
| 7 | `full_adder fa0 (.a(x), …);` | putting a module inside a module | `1+1+1 -> cout=1 sum=1 (= 3)` |
| 8 | `genvar` + `generate for` | write one instance, get four | `9+9+0 -> cout=1 sum=2 (= 18)` |
| 9 | `parameter int N = 4` | one file, every width | `N=4 -> 00001111   N=6 -> 00111111` |
| 10 | `4'b1010`, `4'd10`, `4'hA` | how to write a number | `4'b1010=10  4'd10=1010  4'hA=1010` |
| 11 | width rules | the left-hand side sets the width, which is a trap | `9+9 -> narrow[3:0]=2  wide[4:0]=18` |
| 12 | `` `timescale ``, `$display`, `$dumpfile`, `$finish` | used only in testbenches; none of it becomes hardware | `at 20 ns, a=1 y=0` |

To run one card on its own, give `make` its number:

```bash
make card N=11
```

```
--- src/11_width_truncation.sv
11_width_truncation: 9+9 -> narrow[3:0]=2  wide[4:0]=18
```

## The shapes

### 1 · `module` and the port list

The port list is the edge of your drawing written out as text. Each port gives its direction,
then its type, then its name.

```systemverilog
module gate_box (
    input  logic a,
    input  logic b,
    output logic y
);
    assign y = a & b;
endmodule
```

*(Excerpt from
[`src/01_module_ports.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/01_module_ports.sv),
which also contains the small testbench that printed `a=1 b=1 y=1`.)*

Ports of the same direction and type can share a line, as in `input logic a, b, cin;`. The
[`errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors) folder has a
file showing that you can't call a module the way you would call a function.

### 2 · `logic`, and wires with no port

Signals that have a name on your drawing but don't reach the edge are declared inside the module,
before you use them:

```systemverilog
logic ha1_sum, ha1_carry, ha2_carry;
```

`logic [3:0] a` declares four wires in a bundle. `a[3]` is one of them, and `a[2:1]` is two of
them. The numbering runs `[high:low]`, and every file in this course writes its buses in that
order, as `[3:0]`.

> If you leave the declaration out, neither tool stops you. Icarus compiles the file, simulates it
> and gets the right answer, and Yosys builds it with only a warning. The file that shows this is
> [`errors/undeclared_wire.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/errors/undeclared_wire.sv).
> Every name inside a module is either a port or declared on a `logic` line, so a name that is
> neither is a typo.

### 3 · `assign`

An `assign` line describes a wire. If you have programmed before, you might read it as a statement
that runs once, but it doesn't mean "do this now"; it means "these two things are the same,
permanently".

| You write | It means |
|---|---|
| `assign y = a & b;` | And |
| `assign y = a \| b;` | Or |
| `assign y = a ^ b;` | Xor |
| `assign y = ~a;` | Not |

Everything happens at once, so the order of your `assign` lines doesn't matter. Write them in the
order the signal travels, because that is easiest to read.

If two `assign`s drive the same signal, the second one doesn't overwrite the first; the pair is an
error. One `assign` and one `always_comb` writing the same signal are an error too. Both refusals
are in
[`errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors), and
[`assign` and `always_comb`](../guide/assign-and-always-comb.md) explains why.

### 5 · `always_comb`

`always_comb` builds the same hardware as `assign`, written a different way. Use it when the logic
is easier to describe in sentences than in one expression. Inside it you use `=`, not `<=`, and
you may use `if`/`else` and `case`.

```systemverilog
always_comb begin
    if (sel) out = x;
    else     out = y;
end
```

You need the `else`, and Icarus won't tell you when it's missing. The shipped
[`errors/forgot_a_branch.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/errors/forgot_a_branch.sv)
is a full adder whose `always_comb` assigns its outputs only when `cin` is 1, and Icarus compiles
it without complaint:

```bash
cd /foss/designs/modules/dd102/labs/guide-examples
iverilog -g2012 -o /dev/null errors/forgot_a_branch.sv ; echo "iverilog exit=$?"
```

```
iverilog exit=0
```

Icarus prints no warning and exits with 0. Yosys, given the same file, refuses to build it:

```bash
yosys -p "read_verilog -sv errors/forgot_a_branch.sv; synth -top forgot_a_branch"
```

```
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process
       `\forgot_a_branch.$proc$errors/forgot_a_branch.sv:10$1'.
```

Yosys exits with code 1. A circuit that doesn't say what `sum` is when `cin` is 0 has to remember
the old value, and a circuit that remembers is a latch, which is real hardware you didn't ask for.
This check is the reason to use `always_comb`: Yosys refuses a latch in an `always_comb`, but it
doesn't check `always @*` at all.

> Every output of an `always_comb` gets a value on every path. If you wrote an `if`, write the
> `else`; if you wrote a `case`, write the `default`.

DD103's
[The latch you didn't ask for](https://uoftasic.com/dd103/guide/the-latch-you-didnt-ask-for.html)
covers latches in full, with three ways to lose a latch.

### 8 · `generate for`

Four full adders in a row, written once:

```systemverilog
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : slice
        full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]),
                       .sum(sum[i]), .cout(c[i+1]));
    end
endgenerate
```

*(Excerpt from
[`src/08_generate_for.sv`](https://github.com/uoftasic/dd102/blob/main/labs/reference-card/src/08_generate_for.sv),
which is complete and runs.)*

The loop doesn't exist in the silicon. It runs once, while the tool reads your file, and leaves
four full adders behind. To see what those four adders cost on an iCE40, run:

```bash
make synth
```

```
=== ripple4 ===
   13 cells
    4   $scopeinfo
    9   SB_LUT4
```

That's nine `SB_LUT4`, exactly what four hand-written instances cost, because the loop produced
four ordinary instances. The four `$scopeinfo` cells are bookkeeping, not hardware. A
`generate for` saves you typing, but it never makes the circuit cheaper. (The note `make synth`
prints under the table still says "Eight SB_LUT4", which is out of date; the count above it is
the current one.)

Two things are worth knowing about the label after `begin :`:

- `begin : slice` names the copies `slice[0]`, `slice[1]` and so on. Yosys, nextpnr and the
  waveform viewer all use those names.
- Don't call it `bit`, because `bit` is a type keyword. Yosys reports
  `syntax error, unexpected TOK_LOGIC, expecting TOK_ID`, and Icarus does something worse: it
  crashes:

  ```
  errors/ripple4_bit.sv:7: assert: pform.cc:1575: failed assertion lexical_scope == cur_module
  Aborted (core dumped)
  ```

  Icarus exits with code 134. The compiler itself has crashed, so the message tells you nothing
  about what's wrong with your file. The shipped
  [`errors/ripple4_bit.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/errors/ripple4_bit.sv)
  lets you cause the crash once on purpose, so that it doesn't confuse you when it happens by
  accident.

> A crash with `assert:` and `core dumped` in it is a bug in the tool. Look at the line number it
> named, and suspect a name on that line before you suspect your logic.

`i = i + 1` and `i++` both work here, and both synthesize to the same 9 `SB_LUT4`. Somebody will
tell you otherwise, so we ship
[`errors/ripple4_incr.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/errors/ripple4_incr.sv)
for you to settle the argument yourself.

### 10 · Literals

A literal is written as its width, an apostrophe, a base letter and then the digits:
<code><i>width</i>'<i>base</i><i>digits</i></code>.

| Base letter | Means | Card 10 printed |
|---|---|---|
| `b` | binary | `4'b1010=10` |
| `d` | decimal | `4'd10=1010` |
| `h` | hexadecimal | `4'hA=1010` |
| `o` | octal | `4'o12=1010` |

All four literals put the same value on the same four wires. The base only changes how you write
the number down, and the wires carry no record of which base you used.

| Shorthand | What it is | Card 10 printed |
|---|---|---|
| `'0` | every bit 0, as wide as it needs to be | `'0=00000000` |
| `'1` | every bit 1, as wide as it needs to be | `'1=11111111` |
| `10` | a bare number, 32 bits wide | `bare 10 is 32 bits wide, value 10` |
| `8'b1010_1010` | underscores change nothing; they only make the number easier to read | `8'b1010_1010=170` |

Always write the width, which means `1'b0` and `1'b1` for single bits. An unsized literal is 32
bits wide, and it brings all 32 bits into whatever expression you put it in.

### 11 · Widths

The left-hand side decides how wide the arithmetic is. Card 11 assigns the same expression to two
destinations:

```systemverilog
assign narrow = a + b;      // narrow is logic [3:0]
assign wide   = a + b;      // wide   is logic [4:0]
```

For `a = 9`, `b = 9`:

```
11_width_truncation: 9+9 -> narrow[3:0]=2  wide[4:0]=18
```

In binary, `18` is `10010`, which takes five bits. `narrow` has only four, so the addition is done four
bits wide and the top bit never exists. `10010` without its top bit is `0010`, which is 2, the
same as 18 − 16 = 2.

No tool warns you about this. `make lint` puts card 11's mistake alone in a file and gives it to
two more tools:

```bash
make lint
```

```
    iverilog  exit 0 -- and it printed nothing at all
    verilator exit 0 -- the three lines above are its run report,
                       not a warning. -Wall found nothing to say.
```

Icarus says nothing, Verilator says nothing even with `-Wall`, and Yosys builds the file. The code
is legal SystemVerilog that happens to mean something other than what you meant, so you are the
only one who can catch the mistake.

> Adding two $N$-bit numbers needs an $N+1$-bit destination. If you want the carry, give it room.

That is why `ripple4` declares `logic [4:0] c;` for the five carries of its four adders, and why
the testbenches compare against `{cout, sum}` rather than `sum` alone.

### 12 · Testbench only

None of these become hardware. They exist so that the testbench can drive inputs and report what
comes out.

| | |
|---|---|
| `` `timescale 1ns/1ps `` | what `#10` means, and the precision times are recorded at |
| `initial begin … end` | runs once, at the start; it means nothing in a design, but every testbench needs one |
| `#10` | wait 10 time units. In a design file, delay is [silently discarded](https://uoftasic.com/dd103/reference/synthesizable-subset.html) |
| `$display`, `$write` | print a line / print without a newline |
| `$timeformat(-9, 0, " ns", 6)` | print `%0t` times as `20 ns` instead of `20000` |
| `$dumpfile("x.vcd")` / `$dumpvars(0, tb)` | the two lines that make a waveform file |
| `$finish` | stops the simulation; without it, `vvp` can sit there forever |

Card 12 also prints two lines that the table at the top of this page leaves out, and both are
normal:

```
VCD info: dumpfile card12.vcd opened for output.
../src/12_testbench_only.sv:25: $finish called at 20000 (1ps)
```

The second is `$finish` reporting the time in picoseconds, the precision set by
`` `timescale 1ns/1ps ``. `$timeformat` affects only `%0t` inside your own `$display` calls, so
your line says `20 ns` and this one says `20000`: the same instant, in two different units.

## Not used in DD102

We didn't leave these out because they are advanced. You don't need any of them to finish this
course, and each one is a place to get lost.

| | Where it belongs |
|---|---|
| `always_ff`, `posedge clk`, `<=` | anything with memory, which DD102's adder doesn't have and DD103's elevator does |
| `wire` / `reg` | the older spellings, which `logic` replaces; [DD103](https://uoftasic.com/dd103/reference/synthesizable-subset.html) explains the history |
| `always @*` | `always_comb` with the safety check switched off |
| `typedef enum`, `struct`, `interface`, `package` | ways to organize a design bigger than one adder |
| `function`, `task` | DD103, along with the fact that `return` doesn't work in Yosys. (The Lab 02 testbench calls a `task` named `check`, but you never have to write one.) |
| `unique`, `priority` | promises to the optimizer that no tool checks |
| `real`, `$random`, assertions | DD104 |

## If it won't compile

The refusals you'll meet, with the exact text Icarus prints and which line to believe, are in
[Icarus error messages](../reference/when-icarus-says-syntax-error.md). In short: the first error is
the real one, and everything printed under it follows from that first error.

## Where these came from

- [From your drawing to a module](../guide/from-your-drawing-to-a-module.md): cards 1–3
- [Modules and instances](../guide/what-a-module-is.md): card 7
- [`assign` and `always_comb`](../guide/assign-and-always-comb.md): cards 3–6
- [Vectors, generate loops and parameters](../guide/four-adders-in-a-row.md): cards 2, 7–9 and 11
- [Waveforms](../guide/two-lines-make-the-waveform-appear.md): card 12, and
  [Reading a waveform](../reference/reading-a-waveform.md) for what to do with the file
