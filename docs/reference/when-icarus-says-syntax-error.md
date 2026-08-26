# When Icarus says syntax error

**Question this page answers:** *The tool printed five red lines and I only made one mistake.
Which one do I believe?*

**The first one. Always the first one.**

Everything under the first error is usually the parser guessing, and its guesses can describe
constructs you never wrote. Read from the top, fix one thing, run again. Error counts in Verilog
are not a measure of how wrong you are — [Everything happens at
once](guide/assign-and-always-comb.md) shows a one-line mistake producing five errors, three of
which are fiction.

This page is a decoder. Find the text you are looking at, and read across.

> **Every message on this page was produced by a file that ships with the course.** They are in
> [`labs/guide-examples/syntax/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/syntax),
> they are broken on purpose, and `make syntax` in that package reproduces the lot with exit
> codes. Nothing in that folder is meant to compile — that is the point of it.
>
> ```bash
> cd labs/guide-examples
> make syntax
> ```

## The three rules, before the table

**1. `iverilog` without `-g2012` is not a SystemVerilog compiler.** Every command in DD102 says
`iverilog -g2012`. If yours does not, see the last row of the table — the error you get says
nothing at all about the missing flag.

**2. The error is often on the line *after* the mistake.** A missing semicolon is not detectable
until the parser reaches something that cannot follow. Look at the reported line, and then look
at the line above it.

**3. `syntax error` is a different kind of failure from `error:`.** `syntax error` means the
parser could not read your file. Lines beginning `error:` mean it read the file fine and did not
like what it said. The second kind is usually easier.

## The table

| What you see | What it means | What to look at |
|---|---|---|
| `syntax error` then `I give up.` | The parser hit something it cannot read and stopped. Nothing after this was checked. | The reported line, **and the line above it** |
| `error: Unknown module type: X` | You instantiated `X` and no file defining `X` was compiled | Your `iverilog` command line — a filename is missing |
| ``error: port ``x'' is not a port of inst`` | The port name in `.x(...)` is not spelled that way in the module | The module's own port list |
| `error: No function named ...` | You wrote `module_name(a, b)` as if it returned a value | You want an instance and a wire, not a call |
| `error: Cannot perform procedural assignment to variable 'y' because it is also continuously assigned` | `y` is driven by both an `assign` and an `always_comb` | Pick one. One signal, one driver |
| `error: Variable 'y' cannot have multiple drivers` | Two `always` blocks write `y` | Same rule, different spelling of the same mistake |
| `error: Syntax error in continuous assignment` | An `if` or a statement inside an `assign` | Use `? :`, or switch the whole thing to `always_comb` |
| `Invalid module instantiation` / `generate else is missing matching if` | **Usually fiction.** Fallout from an earlier error | Scroll up. Fix the first message only |
| **Nothing at all, exit 0** | Icarus is satisfied. That is not the same as correct | See [Silence is not a pass](#silence-is-not-a-pass) |

## The refusals, one at a time

### A missing semicolon points at the next line

[`syntax/01_missing_semicolon.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/01_missing_semicolon.sv),
complete as shipped — the mistake is on **line 4**:

```systemverilog
module missing_semicolon (input logic a, input logic b, output logic y);
    assign y = a & b
endmodule
```

```
syntax/01_missing_semicolon.sv:5: syntax error
I give up.
```

**Line 5 is `endmodule`, and there is nothing wrong with it.** The parser was still reading your
`assign` when `endmodule` arrived, and `endmodule` cannot appear in the middle of an expression.
That is the moment it noticed, not the moment you erred.

> **The reflex:** on any `syntax error`, check the reported line *and the one above it*. Roughly
> every second one is a semicolon on the line above.

### No `endmodule` points past the end of the file

[`syntax/02_missing_endmodule.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/02_missing_endmodule.sv)
is five lines long:

```
syntax/02_missing_endmodule.sv:6: syntax error
I give up.
```

**There is no line 6.** The file ended while the parser was still waiting for something, so it
reports the position where it ran out. A line number one past the end of your file almost always
means an unclosed `module`, `begin`, or `case`.

### Keywords are lowercase

[`syntax/03_capital_module.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/03_capital_module.sv)
says `Module` instead of `module`:

```
syntax/03_capital_module.sv:3: syntax error
I give up.
```

SystemVerilog is case-sensitive and every keyword is lowercase. `Module`, `Always_comb`,
`EndModule` and `Assign` are all just identifiers as far as the parser is concerned, and none of
them can start a file.

### `Unknown module type` is a command-line problem

[`syntax/04_unknown_module.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/04_unknown_module.sv)
instantiates `half_adder` without compiling a file that defines one:

```
syntax/04_unknown_module.sv:5: error: Unknown module type: half_adder
2 error(s) during elaboration.
*** These modules were missing:
        half_adder referenced 1 times.
***
```

**This is almost never a bug in your RTL.** Icarus compiles exactly the files you name and does
not go looking for others. You wrote

```bash
iverilog -g2012 -o sim.vvp tb.sv ripple4.sv
```

and forgot `full_adder.sv` on the end. The `*** These modules were missing:` block is Icarus
listing precisely which filenames you owe it — it is the most helpful error message in this
entire course, and it looks alarming for no reason.

### `is not a port of` is a spelling problem

[`syntax/05_wrong_port_name.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/05_wrong_port_name.sv)
defines a `half_adder` whose second output is called `carry`, and then wires it as `cout`:

```
syntax/05_wrong_port_name.sv:9: error: port ``cout'' is not a port of ha.
1 error(s) during elaboration.
```

Note that it names **`ha`**, your instance, not `half_adder`, the module. Go and read the port
list of the module you are instantiating; the name it wants is written there. Note also the
double-backtick-double-quote around `cout` — that is Icarus's quoting style, not corruption.

### The one that never mentions the real cause

[`syntax/06_needs_g2012.sv`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/syntax/06_needs_g2012.sv)
is **correct SystemVerilog**. Compile it the way every DD102 command does and it is fine:

```bash
iverilog -g2012 -o /dev/null syntax/06_needs_g2012.sv     # exit 0, silent
```

Drop the flag — the same file, not one character changed:

```
syntax/06_needs_g2012.sv:7: syntax error
syntax/06_needs_g2012.sv:7: error: Invalid module instantiation
I give up.
```

Line 7 is `always_comb`. Plain `iverilog` defaults to an older Verilog standard in which
`always_comb` does not exist, so the parser reads `always_comb begin` as somebody instantiating a
module of type `always_comb` — hence *"Invalid module instantiation"*, an error about a construct
you did not write.

**Nothing in that output contains the word `-g2012`, or `SystemVerilog`, or `standard`.**

> **The reflex:** if a file that should be fine produces `syntax error` on a line containing
> `always_comb`, `logic`, `always_ff`, or `int`, check your command line for `-g2012` before you
> change one character of your RTL.

## Silence is not a pass

The failure mode that costs the most time does not print anything.

**`iverilog` exit 0 means "I could read and elaborate this."** It does not mean the design is
right, and there are two mistakes it will accept without comment. Both ship in
[`labs/guide-examples/errors/`](https://github.com/uoftasic/dd102/tree/main/labs/guide-examples/errors)
and `make errors` runs them:

**An undeclared wire.** `errors/undeclared_wire.sv` is `src/full_adder.sv` with the
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

Both tools exit 0. Only one of them says anything, and it says it as a warning. Here the design
happens to be correct anyway — but the same silence covers a **typo in a signal name**, which
quietly creates a brand-new one-bit wire connected to nothing.

**A hole in an `always_comb`.** `errors/forgot_a_branch.sv` describes what the outputs are when
`cin` is 1 and says nothing about `cin` being 0:

```
--- errors/forgot_a_branch.sv  (Icarus first)
    iverilog exit 0 - not one word about it
--- errors/forgot_a_branch.sv  (now Yosys)
    yosys exit 1
ERROR: Latch inferred for signal `\forgot_a_branch.\sum' from always_comb process ...
```

**Icarus exit 0. Yosys exit 1.** Same file. A simulator's job is to run what you wrote; a
synthesizer's job is to build it, and only one of those jobs notices that you asked for memory
inside a block named `comb`.

> **The reflex, and it is the most valuable line on this page:** *a simulator passing is not a
> tool telling you the design is right.* Two cheap second opinions, both already installed:
>
> ```bash
> verilator --lint-only -Wall your_file.sv
> yosys -p "read_verilog -sv your_file.sv; synth -top your_module"
> ```
>
> Run them before you are confused, not after.

## Do not pipe the compiler

Errors go to **stderr**; `|` only carries **stdout**. So a pipe does not hide the messages — it
hides the *verdict*. Here is the same broken file, piped and unpiped:

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

**Identical output. `exit 0` and `exit 2`.** The status you got back belonged to `head`, which
succeeded, not to `iverilog`, which failed. Anything reading that exit code — a `Makefile`, a
script, a `&&` — has just been told your build was fine.
[Getting started](guide/getting-started.md) makes a related point about `iverilog -V`.

**Run the compiler unpiped.** If you must capture it, capture both:

```bash
iverilog -g2012 -o sim.vvp tb.sv dut.sv > build.log 2>&1; echo "exit $?"
```

## Exit codes you will see

Icarus returns the number of errors, not a flag, so the value is informative rather than a
verdict:

| Exit | Seen from |
|---|---|
| `0` | compiled — see [Silence is not a pass](#silence-is-not-a-pass) |
| `1` | one elaboration error, e.g. the wrong port name |
| `2` | a `syntax error` that ended in `I give up.`, or two elaboration errors |
| `3` | the missing `-g2012` case above |
| `5` | the `if` inside an `assign` — one mistake, five messages |

**A bigger number does not mean a bigger problem.** Five errors from one misplaced `if` is the
normal shape of a parser losing its place.

## Still stuck?

Post in the [team Discord](https://discord.gg/hrJnP5UsGz) with three things and you will get an
answer in minutes:

1. **The first error line, as text**, not a screenshot and not a summary
2. **The exact command you ran**, including the filenames
3. **The line the error names, and the one above it**

Related: [The DD102 subset](reference/the-dd102-subset.md) is every construct this course uses,
with a runnable card for each — if a construct is not on that card, DD102 never asks you to write
it. [Everything happens at once](guide/assign-and-always-comb.md) is where the one-driver rule and
the latch trap are explained rather than merely listed.
