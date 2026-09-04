# Lab 03 -- The lazy testbench
# Runs inside hpretl/iic-osic-tools:2026.08 (Icarus Verilog 14.0, Python 3.12.3).
# No PDK, no liberty file, no environment variables. `make` alone is enough.
#
#   make            all three stages, in order. Run this one.
#   make lazy       stage 1 -- your hand-picked cases. It passes.
#   make exhaustive stage 2 -- all 512. It does not.
#   make fixed      stage 3 -- one extra wire, all 512 again.
#   make trap       the plausible fix that changes nothing, and the one
#                   command that catches it. Not part of `make`.
#   make lint       verilator -Wall on all three designs. Not part of `make`.
#   make reference  stage 1 with the shipped six cases instead of yours
#   make grade      the same three stages, with an exit status
#   make clean      empty results/

RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_run.py

.PHONY: all reset lazy exhaustive fixed summary trap lint reference grade clean

all: reset lazy exhaustive fixed summary

reset: | $(RES)
	@rm -f $(RES)/scoreboard.txt

## lazy -- stage 1: the cases a person picks
lazy: | $(RES)
	@echo "=============================================================="
	@echo " 1. THE TESTBENCH YOU WROTE  --  tb/tb_lazy.sv"
	@echo "=============================================================="
	$(IV) -o $(RES)/lazy.vvp tb/tb_lazy.sv src/add4.sv src/full_adder.sv
	@vvp $(RES)/lazy.vvp | tee $(RES)/lazy.txt
	@echo ""
	@$(CHECK) $(RES)/lazy.txt --stage lazy || true
	@echo ""
	@echo "    Before you run the next stage, commit to a number:"
	@echo "    of add4's 512 possible inputs, how many does it get WRONG?"
	@echo "    Write it down. ______"

## exhaustive -- stage 2: every input the design can ever see
exhaustive: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. THE SAME ADDER, ALL 512 INPUTS  --  tb/tb_exhaustive.sv"
	@echo "=============================================================="
	$(IV) -o $(RES)/all512.vvp tb/tb_exhaustive.sv src/add4.sv src/full_adder.sv
	@vvp $(RES)/all512.vvp | tee $(RES)/all512.txt
	@echo ""
	@$(CHECK) $(RES)/all512.txt --stage exhaustive || true

## fixed -- stage 3: one more wire out of the module
fixed: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 3. ONE EXTRA WIRE  --  reference/add5.sv, all 512 again"
	@echo "=============================================================="
	$(IV) -o $(RES)/fixed.vvp tb/tb_exhaustive_fixed.sv reference/add5.sv src/full_adder.sv
	@vvp $(RES)/fixed.vvp | tee $(RES)/fixed.txt
	@echo ""
	@$(CHECK) $(RES)/fixed.txt --stage fixed || true

summary:
	@echo ""
	@$(CHECK) --summary || true

## trap -- widening the wire inside the module fixes nothing
trap: | $(RES)
	@echo "=============================================================="
	@echo " broken/add4_wider_inside.sv -- five bits inside, four at the port"
	@echo "=============================================================="
	$(IV) -Wall -o $(RES)/trap.vvp tb/tb_exhaustive.sv broken/add4_wider_inside.sv src/full_adder.sv
	@vvp $(RES)/trap.vvp | tail -12
	@echo ""
	@echo "--- and the one command that would have told you ---"
	@verilator --lint-only -Wall --top-module add4 broken/add4_wider_inside.sv src/full_adder.sv; \
	  echo "exit status $$?"

## lint -- the same command on all three designs
lint:
	@for pair in "src/add4.sv add4" "broken/add4_wider_inside.sv add4" "reference/add5.sv add5"; do \
	  set -- $$pair; \
	  echo "=============================================================="; \
	  echo " verilator --lint-only -Wall --top-module $$2 $$1"; \
	  echo "=============================================================="; \
	  verilator --lint-only -Wall --top-module $$2 $$1 src/full_adder.sv; \
	  echo "exit status $$?"; echo ""; \
	done

## reference -- stage 1 with the shipped six cases, so you can see it pass
##             even if your own tb_lazy.sv will not compile
reference: | $(RES)
	@echo "=============================================================="
	@echo " reference/tb_lazy.sv  --  six cases, none of them out of range"
	@echo "=============================================================="
	$(IV) -o $(RES)/ref_lazy.vvp reference/tb_lazy.sv src/add4.sv src/full_adder.sv
	@vvp $(RES)/ref_lazy.vvp | tee $(RES)/ref_lazy.txt
	@echo ""
	@$(CHECK) $(RES)/ref_lazy.txt --stage lazy || true

## grade -- an exit status a script can read
grade: reset lazy exhaustive fixed
	@$(CHECK) --summary

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.vvp $(RES)/*.txt
