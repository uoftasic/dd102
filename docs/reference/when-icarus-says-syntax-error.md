# Icarus error messages

When Icarus prints five red lines, you have usually made one mistake, and the first line is the
one to believe.

Everything under the first error is usually the parser guessing at what you meant, and its
guesses can describe constructs you never wrote. So read from the top, fix one thing, and run
again. The number of errors in Verilog doesn't tell you how wrong your file is:
[`assign` and `always_comb`](../guide/assign-and-always-comb.md) shows a one-line mistake that
produces five errors, three of which describe things that aren't in the file.

Use this page to look up a message: find the text you're looking at in the table, and read across
to see what it means and where to look.

> Every message on this page was produced by a file that ships with the course. The files are in
> [`labs/guide-examples/syntax/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/syntax),
> and they are broken on purpose, so nothing in that folder is meant to compile. Running
> `make syntax` in that package reproduces every message, along with its exit code.
>
> ```bash
> cd labs/guide-examples
> make syntax
> ```

## Three rules

1. `iverilog` compiles SystemVerilog only when you give it `-g2012`, which is why every command in
   DD102 says `iverilog -g2012`. If yours doesn't, see "Missing `-g2012`" further down this page,
   because the error you get says nothing about the missing flag.
2. The error is often reported on the line after the mistake. The parser can't detect a missing
   semicolon until it reaches something that can't follow it, so look at the reported line and
   then at the line above it.
3. `syntax error` is a different kind of failure from `error:`. `syntax error` means the parser
   couldn't read your file at all. A line beginning `error:` means it read the file and didn't
   like what the file said. The second kind is usually easier to fix.

## The table

| What you see | What it means | What to look at |
|---|---|---|
| `syntax error` then `I give up.` | The parser hit something it couldn't read and stopped, so nothing after that point was checked | The reported line, and the line above it |
| `error: Unknown module type: X` | You instantiated `X`, but no file defining `X` was compiled | Your `iverilog` command line, which is missing a file name |
| ``error: port ``x'' is not a port of inst`` | The module has no port spelled the way you wrote it in `.x(...)` | The module's own port list |
| `error: No function named ...` | You wrote `module_name(a, b)` as if the module returned a value | You want an instance and a wire, not a call |
| `error: Cannot perform procedural assignment to variable 'y' because it is also continuously assigned` | `y` is driven by both an `assign` and an `always_comb` | Pick one, since each signal gets one driver |
| `error: Variable 'y' cannot have multiple drivers` | Two drivers write `y` | The same one-driver rule, in different words |
| `error: Syntax error in continuous assignment` | You put an `if` or another statement inside an `assign` | Use `? :`, or move the whole thing into an `always_comb` |
| `Invalid module instantiation` / `generate else is missing matching if` | Usually fallout from an earlier error | Scroll up and fix only the first message |
| Nothing at all, exit 0 | Icarus is satisfied, which isn't the same as the design being correct | See [When Icarus says nothing](#when-icarus-says-nothing) |

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

Line 5 is `endmodule`, which is correct as written. The parser was still reading your `assign`
when `endmodule` arrived, and `endmodule` can't appear in the middle of an expression, so line 5
is where the parser noticed the problem rather than where you made it. On any `syntax error`,
check the reported line and the one above it; roughly every second time, the cause is a missing
semicolon on the line above.

### Missing `endmodule`

[`syntax/02_missing_endmodule.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/02_missing_endmodule.sv)
is five lines long:

```
syntax/02_missing_endmodule.sv:6: syntax error
I give up.
```

The file has no line 6. It ended while the parser was still waiting for something, so the parser
reports the position where it ran out of file. A line number one past the end of your file almost
always means an unclosed `module`, `begin` or `case`.

### Capitalised keyword

[`syntax/03_capital_module.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/03_capital_module.sv)
says `Module` instead of `module`:

```
syntax/03_capital_module.sv:3: syntax error
I give up.
```

SystemVerilog is case-sensitive and every keyword is lowercase, so to the parser `Module`,
`Always_comb`, `EndModule` and `Assign` are ordinary identifiers, and a file can't start with any
of them.

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
go looking for others, so the usual cause is a command line like this one:

```bash
iverilog -g2012 -o sim.vvp tb.sv ripple4.sv
```

where you forgot to put `full_adder.sv` on the end. The `*** These modules were missing:` block
lists exactly which modules Icarus still needs a file for. It looks alarming, but it's the most
helpful error message in this course.

### `is not a port of`

[`syntax/05_wrong_port_name.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/05_wrong_port_name.sv)
defines a `half_adder` whose second output is called `carry`, and then wires it as `cout`:

```
syntax/05_wrong_port_name.sv:9: error: port ``cout'' is not a port of ha.
syntax/05_wrong_port_name.sv:9: error: port ``cout'' is not a port of ha.
2 error(s) during elaboration.
```

Icarus reports the same error twice, and the name it gives is `ha`, your instance, rather than
`half_adder`, the module. The port name it wants is written in the port list of the module you're
instantiating, so read that. The two backticks before `cout` and the two single quotes after it
are just how Icarus quotes names; the output isn't corrupted.

### Missing `-g2012`

[`syntax/06_needs_g2012.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/06_needs_g2012.sv)
is correct SystemVerilog, and if you compile it the way every DD102 command does, Icarus accepts
it:

```bash
iverilog -g2012 -o /dev/null syntax/06_needs_g2012.sv     # exit 0, silent
```

Here is what you get if you drop the flag and leave every character of the file unchanged:

```
syntax/06_needs_g2012.sv:7: syntax error
syntax/06_needs_g2012.sv:7: error: Invalid module instantiation
I give up.
```

Line 7 is `always_comb`. Plain `iverilog` defaults to an older Verilog standard in which
`always_comb` doesn't exist, so the parser reads `always_comb begin` as someone instantiating a
module of type `always_comb`. That's where "Invalid module instantiation" comes from, an error
about a construct you didn't write. The output never mentions `-g2012`, `SystemVerilog` or
`standard`, so it gives you no hint that the missing flag is the problem.

> If a file that should be fine gives `syntax error` on a line containing `always_comb`, `logic`,
> `always_ff` or `int`, check your command line for `-g2012` before you change any of your RTL.

## When Icarus says nothing

The failure that costs you the most time is the one that prints nothing. When `iverilog` exits
with 0, it means "I could read and elaborate this", not that the design is right, and there are
two mistakes it accepts without comment. Both ship in
[`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors),
and `make errors` runs them.

The first is an undeclared wire. `errors/undeclared_wire.sv` is `src/full_adder.sv` with the
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

Both tools exit 0, and only Yosys says anything, as a warning. Here the design happens to be
correct anyway, because the implicitly declared wires are the ones you meant. The tools are
just as silent about a typo in a signal name, which creates a new one-bit wire connected to
nothing.

The second is a hole in an `always_comb`. `errors/forgot_a_branch.sv` says what the outputs are
when `cin` is 1 and says nothing about what they are when `cin` is 0:

```
--- errors/forgot_a_branch.sv  (Icarus first)
    iverilog exit 0 - not one word about it
--- errors/forgot_a_branch.sv  (now Yosys)
    yosys exit 1
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process ...
```

On the same file, Icarus exits 0 and Yosys exits 1. A simulator's job is to run what you wrote,
and a synthesizer's job is to build it, so only the synthesizer notices that you asked for memory
inside a block named `comb`.

> When a simulation passes, no tool has told you the design is right. Two cheap second opinions
> are already installed:
>
> ```bash
> verilator --lint-only -Wall your_file.sv
> yosys -p "read_verilog -sv your_file.sv; synth -top your_module"
> ```
>
> It's worth running them before you get confused rather than after.

## Piping the compiler

Icarus writes its errors to stderr, and `|` carries only stdout, so piping the compiler into
another command still shows you the messages on the terminal. What the pipe hides is the exit
status. Here is the same broken file compiled with and without a pipe:

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

The output is identical, but the exit statuses are 0 and 2. A pipeline returns the status of its
last command, so the 0 belonged to `head`, which succeeded, rather than to `iverilog`, which
failed. Anything that reads that exit code (a `Makefile`, a script, a `&&`) will conclude that
your build was fine.
[Lab 01, Part 1](../labs/lab-01-transcribe-your-adder-overview.md) makes a related point about
`iverilog -V`.

So run the compiler without a pipe, and if you need to keep its output, redirect both streams to
a file:

```bash
iverilog -g2012 -o sim.vvp tb.sv dut.sv > build.log 2>&1; echo "exit $?"
```

## Exit codes

Icarus's exit status is a count of errors rather than a simple pass/fail flag. The value tells
you something about what happened, but it doesn't measure how serious the mistake is. Here is where
each value has come from:

| Exit | Seen from |
|---|---|
| `0` | a file that compiled; see [When Icarus says nothing](#when-icarus-says-nothing) |
| `1` | one elaboration error, for example two `assign`s driving the same signal |
| `2` | a `syntax error` that ended in `I give up.`, or two elaboration errors (the unknown module type and the wrong port name both report two) |
| `3` | the missing `-g2012` case above |
| `5` | the `if` inside an `assign`, where one mistake produces five messages |

A bigger number doesn't mean a bigger problem. Five errors from one misplaced `if` is what it
normally looks like when a parser loses its place.

## Still stuck?

Post in the [team Discord](https://discord.gg/hrJnP5UsGz) with three things:

1. the first error line, as text, not a screenshot or a summary
2. the exact command you ran, including the file names
3. the line the error names, and the one above it

Two related pages: [The DD102 subset](../reference/the-dd102-subset.md) lists every construct this
course uses, with a runnable card for each, and if a construct isn't on that list, DD102 never
asks you to write it. [`assign` and `always_comb`](../guide/assign-and-always-comb.md) explains
why the one-driver rule and the latch trap exist, where this page only lists the errors they
cause.
