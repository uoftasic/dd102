# The browser tools

Which tab you need, what it costs you, and what to do when one is down.

DD102 uses three websites that nobody on this team runs. They are free and good, and none of them
owes you any uptime. One is a university lecturer's side project, one is run by a training company
and one by a single person, and any of them can be down on the night you sit down to work. That is
fine, because everything they do for you, your workbench also does, apart from HDLBits, which
nothing in DD102 requires. The browser tabs are faster and nicer to use; the course doesn't depend
on them.

> Everything on this page was checked by loading the sites on 2026-08-25. Versions and quoted text
> are what the sites served that day. Version numbers on somebody else's server change without
> notice; if yours disagree, the site moved, not you.

## At a glance

| | [DigitalJS Online](https://digitaljs.tilk.eu/) | [EDA Playground](https://www.edaplayground.com/) | [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page) |
|---|---|---|---|
| What it is for here | see your text as a clickable schematic | run a testbench and share the exact run | drill problems, graded against a reference |
| Account? | none | Google login to press Run | none to solve; optional to remember progress |
| Cost | free | free | free |
| Who runs it | Marek Materzok, University of Wrocław | Doulos | Henry Wong |
| Runs where | in your browser (WebAssembly) | on their servers | on their servers |
| Used in | Lab 01 (Part 5, and Going further), Lab 05 (Going further) | Lab 03 (Going further), and any Discord question | optional practice between labs |
| If it is down | `yosys scripts/digitaljs.ys` | `make` in any lab package | nothing replaces it, and nothing needs it |

## DigitalJS Online

**<https://digitaljs.tilk.eu/>**

Paste SystemVerilog, press **Run**, switch from the **`</>` Code** view to the **Circuit** view on
a narrow screen, and click on your own gates. The site describes itself:

> *"This is a demonstration app for the DigitalJS digital logic simulator and the
> yosys2digitaljs netlist format converter, by Marek Materzok, University of Wrocław. … This
> was made possible by the Yosys open-source hardware synthesis framework."*

It is Yosys compiled to WebAssembly, running in your tab: the **Synthesis mode** setting says
`WebAssembly (faster and local)` and means it literally. A second setting, `Server side (legacy,
works with older browsers)`, does send your code away; you won't need it.

Three of its checkboxes map onto things you already know:

| Checkbox | What it does |
|---|---|
| Convert to logic gates → Map into subset of gates | tick `NAND` and nothing else, and watch your adder rebuild itself out of the one gate DD101 built everything from |
| Map into LUTs | what an FPGA does; see [Inside an FPGA](../guide/the-chip-is-already-there.md) |
| Lint source code using Verilator | a second opinion on your file, in the browser |

### Its Yosys version

DigitalJS's synthesis worker loads Yosys at run time from
`https://cdn.jsdelivr.net/npm/@yowasp/yosys/gen/bundle.js`, with no version in the URL, so you get
whatever is newest. On 2026-08-25 that was 0.65.176-dev.1145, against your workbench's 0.68.

> Use DigitalJS for the picture, never for the count. No lab in DD102 asks you to compare a
> DigitalJS cell count with a workbench cell count. If you do and the numbers differ, that isn't a
> bug in either one.
>
> It also means the site can break for you while `digitaljs.tilk.eu` itself is up, because the
> code it needs comes from a different server.

### Workbench equivalent

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

It exits 0 and writes `results/full_adder_rtl.svg`: the same five boxes, drawn by the same
synthesizer, in a file you own. The script is
[`scripts/digitaljs.ys`](https://github.com/uoftasic/dd102/blob/main/labs/guide-examples/scripts/digitaljs.ys),
and its command list is copied from yosys2digitaljs itself, so the picture is the one DigitalJS
would have drawn. What you give up is the clicking.

## EDA Playground

**<https://www.edaplayground.com/>**

Two editor tabs with fixed names, **`design.sv`** and **`testbench.sv`**, a simulator dropdown, a
**Run** button and a **Log** pane. Its front page states the account rule:

> *"You can start typing straight away. But to run your code, you'll need to sign or log in.
> Logging in with a Google account gives you access to all non-commercial simulators and some
> commercial simulators."*

This is the only account the DD track asks you for. You can read, edit and share without it; only
**Run** needs it. If you'd rather not have one, nothing in DD102 breaks, because everything it can
simulate your workbench simulates too. What you lose is the permalink, which matters when you need
help at 2 a.m.

The simulator dropdown on 2026-08-25:

| Free simulator listed | Version |
|---|---|
| Icarus Verilog | 12.0 |
| Verilator | v5.044 |
| Yosys | 0.37 |
| GHDL | 5.1.1 |

Your workbench runs Icarus 14.0, Verilator 5.050 and Yosys 0.68. For everything DD102 asks you to
write this makes no difference; [Waveforms](../guide/two-lines-make-the-waveform-appear.md) covers
the one place where 12.0 says `sorry:` and 14.0 doesn't.

Checkboxes on the left that matter:

- **Open EPWave after run**: without it there is no waveform window, whatever your testbench
  dumps. EPWave opens in a new browser window, so a pop-up blocker hides it silently.
- **Download files after run**: how you get the `.vcd` onto your own machine.

### No SKY130 library

Its Yosys is 0.37 and there is no SKY130 liberty file on it. That is fine for `synth` and `stat`
and useless for the work DD103 is about, so don't plan on doing chip work there.

### Workbench equivalent

Everything EPWave shows you, GTKWave and Surfer show you too; see
[Reading a waveform](../reference/reading-a-waveform.md):

```bash
cd /foss/designs/modules/dd102/labs/guide-examples-proving-it
make            # five verdicts, about 0.4 s
make wave       # GTKWave, signals already added
make surfer     # the same file in Surfer
```

The workbench can't replace the permalink. When EDA Playground is down and you need help, post to
[Discord](https://discord.gg/hrJnP5UsGz): the file, the exact command you ran, and the first error
line. Not a screenshot, and not a paraphrase.

## HDLBits

**<https://hdlbits.01xz.net/wiki/Main_Page>**

Small problems: you write a module and the site checks it.

> *"Your circuit is checked for correctness by simulating with a set of test vectors and
> comparing it to our reference solution."*

No account is needed to solve problems. One exists only so your progress follows you:

> *"If you want to track your progress or move to another browser, create a username and
> password so you can log in from elsewhere."*

There is no score or percentage on it; it counts problems you have finished and stops there.
That is part of why DD102 is willing to point at it. From its About page:

> *"HDLBits was created by Henry Wong, who spent 7 years as a teaching assistant in digital
> logic and computer organization (ECE243, ECE253, and ECE241) during his Ph.D. studies at the
> University of Toronto."*

Those are the courses many of you are walking into.

On 2026-08-25 its problem list had 182 problems. Two of its sections are DD102 and DD104 in
miniature: Finding bugs in code (5 problems) and Build a circuit from a simulation waveform
(10 problems, `sim/circuit1` to `sim/circuit10`). It calls its language Verilog, not
SystemVerilog; everything DD102 teaches sits inside what it accepts.

### No workbench equivalent

This is the one service with no workbench equivalent, because what it gives you is somebody
else's testbench and problems you didn't write. Nothing in DD102 requires it; it is optional on
every page that mentions it.

What you can do instead is write the testbench yourself, which is what
[Lab 02](../labs/lab-02-prove-it-overview.md) and [Lab 03](../labs/lab-03-the-lazy-testbench-overview.md)
teach. After them you can grade your own work on any problem statement you have. These two
self-checking packages give a verdict with no network at all (run each from the repo root):

```bash
cd labs/reference-card && make               # VERDICT PASS — all 12 cards
cd labs/guide-examples-proving-it && make    # five PASS lines
```

## Checking whether a site is down

None of the three publishes a status page. The check is one command each, and `curl` is in the
workbench:

```bash
curl -sS -o /dev/null -w "digitaljs %{http_code}\n" https://digitaljs.tilk.eu/
curl -sS -o /dev/null -w "playground %{http_code}\n" https://www.edaplayground.com/
curl -sS -o /dev/null -w "hdlbits %{http_code}\n" https://hdlbits.01xz.net/wiki/Main_Page
```

On 2026-08-25, from inside `hpretl/iic-osic-tools:2026.08`:

```
digitaljs 200
playground 200
hdlbits 200
```

| What you get | What it means |
|---|---|
| `200` | the site is up. The problem is your browser, your login or your file |
| `502`, `503`, `504` | their server. Nothing you can do; use the workbench and try later |
| `000` | `curl` never got an answer: your network, or DNS |
| `403` | you are being blocked, not the site being down |

`ping` isn't installed in this image, so `command not found` from it isn't a broken container.
Before you spend an hour retyping a file, spend three seconds on `curl`.

## Long-term risk

| | |
|---|---|
| DigitalJS | source is [BSD-2 on GitHub](https://github.com/tilk/digitaljs_online) and runs client-side, so it is the most likely of the three to survive. Its weak point is the unpinned Yosys it fetches from a CDN, not the site |
| EDA Playground | a free service from a commercial training company, behind one Google login. If it went away, DD102 would lose the permalink and nothing else |
| HDLBits | one person, no funding model, running since before you started. Everything DD102 uses it for is optional, which is the only sensible way to depend on it |

DD102's actual deliverable, a transcribed `ripple4.sv` proven on all 512 of its inputs and a
104,090-byte bitstream, is produced entirely inside a container already on your disk. The browser
is a convenience.

Next, if you haven't read it: [Reading a waveform](../reference/reading-a-waveform.md), for what to do
with the window once EPWave or GTKWave shows you one.
