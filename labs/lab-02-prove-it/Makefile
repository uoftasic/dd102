# Lab 02 -- Prove it
# Runs inside hpretl/iic-osic-tools:2026.08 (Icarus Verilog 14.0, Python 3.12.3).
# No PDK, no liberty file, no environment variables. `make` alone is enough.
#
#   make            your testbench vs. one good adder and three broken ones
#   make good       only the working adder
#   make mutants    only the three broken adders
#   make reference  the same sweep, using reference/tb_full_adder.sv
#   make grade      same as `make`, but exits 1 until every box is ticked
#   make clean      empty results/

RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_verdict.py
TB    := tb/tb_full_adder.sv

MUTANTS := mut1_cin_ignored mut2_carry_needs_all_three mut3_outputs_swapped

.PHONY: all good mutants summary reference grade clean

all: reset good mutants summary

reset: | $(RES)
	@rm -f $(RES)/scoreboard.txt

## good -- your testbench against a full adder that works
good: | $(RES)
	@echo "=============================================================="
	@echo " 1. YOUR TESTBENCH vs. A WORKING ADDER  (src/full_adder.sv)"
	@echo "=============================================================="
	$(IV) -o $(RES)/good.vvp $(TB) src/full_adder.sv
	@vvp $(RES)/good.vvp | tee $(RES)/good.txt
	@echo ""
	@$(CHECK) $(RES)/good.txt --expect pass --label "src/full_adder.sv" || true

## mutants -- your testbench against three adders that are broken on purpose
mutants: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. YOUR TESTBENCH vs. THREE BROKEN ADDERS"
	@echo "    Each of these is a complete file in mutants/ with exactly"
	@echo "    one thing wrong. Your testbench should say FAIL on all three."
	@echo "=============================================================="
	@for m in $(MUTANTS); do \
	  echo ""; \
	  echo "--- mutants/$$m.sv ---"; \
	  $(IV) -o $(RES)/$$m.vvp $(TB) mutants/$$m.sv; \
	  vvp $(RES)/$$m.vvp | tee $(RES)/$$m.txt; \
	  $(CHECK) $(RES)/$$m.txt --expect fail --label "mutants/$$m.sv" || true; \
	done

summary:
	@echo ""
	@$(CHECK) --summary || true

## reference -- the shipped answer, through the identical sweep
reference: | $(RES)
	@rm -f $(RES)/scoreboard.txt
	@echo "=============================================================="
	@echo " reference/tb_full_adder.sv through the identical sweep"
	@echo "=============================================================="
	$(IV) -o $(RES)/ref_good.vvp reference/tb_full_adder.sv src/full_adder.sv
	@vvp $(RES)/ref_good.vvp > $(RES)/ref_good.txt
	@$(CHECK) $(RES)/ref_good.txt --expect pass --label "src/full_adder.sv" || true
	@for m in $(MUTANTS); do \
	  $(IV) -o $(RES)/ref_$$m.vvp reference/tb_full_adder.sv mutants/$$m.sv; \
	  vvp $(RES)/ref_$$m.vvp > $(RES)/ref_$$m.txt; \
	  $(CHECK) $(RES)/ref_$$m.txt --expect fail --label "mutants/$$m.sv" || true; \
	done
	@echo ""
	@$(CHECK) --summary || true

## grade -- an exit status a script can read
grade: reset good mutants
	@$(CHECK) --summary

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.vvp $(RES)/*.txt
