# The three services

**Question this page answers:** *Which tab do I need, what does it cost me, and what do I do
when one of them is down?*

DD102 leans on three websites that nobody on this team runs. They are free, they are good, and
**none of them owes you an SLA.** One is a university lecturer's side project, one is run by a
training company, one is one person. Any of them can be down on the night you sit down to work.

That is fine, and this page is why: **every single thing they do for you, your workbench also
does.** The browser tabs are faster and prettier. They are not load-bearing.

> **Everything on this page was checked by loading the site on 2026-08-25.** Versions and quoted
> text are what the sites served that day. Version numbers on somebody else's server change
> without notice; if yours disagree, the site moved, not you.

## At a glance

| | [DigitalJS Online](https://digitaljs.tilk.eu/) | [EDA Playground](https://www.edaplayground.com/) | [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page) |
|---|---|---|---|
| **What it is for here** | see your text as a clickable schematic | run a testbench and share the exact run | drill problems, graded against a reference |
| **Account?** | **none** | **Google login to press Run** | none to solve; optional to remember |
| **Cost** | free | free | free |
| **Who runs it** | Marek Materzok, University of Wrocław | Doulos | Henry Wong |
| **Runs where** | **in your browser** (WebAssembly) | on their servers | on their servers |
| **Used in** | Lab 01, Lab 02 | Lab 02, Lab 03, and every Discord question | optional, between labs |
| **If it is down** | `yosys scripts/digitaljs.ys` | `make` in any lab package | nothing replaces it — and nothing needs it |

## DigitalJS Online

**<https://digitaljs.tilk.eu/>**

Paste SystemVerilog, press **Run**, switch from the **`</>` Code** tab to the **Circuit** tab,
and click on your own gates. The site describes itself:

> *"This is a demonstration app for the DigitalJS digital logic simulator and the
> yosys2digitaljs netlist format converter, by Marek Materzok, University of Wrocław. … This
> was made possible by the Yosys open-source hardware synthesis framework."*

It is **Yosys compiled to WebAssembly, running in your tab** — the **Synthesis mode** setting
says `WebAssembly (faster and local)`, and it means that literally. There is a second setting,
`Server side (legacy, works with older browsers)`, which does send your code away; you will not
need it.

Worth knowing about three of its checkboxes, because each maps onto something you already know:

| Checkbox | What it does |
|---|---|
| **Convert to logic gates → Map into subset of gates** | tick `NAND` and nothing else, and watch your adder rebuild itself out of the one gate DD101 built everything from |
| **Map into LUTs** | the FPGA question, four courses early — see [The chip is already there](guide/the-chip-is-already-there.md) |
| **Lint source code using Verilator** | a second opinion on your file, in the browser |

### The trap: its Yosys is not your Yosys, and it moves

DigitalJS's synthesis worker loads Yosys at run time from
`https://cdn.jsdelivr.net/npm/@yowasp/yosys/gen/bundle.js` — **with no version in the URL.**
Whatever is newest is what you get. On 2026-08-25 that resolved to **0.65.176-dev.1145**,
against your workbench's **0.64**.

> **Reflex: use DigitalJS for the *picture*, never for the *count*.** No lab in DD102 asks you
> to compare a DigitalJS cell count against a workbench cell count. If you do it yourself and
> the numbers differ, that is not a bug in either one.
>
> It also means the site can break for you while `digitaljs.tilk.eu` itself is perfectly up,
> because the code it needs comes from a *different* server.

### The workbench does this too

```bash
cd /foss/designs/modules/dd102/labs/guide-examples
yosys scripts/digitaljs.ys
```

```
=== full_adder ===
    5 cells
    2   $and
    1   $or
    2   $xor
```

Exit 0, and `results/full_adder_rtl.svg` — the same five boxes, drawn by the same synthesizer,
in a file you own. The script is
[`scripts/digitaljs.ys`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/scripts/digitaljs.ys),
and its command list is copied out of yosys2digitaljs itself, so the picture is the picture
DigitalJS would have drawn. What you give up is the clicking.

## EDA Playground

**<https://www.edaplayground.com/>**

Two editor tabs with fixed names — **`design.sv`** and **`testbench.sv`** — a simulator
dropdown, a **Run** button, and a **Log** pane. Its front page states the account rule:

> *"You can start typing straight away. But to run your code, you'll need to sign or log in.
> Logging in with a Google account gives you access to all non-commercial simulators and some
> commercial simulators."*

**This is the only account the entire DD track asks you for.** You can read, edit, and share
without it; only **Run** needs it. If you would rather not, nothing in DD102 breaks — every
simulation it can run, your workbench runs too. What you lose is the permalink, and that is a
real loss when you need help at 2 a.m.

The simulator dropdown, on 2026-08-25:

| Free simulator listed | Version |
|---|---|
| Icarus Verilog | **12.0** |
| Verilator | v5.044 |
| Yosys | **0.37** |
| GHDL | 5.1.1 |

Your workbench runs Icarus **14.0**, Verilator **5.046**, Yosys **0.64**. For everything DD102
asks you to write this makes no difference — but see
[Two lines make the waveform appear](guide/two-lines-make-the-waveform-appear.md) for the one
place where 12.0 says `sorry:` and 14.0 does not.

Checkboxes on the left that matter:

- **Open EPWave after run** — without this ticked there is no waveform window, no matter what
  your testbench dumps. **And EPWave opens in a new browser window, so a pop-up blocker eats it
  silently.**
- **Download files after run** — how you get the `.vcd` onto your own machine.

### It is a scratchpad, not a synthesizer

Its Yosys is **0.37** and there is no SKY130 liberty file anywhere on it. That is fine for
`synth` and `stat`; it is useless for the thing DD103 is about. Do not plan on doing chip work
here.

### The workbench does this too

Everything EPWave shows you, GTKWave and Surfer show you — see
[Reading a waveform](reference/reading-a-waveform.md):

```bash
cd /foss/designs/modules/dd102/labs/guide-examples-proving-it
make            # five verdicts, about 0.4 s
make wave       # GTKWave, signals already added
make surfer     # the same file in Surfer
```

**What the workbench cannot replace is the permalink.** When EDA Playground is down and you
need help, post to [Discord](https://discord.gg/hrJnP5UsGz): the file, the exact command you
ran, and the first error line. Not a screenshot of a screen, and not a paraphrase.

## HDLBits

**<https://hdlbits.01xz.net/wiki/Main_Page>**

Small problems; you write a module and the site checks it:

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

**No account is needed to solve problems.** One exists only so your progress follows you:

> *"If you want to track your progress or move to another browser, create a username and
> password so you can log in from elsewhere."*

There is no score and no percentage anywhere on it — it counts problems you have finished and
stops there. That is deliberate, and it is why DD102 is willing to point at it.

It is not a random internet site. From its About page:

> *"HDLBits was created by Henry Wong, who spent 7 years as a teaching assistant in digital
> logic and computer organization (ECE243, ECE253, and ECE241) during his Ph.D. studies at the
> University of Toronto."*

Those are the courses many of you are walking into.

On 2026-08-25 its problem list carried **182** problems. Two of its sections are DD102 and DD104
in miniature: **Finding bugs in code** (5 problems) and **Build a circuit from a simulation
waveform** (10 problems, `sim/circuit1` through `sim/circuit10`).

It calls its language **Verilog**, not SystemVerilog. Everything DD102 taught you sits inside
what it accepts.

### There is no local HDLBits, and you do not need one

This is the one service with no workbench equivalent, because what it gives you is *somebody
else's testbench* and *problems you did not write*. Nothing in DD102 requires it — it is
optional on every page that mentions it.

What you can do instead, and what is worth more anyway: **write the testbench yourself.** That
is [Lab 03 — The lazy testbench](labs/lab-03-the-lazy-testbench-overview.md), and after it you can grade
your own work on any problem statement you already have open. Both self-checking packages
render a verdict with no network at all:

```bash
cd labs/reference-card            && make    # VERDICT PASS — all 12 cards
cd labs/guide-examples-proving-it && make    # five PASS lines
```

## Is it down, or is it me?

None of the three publishes a status page. The check is one command, and `curl` is in the
workbench:

```bash
curl -sS -o /dev/null -w "digitaljs %{http_code}\n" https://digitaljs.tilk.eu/
curl -sS -o /dev/null -w "playground %{http_code}\n" https://www.edaplayground.com/
curl -sS -o /dev/null -w "hdlbits %{http_code}\n" https://hdlbits.01xz.net/wiki/Main_Page
```

On 2026-08-25, from inside `hpretl/iic-osic-tools:2026.04`:

```
digitaljs 200
playground 200
hdlbits 200
```

| What you get | What it means |
|---|---|
| `200` | the site is up. The problem is your browser, your login, or your file |
| `502`, `503`, `504` | their server. Nothing you can do; use the workbench and try later |
| `000` | `curl` never got an answer — **your** network, or DNS |
| `403` | you are being blocked, not the site being down |

**`ping` is not installed in this image.** `command not found` there is not a broken container.

> **Reflex: before you spend an hour re-typing a file, spend three seconds on `curl`.**

## What is actually at risk

Being honest about it, because you are going to build habits on these tools:

| | |
|---|---|
| **DigitalJS** | source is [BSD-2 on GitHub](https://github.com/tilk/digitaljs_online) and runs client-side, so it is the most survivable of the three. Its weak point is not the site — it is the unpinned Yosys it fetches from a CDN |
| **EDA Playground** | a free service from a commercial training company, gated behind one Google login. If it ever went away, DD102 would lose the permalink and nothing else |
| **HDLBits** | one person, no funding model, running since before you started. Everything DD102 uses it for is optional, which is the only sensible way to depend on it |

The reason this page exists is the reason none of that keeps you up at night: **DD102's actual
deliverable — a transcribed `ripple4.sv`, proven on all 512 of its inputs, and a
104,090-byte bitstream — is produced entirely inside a container you already have on your
disk.** The browser is a convenience. Treat it that way and nothing on the internet can stop
you finishing this course.

Next, if you have not read it: [Reading a waveform](reference/reading-a-waveform.md) — what to
do with the window once EPWave or GTKWave finally shows you one.
