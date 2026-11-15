# Lab 04 — Four adders in a row
# Runs inside hpretl/iic-osic-tools:2026.08 (Icarus 14.0, Yosys 0.68, Python 3.12).
# Needs no environment setup: no .designinit, no PDK, no liberty file.
#
#   make            everything below, in order, then the verdict table
#   make generate   your generate-for adder against all 512 inputs   -> PASS
#   make proof      Yosys PROVES it equals the hand-typed version    -> SUCCESS!
#   make broken     one digit changed. Predict the damage first.     -> FAIL 512/512
#   make gotcha     two pieces of generate folklore, one true        -> see for yourself
#   make wide       the same adder at 4, 8, 16 and 32 bits
#   make wide12     the 12-bit exhaustive test. Takes about 4.5 minutes.
#   make check      re-run every verdict on logs you already have
#   make clean      delete results/, keep sources

RES   := results
IV    := iverilog -g2012
CHECK := python3 src/check_lab04.py

# Yosys prints its statistics more than once. This keeps only the last block.
LAST   = awk '/Printing statistics/{b=""} {b=b $$0 ORS} END{printf "%s", b}'

.PHONY: all generate proof broken gotcha wide wide12 check clean

all: generate proof broken gotcha wide check

## generate — one loop, four adders, every input they can ever see
generate: | $(RES)
	@echo "=============================================================="
	@echo " 1. ONE LOOP, FOUR ADDERS, 512 INPUTS"
	@echo "=============================================================="
	$(IV) -o $(RES)/generate.vvp tb/tb_ripple4.sv src/ripple4.sv src/full_adder.sv
	@cd $(RES) && vvp generate.vvp | tee generate.log
	@mv -f $(RES)/ripple4.vcd $(RES)/generate.vcd 2>/dev/null || true
	@echo ""
	@echo "--- and what the loop actually built ---"
	yosys scripts/check_good.ys > $(RES)/check_good.log 2>&1
	@grep -E "Found and reported|^ +[0-9]+ {3}full_adder" $(RES)/check_good.log

## proof — 512 cases is not the same as "for every input". This is.
proof: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. THE PROOF — generate loop vs four instances typed by hand"
	@echo "    Yosys prints ASCII art when it wins. That is not a bug."
	@echo "=============================================================="
	yosys scripts/proof.ys > $(RES)/proof.log 2>&1
	@grep -E "Solving problem with|SAT proof finished" $(RES)/proof.log
	@grep -A11 "SUCCESS!" $(RES)/proof.log | tail -10

## broken — the deliberate failure. Commit to a number before you run it.
broken: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 3. broken/ripple4.sv — ONE character different from yours."
	@echo "    Write your prediction down NOW: of 512 inputs, how many fail?"
	@echo "=============================================================="
	$(IV) -o $(RES)/broken.vvp tb/tb_ripple4.sv broken/ripple4.sv src/full_adder.sv
	@cd $(RES) && vvp broken.vvp | tee broken.log; \
	  echo "vvp exit status $$?   (zero. read the verdict, not the exit code.)"
	@mv -f $(RES)/ripple4.vcd $(RES)/broken.vcd 2>/dev/null || true
	@echo ""
	@echo "--- the one-line check that names the wire, without reading any RTL ---"
	@yosys scripts/check_broken.ys > $(RES)/check_broken.log 2>&1
	@grep -E "Warning: Wire|Found and reported|^ +[0-9]+ {3}full_adder" $(RES)/check_broken.log
	@echo ""
	@echo "--- and the proof, on the broken one: it hands you an input ---"
	@yosys scripts/proof_broken.ys > $(RES)/proof_broken.log 2>&1; \
	  echo "yosys exit status $$?   (one. this tool DOES tell you.)"
	@grep -A6 "Signal Name" $(RES)/proof_broken.log

## gotcha — two things people say about generate loops. One is true.
gotcha: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 4a. FOLKLORE: 'you cannot write i++ in a generate for'"
	@echo "=============================================================="
	@yosys -p "read_verilog -sv errors/ripple4_incr.sv src/full_adder.sv; synth_ice40 -top ripple4" \
	   > $(RES)/incr.log 2>&1; echo "yosys exit status $$?"
	@$(LAST) $(RES)/incr.log | grep -E "SB_LUT4" | head -1
	@echo "    ^ same 9 SB_LUT4 as src/ripple4.sv. On THIS workbench, folklore."
	@echo ""
	@echo "=============================================================="
	@echo " 4b. TRUE: 'you cannot label a generate block bit'"
	@echo "=============================================================="
	@yosys -p "read_verilog -sv errors/ripple4_bit.sv src/full_adder.sv" \
	   > $(RES)/bit_yosys.log 2>&1; echo "yosys exit status $$?"
	@grep -E "ERROR" $(RES)/bit_yosys.log
	@echo ""
	@echo "--- the same file through Icarus. Brace yourself. ---"
	@$(IV) -o $(RES)/bit.vvp errors/ripple4_bit.sv src/full_adder.sv \
	   > $(RES)/bit_icarus.log 2>&1; echo "iverilog exit status $$?"
	@cat $(RES)/bit_icarus.log

## wide — change one number, get a different adder
wide: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 5. THE SAME FILE AT FOUR WIDTHS"
	@echo "=============================================================="
	@for n in 4 8 16 32; do \
	  yosys -p "read_verilog -sv src/ripple.sv src/full_adder.sv; chparam -set N $$n ripple; hierarchy -top ripple; synth_ice40 -top ripple" \
	    > $(RES)/luts$$n.log 2>&1; \
	  printf "  N = %-3s -> " $$n; \
	  $(LAST) $(RES)/luts$$n.log | grep -E "SB_LUT4" | head -1; \
	done
	@echo ""
	@echo "--- now the exhaustive test at 4 bits and at 8 ---"
	@for n in 4 8; do \
	  $(IV) -Ptb_ripple.N=$$n -o $(RES)/wide$$n.vvp tb/tb_ripple.sv src/ripple.sv src/full_adder.sv; \
	  ( cd $(RES) && vvp wide$$n.vvp | tee wide$$n.log | grep -E "cases|PASS|FAIL" ); \
	done
	@echo ""
	@echo "  512 inputs took no measurable time. 131072 took under a second."
	@echo "  'make wide12' does 33554432 and takes about four and a half minutes."
	@echo "  Work out 16 bits before you try it."

## wide12 — the one that starts to hurt
wide12: | $(RES)
	$(IV) -Ptb_ripple.N=12 -o $(RES)/wide12.vvp tb/tb_ripple.sv src/ripple.sv src/full_adder.sv
	@cd $(RES) && time vvp wide12.vvp | tee wide12.log

## check — every verdict in this lab, against the reference run
check:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR VERDICTS"
	@echo "=============================================================="
	@$(CHECK) $(RES)/generate.log     --expect generate
	@$(CHECK) $(RES)/check_good.log   --expect clean
	@$(CHECK) $(RES)/proof.log        --expect proof
	@$(CHECK) $(RES)/broken.log       --expect broken
	@$(CHECK) $(RES)/check_broken.log --expect undriven
	@$(CHECK) $(RES)/proof_broken.log --expect proof_broken
	@$(CHECK) $(RES)/luts4.log        --expect luts4
	@$(CHECK) $(RES)/luts8.log        --expect luts8
	@$(CHECK) $(RES)/luts16.log       --expect luts16
	@$(CHECK) $(RES)/luts32.log       --expect luts32
	@$(CHECK) $(RES)/wide4.log        --expect wide4
	@$(CHECK) $(RES)/wide8.log        --expect wide8

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.vvp $(RES)/*.vcd $(RES)/*.log
