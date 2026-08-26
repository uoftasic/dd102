# Guide examples — every runnable file the guide pages print
# Runs inside hpretl/iic-osic-tools:2026.04 (Icarus 14.0, Yosys 0.64, Python 3.12).
# No environment setup. No `.designinit`. Just `make`.
#
#   make            everything, in order, ending in a verdict
#   make sim        your adder against the eight rows of your DD101 table
#   make broken     the same testbench against a deliberately wrong adder
#   make spellings  four ways to write this adder, driven side by side
#   make area       what each spelling costs in sky130 silicon
#   make backwards  the same five lines in reverse order. Still passes.
#   make picture    the schematic Yosys draws, as an SVG (needs `dot`)
#   make errors     six files that misbehave on purpose, and what the tools say
#   make luts       what four inputs cost on an FPGA, and what five cost
#   make syntax     six refusals, with the exact text Icarus prints
#   make table      reprint the verdict from JSON you already have
#   make clean      empty results/, keep sources

SRC   := src
RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_area.py

.PHONY: all sim broken spellings backwards area picture errors luts syntax table clean

all: sim broken spellings backwards area luts table

## sim — the lab's main event: your module, your eight rows
sim: | $(RES)
	@echo "=============================================================="
	@echo " 1. YOUR ADDER AGAINST YOUR OWN TRUTH TABLE"
	@echo "=============================================================="
	$(IV) -o $(RES)/sim.vvp $(SRC)/tb_full_adder.sv $(SRC)/full_adder.sv
	@vvp $(RES)/sim.vvp | tee $(RES)/sim.log
	@grep -q "^PASS" $(RES)/sim.log

## broken — read a FAIL you caused on purpose
broken: | $(RES)
	@echo "=============================================================="
	@echo " 2. THE DELIBERATE FAILURE"
	@echo "    broken/full_adder.sv is src/full_adder.sv with one & where"
	@echo "    the drawing has an Or. Same testbench, no edits."
	@echo "=============================================================="
	@$(IV) -o $(RES)/broken.vvp $(SRC)/tb_full_adder.sv broken/full_adder.sv
	@vvp $(RES)/broken.vvp | tee $(RES)/broken.log
	@echo "    vvp exited $$(vvp $(RES)/broken.vvp >/dev/null 2>&1; echo $$?). Yes. Zero."
	@echo "    A simulator that finds a bug still exits 0. Read the verdict line,"
	@echo "    or make something else read it for you -- that is why the rule"
	@echo "    above this one is 'grep -q ^PASS'."

## spellings — four modules, one truth table, zero disagreements
spellings: | $(RES)
	@echo "=============================================================="
	@echo " 3. FOUR SPELLINGS OF THE SAME ADDER"
	@echo "=============================================================="
	@$(IV) -o $(RES)/spell.vvp $(SRC)/tb_spellings.sv $(SRC)/full_adder.sv \
	    $(SRC)/full_adder_flat.sv $(SRC)/full_adder_table.sv \
	    $(SRC)/full_adder_hier.sv $(SRC)/half_adder.sv
	@vvp $(RES)/spell.vvp | tee $(RES)/spell.log
	@grep -q "^PASS" $(RES)/spell.log

## backwards — assign order is not execution order
backwards: | $(RES)
	@echo "=============================================================="
	@echo " 3b. THE SAME FIVE LINES, WRITTEN BACKWARDS"
	@echo "=============================================================="
	@$(IV) -o $(RES)/back.vvp $(SRC)/tb_backwards.sv $(SRC)/full_adder_backwards.sv
	@vvp $(RES)/back.vvp | tee $(RES)/back.log
	@grep -q "^PASS" $(RES)/back.log

## area — what each spelling costs, in square micrometres of sky130
area: | $(RES)
	@echo "=============================================================="
	@echo " 4. WHAT EACH SPELLING COSTS"
	@echo "    Predict first: is the five-assign version bigger than the"
	@echo "    two-assign version? Write down yes or no before you look."
	@echo "=============================================================="
	yosys scripts/area.ys > $(RES)/area.log 2>&1
	@grep -E "^---- |Chip area for (module|top module)" $(RES)/area.log

## picture — the schematic, drawn by the same Yosys the browser runs
picture: | $(RES)
	yosys scripts/digitaljs.ys > $(RES)/digitaljs.log 2>&1
	@awk '/^=== full_adder ===/{p=1} /^9\. Generating/{p=0} p' $(RES)/digitaljs.log | grep -E "cells|^ +[0-9]+ +\\$$"
	@echo "wrote $(RES)/full_adder_rtl.svg -- open it in a browser"

## errors — six ways to be wrong, and the exact text you get
errors: | $(RES)
	@echo "=============================================================="
	@echo " SIX FILES THAT MISBEHAVE ON PURPOSE"
	@echo "=============================================================="
	@echo "--- errors/call_it_like_a_function.sv"
	-@$(IV) -o /dev/null errors/call_it_like_a_function.sv $(SRC)/full_adder.sv
	@echo "--- errors/two_drivers.sv"
	-@$(IV) -o /dev/null errors/two_drivers.sv
	@echo "--- errors/if_inside_assign.sv"
	-@$(IV) -o /dev/null errors/if_inside_assign.sv
	@echo "--- errors/both_ways_at_once.sv  (Icarus first)"
	-@$(IV) -o /dev/null errors/both_ways_at_once.sv
	@echo "--- errors/both_ways_at_once.sv  (now Yosys)"
	-@yosys -p "read_verilog -sv errors/both_ways_at_once.sv; synth -top both_ways_at_once" \
	    > $(RES)/bothways.log 2>&1; echo "    yosys exit $$?"
	@grep "multiple conflicting drivers" $(RES)/bothways.log
	@echo "--- errors/undeclared_wire.sv  (Icarus first)"
	@$(IV) -o /dev/null errors/undeclared_wire.sv && echo "    iverilog exit 0 - silent"
	@echo "--- errors/undeclared_wire.sv  (now Yosys)"
	-@yosys -p "read_verilog -sv errors/undeclared_wire.sv; synth -top undeclared_wire" \
	    > $(RES)/implicit.log 2>&1; echo "    yosys exit $$?"
	@grep "implicitly declared" $(RES)/implicit.log
	@echo "--- errors/forgot_a_branch.sv  (Icarus first)"
	@$(IV) -o /dev/null errors/forgot_a_branch.sv && echo "    iverilog exit 0 - not one word about it"
	@echo "--- errors/forgot_a_branch.sv  (now Yosys)"
	-@yosys -p "read_verilog -sv errors/forgot_a_branch.sv; synth -top forgot_a_branch" \
	    > $(RES)/latch.log 2>&1; echo "    yosys exit $$?"
	@grep "^ERROR" $(RES)/latch.log

## luts — cost on an FPGA is input count, not complexity
luts: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 7. WHAT A LOOKUP TABLE CHARGES YOU FOR"
	@echo "    Three unrelated 4-input functions, then one 5-input AND."
	@echo "=============================================================="
	@for m in lut_simple lut_parity lut_weird lut_five; do \
	    yosys -p "read_verilog -sv $(SRC)/$$m.sv; synth_ice40 -top $$m; stat" \
	        > $(RES)/$$m.log 2>&1; \
	    n=$$(awk "/=== $$m ===/{k++} k>=2" $(RES)/$$m.log \
	        | awk '/SB_LUT4/{print $$1}'); \
	    printf "  %-12s %s SB_LUT4\n" "$$m" "$$n"; \
	    echo "$$m $$n" >> $(RES)/luts.txt; \
	done
	@echo ""
	@python3 $(SRC)/check_luts.py $(RES)/luts.txt

## syntax — the refusals, with exit codes. Not part of `all`: it is a reference.
syntax:
	@echo "=============================================================="
	@echo " SIX REFUSALS. Every message on the reference page, reproduced."
	@echo "=============================================================="
	@for f in syntax/0*.sv; do \
	    echo ""; echo "--- $$f"; \
	    $(IV) -o /dev/null $$f 2>&1 || true; \
	    $(IV) -o /dev/null $$f >/dev/null 2>&1; echo "    iverilog -g2012 exit $$?"; \
	done
	@echo ""
	@echo "--- syntax/06_needs_g2012.sv WITHOUT -g2012 (the same file)"
	-@iverilog -o /dev/null syntax/06_needs_g2012.sv 2>&1
	@iverilog -o /dev/null syntax/06_needs_g2012.sv >/dev/null 2>&1; echo "    iverilog exit $$?"
	@echo ""
	@echo "Every one of these is in docs/reference/when-icarus-says-syntax-error.md"
	@echo "with what it means. Nothing here is expected to compile except 06 with -g2012."

## table — the verdict, from JSON you already produced
table:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR NUMBERS"
	@echo "=============================================================="
	@$(CHECK) --table $(RES)/drawing.json $(RES)/flat.json $(RES)/table.json \
	    $(RES)/half.json $(RES)/boxes.json $(RES)/boxes_flat.json

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.log $(RES)/*.json $(RES)/*.vvp $(RES)/*.svg $(RES)/*.dot
