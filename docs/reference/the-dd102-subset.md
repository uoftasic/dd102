# The DD102 subset

A lookup card for the exact spelling of the thing you want to write. Find your construct, copy
the shape, move on.

DD102 uses twelve pieces of SystemVerilog, and that is the whole list. The language has hundreds
more and you'll meet them later; none of them is needed to transcribe a drawing, prove it and put
it on an FPGA.

## Running the cards

Each card below is a complete file, not a fragment, and every one ships in
[`labs/reference-card/`](https://github.com/uoftasic/dd102/tree/main/labs/reference-card):

```bash
cd /foss/designs/modules/dd102/labs/reference-card
make
```

```
VERDICT PASS  — all 12 cards match the reference run.
```

It takes about 0.3 seconds and needs no `.designinit`, `mod`, PDK or environment variables. If a
line on this page doesn't match what your machine prints, `make` tells you which one, in the same
words this page uses.

These outputs came from Icarus Verilog 14.0 in `hpretl/iic-osic-tools:2026.08`. Check yours with
`iverilog -V`; the first line should be:

```
Icarus Verilog version 14.0 (devel) (s20260301-391-g64f13540-dirty)
```

That is the first of 73 lines; the rest is the GPL, which is normal. [Lab 01, Part 1](labs/lab-01-transcribe-your-adder-overview.md)
has the details.

## The twelve

| # | Construct | What it is | It printed |
|---|---|---|---|
| 1 | `module` … `endmodule` | a box with labelled edges; the labels are your drawing's labels | `a=1 b=1 y=1` |
| 2 | `logic`, `logic [3:0]` | the only type you need, one bit or several | `a=1001 y=0110 a[3]=1 a[2:1]=00` |
| 3 | `assign` with `& \| ^ ~` | a soldered connection, evaluated always | `and=0 or=1 xor=1 not_a=0` |
| 4 | `{cout, sum}` | glue bits into one wider bus | `{cout=1, sum=2} = 10010 = 18` |
| 5 | `always_comb` + `if`/`else` | the same hardware, said in words instead of expressions | `sel=1 -> 9   sel=0 -> 4` |
| 6 | `case` … `default:` | a truth table you can read | `00->0001 01->0010 10->0100 11->1000` |
| 7 | `full_adder fa0 (.a(x), …);` | putting a module inside a module | `1+1+1 -> cout=1 sum=1 (= 3)` |
| 8 | `genvar` + `generate for` | write one instance, get four | `9+9+0 -> cout=1 sum=2 (= 18)` |
| 9 | `parameter int N = 4` | one file, every width | `N=4 -> 00001111   N=6 -> 00111111` |
| 10 | `4'b1010`, `4'd10`, `4'hA` | how to write a number | `4'b1010=10  4'd10=1010  4'hA=1010` |
| 11 | width rules | the left side decides; the trap | `9+9 -> narrow[3:0]=2  wide[4:0]=18` |
| 12 | `` `timescale ``, `$display`, `$dumpfile`, `$finish` | testbench only, never hardware | `at 20 ns, a=1 y=0` |

Run one card on its own:

```bash
make card N=11
```

```
--- src/11_width_truncation.sv
11_width_truncation: 9+9 -> narrow[3:0]=2  wide[4:0]=18
```

## The shapes

### 1 · `module` and the port list

The port list is the edge of your drawing, typed out: direction, then type, then name.

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

Ports of the same direction and type can share a line: `input logic a, b, cin;`.
[`errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors) has the file
that shows a module isn't a function you can call.

### 2 · `logic`, and wires with no port

Signals that have a name on your drawing but don't reach the edge are declared inside the module,
before you use them:

```systemverilog
logic ha1_sum, ha1_carry, ha2_carry;
```

`logic [3:0] a` is four wires in a bundle. `a[3]` is one of them; `a[2:1]` is two. Numbering runs
`[high:low]`, and `[3:0]` is the order every file in this course uses.

> Leave the declaration out and nothing complains. Icarus compiles it, simulates it and gets the
> right answer; Yosys builds it and warns. The file that shows this is
> [`errors/undeclared_wire.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/errors/undeclared_wire.sv).
> Every name inside a module is either a port or a `logic` line; if it is neither, it is a typo.

### 3 · `assign`

`assign` is a wire, not a statement. It doesn't mean "do this now"; it means "these two things are
the same, permanently".

| You write | It means |
|---|---|
| `assign y = a & b;` | And |
| `assign y = a \| b;` | Or |
| `assign y = a ^ b;` | Xor |
| `assign y = ~a;` | Not |

Everything happens at once, so the order of your `assign` lines doesn't matter. Write them in the
order the signal travels, because that is easiest to read.

Two `assign`s aimed at the same signal are an error, not an overwrite. So are one `assign` and one
`always_comb` writing the same signal. Both refusals are in
[`errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors), and
[`assign` and `always_comb`](guide/assign-and-always-comb.md) explains why.

### 5 · `always_comb`

The same hardware as `assign`, spelled differently. Use it when the logic is easier to say in
sentences than in one expression. Inside it you use `=`, not `<=`, and you may use `if`/`else` and
`case`.

```systemverilog
always_comb begin
    if (sel) out = x;
    else     out = y;
end
```

The `else` isn't optional, and Icarus won't tell you so. The shipped
[`errors/forgot_a_branch.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/errors/forgot_a_branch.sv)
is a full adder whose `always_comb` only assigns its outputs when `cin` is 1:

```bash
cd /foss/designs/modules/dd102/labs/guide-examples
iverilog -g2012 -o /dev/null errors/forgot_a_branch.sv ; echo "iverilog exit=$?"
```

```
iverilog exit=0
```

Not a word. Yosys, on the same file:

```bash
yosys -p "read_verilog -sv errors/forgot_a_branch.sv; synth -top forgot_a_branch"
```

```
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process
       `\forgot_a_branch.$proc$errors/forgot_a_branch.sv:10$1'.
```

Exit code 1. A circuit that doesn't say what `sum` is when `cin` is 0 has to remember the old
value, and remembering is a latch: real hardware you didn't ask for. `always_comb` is worth using
because Yosys will refuse this; `always @*` isn't checked at all.

> Every output of an `always_comb` gets a value on every path. If you wrote an `if`, write the
> `else`; if you wrote a `case`, write the `default`.

The whole story, with three ways to lose a latch, is DD103's
[The latch you didn't ask for](https://uoftasic.com/dd103/#/guide/the-latch-you-didnt-ask-for).

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

Nothing loops in silicon. The loop runs once, while the tool reads your file, and leaves four full
adders behind. To see what that costs on an iCE40:

```bash
make synth
```

```
=== ripple4 ===
   13 cells
    4   $scopeinfo
    9   SB_LUT4
```

Nine `SB_LUT4`, exactly what four hand-written instances cost, because it is four instances. The
four `$scopeinfo` are bookkeeping, not hardware. A `generate for` is a typing shortcut, never a
discount. (The note `make synth` prints under the table still says "Eight SB_LUT4"; the count above
it is the current one.)

Two things about the label after `begin :`:

- `begin : slice` names the copies `slice[0]`, `slice[1]` and so on. Yosys, nextpnr and the
  waveform viewer all use those names.
- Don't call it `bit`. `bit` is a type keyword. Yosys says
  `syntax error, unexpected TOK_LOGIC, expecting TOK_ID`, and Icarus does something worse:

  ```
  errors/ripple4_bit.sv:7: assert: pform.cc:1575: failed assertion lexical_scope == cur_module
  Aborted (core dumped)
  ```

  Exit code 134. That is a crash in the compiler, not a diagnosis of your file. The shipped
  [`errors/ripple4_bit.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/errors/ripple4_bit.sv)
  lets you cause it once on purpose so it doesn't confuse you later.

> A crash with `assert:` and `core dumped` in it is a bug in the tool. Look at the line number it
> named, and suspect a name, not your logic.

`i = i + 1` and `i++` both work here and synthesize to the same 9 `SB_LUT4`. Somebody will tell
you otherwise;
[`errors/ripple4_incr.sv`](https://github.com/uoftasic/dd102/blob/main/labs/lab-04-four-adders-in-a-row/errors/ripple4_incr.sv)
is shipped so you can settle it.

### 10 · Literals

The shape is <code><i>width</i>'<i>base</i><i>digits</i></code>.

| Base letter | Means | Card 10 printed |
|---|---|---|
| `b` | binary | `4'b1010=10` |
| `d` | decimal | `4'd10=1010` |
| `h` | hexadecimal | `4'hA=1010` |
| `o` | octal | `4'o12=1010` |

All four are the same four wires. The base is how you write it down; the wires don't know.

| Shorthand | What it is | Card 10 printed |
|---|---|---|
| `'0` | every bit 0, as wide as it needs to be | `'0=00000000` |
| `'1` | every bit 1, as wide as it needs to be | `'1=11111111` |
| `10` | a bare number, 32 bits wide | `bare 10 is 32 bits wide, value 10` |
| `8'b1010_1010` | underscores are free, and only for your eyes | `8'b1010_1010=170` |

Write the width: `1'b0` and `1'b1` for single bits, always. An unsized literal is 32 bits and
brings its 32 bits into whatever expression you put it in.

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

`18` is `10010`, five bits. `narrow` has four, so the top bit never existed, and `10010` without
its top bit is `0010`, which is 2: 18 − 16 = 2.

Nothing warns you. Card 11's mistake, alone in a file, shown to two more tools:

```bash
make lint
```

```
    iverilog  exit 0 -- and it printed nothing at all
    verilator exit 0 -- the three lines above are its run report,
                       not a warning. -Wall found nothing to say.
```

Icarus is silent, Verilator with `-Wall` is silent, and Yosys builds it. This is legal
SystemVerilog that means something other than what you meant, and only you can catch it.

> Adding two $N$-bit numbers needs an $N+1$-bit destination. If you want the carry, give it room.

That is why `ripple4` declares `logic [4:0] c;` for four carries, and why the testbenches compare
against `{cout, sum}` rather than `sum` alone.

### 12 · Testbench only

None of these become hardware. They exist so the testbench can drive inputs and report.

| | |
|---|---|
| `` `timescale 1ns/1ps `` | what `#10` means, and the precision times are recorded at |
| `initial begin … end` | runs once, at the start. Meaningless in a design, essential in a testbench |
| `#10` | wait 10 time units. In a design file, delay is [silently discarded](https://uoftasic.com/dd103/#/reference/synthesizable-subset) |
| `$display`, `$write` | print a line / print without a newline |
| `$timeformat(-9, 0, " ns", 6)` | print `%0t` times as `20 ns` instead of `20000` |
| `$dumpfile("x.vcd")` / `$dumpvars(0, tb)` | the two lines that make a waveform file |
| `$finish` | stop. Without it, `vvp` can sit there forever |

Card 12 prints two lines this page's table leaves out, and both are normal:

```
VCD info: dumpfile card12.vcd opened for output.
../src/12_testbench_only.sv:25: $finish called at 20000 (1ps)
```

The second is `$finish` reporting the time in picoseconds, the precision from
`` `timescale 1ns/1ps ``. `$timeformat` only affects `%0t` inside your own `$display` calls. Same
instant, two units.

## Not used in DD102

These aren't left out because they are advanced. You don't need them to finish this course, and
each one is a place to get lost.

| | Where it belongs |
|---|---|
| `always_ff`, `posedge clk`, `<=` | anything with memory. DD102's adder has none; DD103's elevator does |
| `wire` / `reg` | the older spellings. `logic` replaces both. [DD103](https://uoftasic.com/dd103/#/reference/synthesizable-subset) explains the history |
| `always @*` | `always_comb` with the safety check switched off |
| `typedef enum`, `struct`, `interface`, `package` | ways to organize a design bigger than one adder |
| `function`, `task` | DD103, along with the fact that `return` doesn't work in Yosys |
| `unique`, `priority` | promises to the optimizer that nothing checks |
| `real`, `$random`, assertions | DD104 |

## If it won't compile

The refusals you'll meet, with the exact text Icarus prints and which line to believe, are in
[Icarus error messages](reference/when-icarus-says-syntax-error.md). In short: the first error is
the real one, and everything under it is fallout.

## Where these came from

- [From your drawing to a module](guide/from-your-drawing-to-a-module.md): cards 1–4
- [`assign` and `always_comb`](guide/assign-and-always-comb.md): cards 3 and 5
- [Vectors, generate loops and parameters](guide/four-adders-in-a-row.md): cards 7–9 and 11
- [Waveforms](guide/two-lines-make-the-waveform-appear.md): card 12, and
  [Reading a waveform](reference/reading-a-waveform.md) for what to do with the file
