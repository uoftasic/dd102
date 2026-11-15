# Icarus error messages

Icarus printed five red lines and you made one mistake. Believe the first one.

Everything under the first error is usually the parser guessing, and its guesses can describe
constructs you never wrote. Read from the top, fix one thing, and run again. Error counts in
Verilog don't measure how wrong you are:
[`assign` and `always_comb`](../guide/assign-and-always-comb.md) shows a one-line mistake producing
five errors, three of which describe things that aren't there.

This page is a decoder. Find the text you are looking at and read across.

> Every message on this page was produced by a file that ships with the course. They are in
> [`labs/guide-examples/syntax/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/syntax),
> they are broken on purpose, and `make syntax` in that package reproduces them all with exit
> codes. Nothing in that folder is meant to compile.
>
> ```bash
> cd labs/guide-examples
> make syntax
> ```

## Three rules

1. `iverilog` without `-g2012` isn't a SystemVerilog compiler. Every command in DD102 says
   `iverilog -g2012`. If yours doesn't, see the last row of the table: the error you get says
   nothing about the missing flag.
2. The error is often on the line after the mistake. A missing semicolon can't be detected until
   the parser reaches something that can't follow it. Look at the reported line, then at the line
   above it.
3. `syntax error` is a different kind of failure from `error:`. `syntax error` means the parser
   couldn't read your file. Lines beginning `error:` mean it read the file and didn't like what it
   said. The second kind is usually easier.

## The table

| What you see | What it means | What to look at |
|---|---|---|
| `syntax error` then `I give up.` | The parser hit something it can't read and stopped. Nothing after this was checked. | The reported line, and the line above it |
| `error: Unknown module type: X` | You instantiated `X` and no file defining `X` was compiled | Your `iverilog` command line: a file name is missing |
| ``error: port ``x'' is not a port of inst`` | The port name in `.x(...)` isn't spelled that way in the module | The module's own port list |
| `error: No function named ...` | You wrote `module_name(a, b)` as if it returned a value | You want an instance and a wire, not a call |
| `error: Cannot perform procedural assignment to variable 'y' because it is also continuously assigned` | `y` is driven by both an `assign` and an `always_comb` | Pick one. One signal, one driver |
| `error: Variable 'y' cannot have multiple drivers` | Two drivers write `y` | The same rule, spelled differently |
| `error: Syntax error in continuous assignment` | An `if` or a statement inside an `assign` | Use `? :`, or switch the whole thing to `always_comb` |
| `Invalid module instantiation` / `generate else is missing matching if` | Usually fallout from an earlier error | Scroll up and fix the first message only |
| Nothing at all, exit 0 | Icarus is satisfied. That isn't the same as correct | See [When Icarus says nothing](#when-icarus-says-nothing) |

## The messages one at a time

### Missing semicolon

[`syntax/01_missing_semicolon.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/01_missing_semicolon.sv),
as shipped. The mistake is on line 4:

```systemverilog
module missing_semicolon (input logic a, input logic b, output logic y);
    assign y = a & b
endmodule
```

```
syntax/01_missing_semicolon.sv:5: syntax error
I give up.
```

Line 5 is `endmodule`, and nothing is wrong with it. The parser was still reading your `assign`
when `endmodule` arrived, and `endmodule` can't appear in the middle of an expression. Line 5 is
where it noticed, not where you erred. On any `syntax error`, check the reported line and the one
above it; roughly every second one is a semicolon on the line above.

### Missing `endmodule`

[`syntax/02_missing_endmodule.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/02_missing_endmodule.sv)
is five lines long:

```
syntax/02_missing_endmodule.sv:6: syntax error
I give up.
```

There is no line 6. The file ended while the parser was still waiting for something, so it
reports the position where it ran out. A line number one past the end of your file almost always
means an unclosed `module`, `begin` or `case`.

### Capitalised keyword

[`syntax/03_capital_module.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/03_capital_module.sv)
says `Module` instead of `module`:

```
syntax/03_capital_module.sv:3: syntax error
I give up.
```

SystemVerilog is case-sensitive and every keyword is lowercase. `Module`, `Always_comb`,
`EndModule` and `Assign` are just identifiers to the parser, and none of them can start a file.

### `Unknown module type`

[`syntax/04_unknown_module.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/04_unknown_module.sv)
instantiates `half_adder` without compiling a file that defines one:

```
syntax/04_unknown_module.sv:5: error: Unknown module type: half_adder
2 error(s) during elaboration.
*** These modules were missing:
        half_adder referenced 1 times.
***
```

This is almost never a bug in your RTL. Icarus compiles exactly the files you name and doesn't
go looking for others. You wrote

```bash
iverilog -g2012 -o sim.vvp tb.sv ripple4.sv
```

and forgot `full_adder.sv` on the end. The `*** These modules were missing:` block lists exactly
which modules you still owe it. It is the most helpful error message in this course, and it looks
alarming for no reason.

### `is not a port of`

[`syntax/05_wrong_port_name.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/05_wrong_port_name.sv)
defines a `half_adder` whose second output is called `carry`, and then wires it as `cout`:

```
syntax/05_wrong_port_name.sv:9: error: port ``cout'' is not a port of ha.
syntax/05_wrong_port_name.sv:9: error: port ``cout'' is not a port of ha.
2 error(s) during elaboration.
```

Icarus reports the same error twice. It names `ha`, your instance, not `half_adder`, the module.
Read the port list of the module you are instantiating; the name it wants is written there. The
double-backtick-double-quote around `cout` is Icarus's quoting style, not corruption.

### Missing `-g2012`

[`syntax/06_needs_g2012.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/06_needs_g2012.sv)
is correct SystemVerilog. Compiled the way every DD102 command does it, it is fine:

```bash
iverilog -g2012 -o /dev/null syntax/06_needs_g2012.sv     # exit 0, silent
```

Drop the flag, without changing a character of the file:

```
syntax/06_needs_g2012.sv:7: syntax error
syntax/06_needs_g2012.sv:7: error: Invalid module instantiation
I give up.
```

Line 7 is `always_comb`. Plain `iverilog` defaults to an older Verilog standard in which
`always_comb` doesn't exist, so the parser reads `always_comb begin` as someone instantiating a
module of type `always_comb`; hence "Invalid module instantiation", an error about a construct you
didn't write. Nothing in that output contains `-g2012`, `SystemVerilog` or `standard`.

> If a file that should be fine gives `syntax error` on a line containing `always_comb`, `logic`,
> `always_ff` or `int`, check your command line for `-g2012` before you change any of your RTL.

## When Icarus says nothing

The failure that costs the most time prints nothing. `iverilog` exit 0 means "I could read and
elaborate this". It doesn't mean the design is right, and it accepts two mistakes without comment.
Both ship in [`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors),
and `make errors` runs them.

An undeclared wire. `errors/undeclared_wire.sv` is `src/full_adder.sv` with the
`logic ha1_sum, ha1_carry, ha2_carry;` line deleted:

```
--- errors/undeclared_wire.sv  (Icarus first)
    iverilog exit 0 - silent
--- errors/undeclared_wire.sv  (now Yosys)
    yosys exit 0
errors/undeclared_wire.sv:13: Warning: Identifier `\ha1_sum' is implicitly declared.
errors/undeclared_wire.sv:14: Warning: Identifier `\ha1_carry' is implicitly declared.
errors/undeclared_wire.sv:16: Warning: Identifier `\ha2_carry' is implicitly declared.
```

Both tools exit 0, only one says anything, and it says it as a warning. Here the design happens to
be correct anyway, but the same silence covers a typo in a signal name, which quietly creates a new
one-bit wire connected to nothing.

A hole in an `always_comb`. `errors/forgot_a_branch.sv` says what the outputs are when `cin` is 1
and nothing about `cin` being 0:

```
--- errors/forgot_a_branch.sv  (Icarus first)
    iverilog exit 0 - not one word about it
--- errors/forgot_a_branch.sv  (now Yosys)
    yosys exit 1
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process ...
```

Icarus exits 0 and Yosys exits 1 on the same file. A simulator's job is to run what you wrote; a
synthesizer's job is to build it, and only the second notices that you asked for memory inside a
block named `comb`.

> A simulator passing isn't a tool telling you the design is right. Two cheap second opinions are
> already installed:
>
> ```bash
> verilator --lint-only -Wall your_file.sv
> yosys -p "read_verilog -sv your_file.sv; synth -top your_module"
> ```
>
> Run them before you are confused, not after.

## Piping the compiler

Errors go to stderr, and `|` only carries stdout. So a pipe doesn't hide the messages; it hides
the exit status. The same broken file, piped and unpiped:

```bash
iverilog -g2012 -o /dev/null syntax/01_missing_semicolon.sv | head -3; echo "exit $?"
iverilog -g2012 -o /dev/null syntax/01_missing_semicolon.sv;           echo "exit $?"
```

```
syntax/01_missing_semicolon.sv:5: syntax error
I give up.
exit 0
syntax/01_missing_semicolon.sv:5: syntax error
I give up.
exit 2
```

The output is identical, and the exit statuses are 0 and 2. The status you got back from the pipe
belonged to `head`, which succeeded, not to `iverilog`, which failed. Anything reading that exit
code (a `Makefile`, a script, a `&&`) has just been told your build was fine.
[Lab 01, Part 1](../labs/lab-01-transcribe-your-adder-overview.md) makes a related point about
`iverilog -V`.

Run the compiler unpiped. If you need to capture its output, capture both streams:

```bash
iverilog -g2012 -o sim.vvp tb.sv dut.sv > build.log 2>&1; echo "exit $?"
```

## Exit codes

Icarus returns a count, not a flag, so the value tells you something but isn't a verdict:

| Exit | Seen from |
|---|---|
| `0` | compiled; see [When Icarus says nothing](#when-icarus-says-nothing) |
| `1` | one elaboration error, e.g. two `assign`s driving the same signal |
| `2` | a `syntax error` that ended in `I give up.`, or two elaboration errors (the unknown module type and the wrong port name both report two) |
| `3` | the missing `-g2012` case above |
| `5` | the `if` inside an `assign`: one mistake, five messages |

A bigger number doesn't mean a bigger problem. Five errors from one misplaced `if` is the normal
shape of a parser losing its place.

## Still stuck?

Post in the [team Discord](https://discord.gg/hrJnP5UsGz) with three things:

1. the first error line, as text, not a screenshot or a summary
2. the exact command you ran, including the file names
3. the line the error names, and the one above it

Related: [The DD102 subset](../reference/the-dd102-subset.md) lists every construct this course uses,
with a runnable card for each; if a construct isn't on that list, DD102 never asks you to write
it. [`assign` and `always_comb`](../guide/assign-and-always-comb.md) explains the one-driver rule and
the latch trap rather than only listing them.
