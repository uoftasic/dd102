# Guide examples — The carry has to travel
# Runs inside hpretl/iic-osic-tools:2026.08 (Yosys 0.68, nextpnr-0.11.1-9-gb17408e2).
# Needs no environment setup: no .designinit, no PDK, no liberty file.
#
#   make          the width table, then the pin wall, then the verdicts
#   make widths   4, 8 and 12 bits through yosys + nextpnr -> the timing table
#   make wall     16 bits, which does not fit -- and not for the reason you expect
#   make check    re-run every verdict on logs you already have
#   make clean    delete results/, keep sources

RES   := results
DEV   := --up5k --package sg48
CHECK := python3 src/check_carry.py

# Yosys prints its statistics more than once. This keeps only the last block.
LAST   = awk '/Printing statistics/{b=""} {b=b $$0 ORS} END{printf "%s", b}'

.PHONY: all widths wall check clean

all: widths wall check

## widths — the same ripple.sv at three widths, synthesized and placed
widths: | $(RES)
	@echo "=============================================================="
	@echo " THE SAME FILE AT THREE WIDTHS, PLACED ON A REAL PART"
	@echo "   src/ripple.sv is one file. src/topN.sv only fixes its width."
	@echo "=============================================================="
	@for n in 4 8 12; do \
	  yosys -p "read_verilog -sv src/top$$n.sv src/ripple.sv src/full_adder.sv; synth_ice40 -top top -json $(RES)/r$$n.json" \
	    > $(RES)/ys$$n.log 2>&1; \
	  nextpnr-ice40 $(DEV) --json $(RES)/r$$n.json --asc $(RES)/r$$n.asc \
	    > $(RES)/pnr$$n.log 2>&1; \
	  printf "  %2s bits -> " $$n; \
	  luts=$$($(LAST) $(RES)/ys$$n.log | grep -E "SB_LUT4" | head -1 | awk '{print $$1}'); \
	  lc=$$(grep -oE "ICESTORM_LC: +[0-9]+/ +[0-9]+" $(RES)/pnr$$n.log | tail -1 | tr -s ' '); \
	  io=$$(grep -oE "SB_IO: +[0-9]+/ +[0-9]+" $(RES)/pnr$$n.log | tail -1 | tr -s ' '); \
	  t=$$(grep -oE "[0-9.]+ ns logic, [0-9.]+ ns routing" $(RES)/pnr$$n.log | tail -1); \
	  printf "%2s SB_LUT4   %-22s %-18s %s\n" "$$luts" "$$lc" "$$io" "$$t"; \
	done
	@echo ""
	@echo "--- and the longest path, end to end, from nextpnr's own report ---"
	@for n in 4 8 12; do \
	  printf "  %2s bits   total " $$n; \
	  awk '/Critical path report/,0' $(RES)/pnr$$n.log \
	    | grep -oE "^Info: +routing +[0-9.]+ +[0-9.]+" | tail -1 | awk '{printf "%s ns\n", $$4}'; \
	done

## wall — sixteen bits. Predict which resource runs out first.
wall: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " NOW SIXTEEN BITS. Write down what runs out first."
	@echo "=============================================================="
	@yosys -p "read_verilog -sv src/top16.sv src/ripple.sv src/full_adder.sv; synth_ice40 -top top -json $(RES)/r16.json" \
	  > $(RES)/ys16.log 2>&1
	@$(LAST) $(RES)/ys16.log | grep -E "SB_LUT4" | head -1
	@nextpnr-ice40 $(DEV) --json $(RES)/r16.json --asc $(RES)/r16.asc > $(RES)/pnr16.log 2>&1; \
	  echo "nextpnr exit status $$?   (255. this one does tell you.)"
	@grep -E "ICESTORM_LC:|SB_IO:" $(RES)/pnr16.log | tail -2
	@grep -E "^ERROR:|warning, .* error" $(RES)/pnr16.log
	@echo "    The ERROR names ONE pin. The line above it names the real problem:"
	@echo "    16 + 16 + 1 in and 16 + 1 out is 50 signals, and sg48 has 39."
	@echo "    You are using 34 of 5280 logic cells and you still cannot fit it."

## check — every number on the guide page, against the reference run
check:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR VERDICTS"
	@echo "=============================================================="
	@$(CHECK) $(RES) --expect n4
	@$(CHECK) $(RES) --expect n8
	@$(CHECK) $(RES) --expect n12
	@$(CHECK) $(RES) --expect n16
	@$(CHECK) $(RES) --expect slope

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.json $(RES)/*.asc $(RES)/*.log
