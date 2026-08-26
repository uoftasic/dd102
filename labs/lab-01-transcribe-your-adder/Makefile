# Lab 01 -- Transcribe your adder
# Runs inside hpretl/iic-osic-tools:2026.04 (Icarus Verilog 14.0, Python 3.12.3).
# Nothing here reads a PDK, a liberty file, or an environment variable.
# `make` alone, in a bare container, is the whole story.
#
#   make            check the shipped answer, then check yours. Always exits 0.
#   make reference  only reference/full_adder.sv -- proves your toolchain works
#   make yours      only src/full_adder.sv -- the file you are writing
#   make lint       the dead end: Verilator's default lint, and the flag that
#                   makes it useful. Not part of `make`.
#   make grade      same as `make yours`, but exits 1 until you pass
#   make clean      empty results/

RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_table.py

.PHONY: all reference yours summary lint grade clean

all: reference yours summary

## reference -- the shipped answer, through the same printer and the same grader
reference: | $(RES)
	@echo "=============================================================="
	@echo " 1. THE SHIPPED ANSWER  --  reference/full_adder.sv"
	@echo "    If this does not say PASS, the problem is your setup."
	@echo "=============================================================="
	$(IV) -o $(RES)/reference.vvp tb/print_table.sv reference/full_adder.sv
	@vvp $(RES)/reference.vvp | tee $(RES)/reference.txt
	@echo ""
	@$(CHECK) $(RES)/reference.txt --label "reference/full_adder.sv"

## yours -- src/full_adder.sv, the file you edit
yours: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. YOUR FILE  --  src/full_adder.sv"
	@echo "=============================================================="
	@rm -f $(RES)/yours.vvp $(RES)/yours.txt
	@$(IV) -o $(RES)/yours.vvp tb/print_table.sv src/full_adder.sv \
	  > $(RES)/yours.build.log 2>&1 || true
	@if [ -s $(RES)/yours.build.log ]; then \
	  echo "--- iverilog had something to say about your file ---"; \
	  cat $(RES)/yours.build.log; echo ""; fi
	@if [ -f $(RES)/yours.vvp ]; then \
	  vvp $(RES)/yours.vvp | tee $(RES)/yours.txt; echo ""; \
	  $(CHECK) $(RES)/yours.txt --label "src/full_adder.sv (yours)" \
	    && echo PASS > $(RES)/yours.status || echo FAIL > $(RES)/yours.status; \
	else \
	  echo "FAIL -- src/full_adder.sv did not compile, so nothing ran."; \
	  echo "       The FIRST error line above is the real one. Everything"; \
	  echo "       after it is fallout from that one."; \
	  echo FAIL > $(RES)/yours.status; \
	fi

## summary -- one verdict, in one place
summary:
	@echo ""
	@echo "=============================================================="
	@echo " VERDICT"
	@echo "=============================================================="
	@if [ "`cat $(RES)/yours.status 2>/dev/null`" = PASS ]; then \
	  echo " reference/full_adder.sv : PASS  8/8"; \
	  echo " src/full_adder.sv       : PASS  8/8   <-- Lab 01 is done."; \
	  echo ""; \
	  echo " Now paste src/full_adder.sv into https://digitaljs.tilk.eu/ and"; \
	  echo " press Run. Compare the picture to your paper drawing."; \
	  echo " Then: labs/lab-02-prove-it/"; \
	else \
	  echo " reference/full_adder.sv : PASS  8/8   (so your toolchain is fine)"; \
	  echo " src/full_adder.sv       : FAIL        <-- this one is yours to write."; \
	  echo ""; \
	  echo " Open src/full_adder.sv. The assign lines are commented out."; \
	  echo " Your DD101 drawing already says what goes in them."; \
	fi
	@echo "=============================================================="

## lint -- the tool that looks like the right answer and says nothing
lint:
	@echo "=============================================================="
	@echo " verilator --lint-only src/full_adder.sv        (the default)"
	@echo "=============================================================="
	@verilator --lint-only src/full_adder.sv; echo "exit status $$?"
	@echo ""
	@echo "=============================================================="
	@echo " verilator --lint-only -Wall src/full_adder.sv  (one more flag)"
	@echo "=============================================================="
	@verilator --lint-only -Wall src/full_adder.sv; echo "exit status $$?"

## grade -- the same check, with an exit status a script can read
grade: yours
	@test "`cat $(RES)/yours.status 2>/dev/null`" = PASS

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.vvp $(RES)/*.txt $(RES)/*.log $(RES)/*.status
