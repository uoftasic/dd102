# Guide examples — proving it works
# Every runnable file printed in the "Proving it" guide pages lives here.
# Runs inside hpretl/iic-osic-tools:2026.08 (Icarus Verilog 14.0, Python 3.12).
# No environment setup: no .designinit, no mod, no PDK, no liberty file.
#
#   make               everything below, in order, then the verdict table
#   make eight         a full adder against all 8 of its inputs        -> PASS
#   make eight-broken  the same testbench, an And where the Or was     -> FAIL 4/8
#   make six           six hand-picked cases on a BROKEN ripple adder  -> PASS  (!)
#   make sweep         all 512 inputs on that same broken adder        -> FAIL 256/512
#   make clue          the sweep again, with the per-input breakdown
#   make fixed         all 512 inputs on the repaired adder            -> PASS
#   make check         re-run the verdicts on logs you already have
#   make wave          GTKWave on the sweep    (needs the noVNC desktop)
#   make surfer        Surfer on the sweep     (needs the noVNC desktop)
#   make eight-bit     the SAME sweep on an 8-bit adder: 131072 vectors
#   make lint          ask Verilator what it thinks of both broken files
#   make clean         empty results/, keep sources

SRC   := src
RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_sim.py

.PHONY: all eight eight-broken six sweep clue fixed eight-bit check lint wave surfer clean

all: eight eight-broken six sweep fixed check

## eight — an exhaustive test that fits on one screen
eight: | $(RES)
	@echo "=============================================================="
	@echo " 1. EIGHT ROWS.  Every input a full adder can ever see."
	@echo "=============================================================="
	$(IV) -o $(RES)/eight.vvp $(SRC)/tb_eight_rows.sv $(SRC)/full_adder.sv
	@cd $(RES) && vvp eight.vvp | tee eight.log

## eight-broken — read a FAIL you caused on purpose
eight-broken: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. THE SAME TESTBENCH, on broken/full_adder.sv"
	@echo "    One & where the drawing has an Or. No syntax error."
	@echo "=============================================================="
	@$(IV) -o $(RES)/eight_broken.vvp $(SRC)/tb_eight_rows.sv broken/full_adder.sv
	@mkdir -p $(RES)/run
	@cd $(RES)/run && vvp ../eight_broken.vvp | tee ../eight_broken.log; \
	  echo "    vvp exited $$?. Yes. Zero. Read the verdict, not the exit code."
	@mv -f $(RES)/run/eight.vcd $(RES)/eight_broken.vcd && rmdir $(RES)/run

## six — the testbench a reasonable person writes in five minutes
six: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 3. SIX CASES SOMEBODY THOUGHT OF, on broken/ripple4.sv"
	@echo "    Write down now: how many of the six do you expect to fail?"
	@echo "=============================================================="
	@$(IV) -o $(RES)/six.vvp $(SRC)/tb_six_cases.sv broken/ripple4.sv $(SRC)/full_adder.sv
	@cd $(RES) && vvp six.vvp | tee six.log

## sweep — the same broken design, every input it can ever see
sweep: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 4. ALL 512 INPUTS, on the SAME broken/ripple4.sv"
	@echo "=============================================================="
	@$(IV) -o $(RES)/sweep.vvp $(SRC)/tb_sweep.sv broken/ripple4.sv $(SRC)/full_adder.sv
	@cd $(RES) && vvp sweep.vvp | tee sweep.log
	@echo ""
	@echo "    Before 'make clue': that count is a fraction of 512."
	@echo "    What does the fraction say about which input is involved?"

## clue — the breakdown that names the guilty input before you read any RTL
clue: sweep
	@echo ""
	@echo "=============================================================="
	@echo " 5. WHICH INPUT DOES THE DAMAGE FOLLOW?"
	@echo "=============================================================="
	@cd $(RES)/. && vvp sweep.vvp +clue | tail -11

## fixed — the repaired design, same 512 inputs
fixed: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 6. THE SAME 512 INPUTS, on src/ripple4.sv (the good one)"
	@echo "=============================================================="
	@$(IV) -o $(RES)/fixed.vvp $(SRC)/tb_sweep.sv $(SRC)/ripple4.sv $(SRC)/full_adder.sv
	@mkdir -p $(RES)/run
	@cd $(RES)/run && vvp ../fixed.vvp | tee ../fixed.log
	@mv -f $(RES)/run/sweep.vcd $(RES)/fixed.vcd && rmdir $(RES)/run

## eight-bit — the same idea four bits wider, and what that costs
eight-bit: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 7. THE SAME SWEEP ON AN 8-BIT ADDER -- 131072 VECTORS"
	@echo "    Predict the wall time before you look. The 4-bit sweep"
	@echo "    took about 0.05 s and this is 256 times as many vectors."
	@echo "=============================================================="
	@$(IV) -o $(RES)/sweep8.vvp $(SRC)/tb_sweep8.sv $(SRC)/ripple8.sv $(SRC)/full_adder.sv
	@cd $(RES) && /usr/bin/time -f "    wall %e s" vvp sweep8.vvp | tee sweep8.log

## check — all five verdicts against the reference numbers
check:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR VERDICTS"
	@echo "=============================================================="
	@$(CHECK) $(RES)/eight.log        --expect eight
	@$(CHECK) $(RES)/eight_broken.log --expect eight_broken
	@$(CHECK) $(RES)/six.log          --expect six
	@$(CHECK) $(RES)/sweep.log        --expect sweep
	@$(CHECK) $(RES)/fixed.log        --expect fixed

## lint — a second opinion that is not a simulation
lint: | $(RES)
	@echo "=============================================================="
	@echo " WHAT VERILATOR MAKES OF THE TWO BROKEN FILES"
	@echo " (run unpiped first, THEN look -- a pipe eats the exit code)"
	@echo "=============================================================="
	@echo "--- broken/ripple4.sv  (cin dropped)"
	@verilator --lint-only -Wall --top-module ripple4 broken/ripple4.sv \
	   $(SRC)/full_adder.sv > $(RES)/lint_ripple4.log 2>&1; \
	   echo "    verilator exit $$?"
	@sed -n '1,6p' $(RES)/lint_ripple4.log
	@echo "--- broken/full_adder.sv  (And where the Or was)"
	@verilator --lint-only -Wall --top-module full_adder broken/full_adder.sv \
	   > $(RES)/lint_full_adder.log 2>&1; \
	   echo "    verilator exit $$?"
	@grep -c "%Warning" $(RES)/lint_full_adder.log | sed 's/^/    warnings: /'

## wave — GTKWave, with the seven signals already added
wave: sweep
	gtkwave $(RES)/sweep.vcd views/sweep.gtkw

## surfer — the same waveform in Surfer
surfer: sweep
	surfer --command-file views/sweep.surf $(RES)/sweep.vcd

$(RES):
	@mkdir -p $(RES)

clean:
	rm -rf $(RES)/run
	rm -f $(RES)/*.vvp $(RES)/*.vcd $(RES)/*.log
