# Reference card — every example on docs/reference/systemverilog-survival-card.md
# Runs inside hpretl/iic-osic-tools:2026.04 (Icarus Verilog 14.0, Yosys 0.64).
# No environment setup: no .designinit, no mod, no PDK, no liberty file.
#
#   make          compile and run all twelve cards, then the verdict table
#   make card N=8 run one card on its own (N is the number on the page)
#   make synth    what card 08's `generate for` becomes on an iCE40
#   make check    re-run the verdict on a card.log you already have
#   make broken   read a FAIL. Feeds the checker the answer most people predict
#   make lint     ask two other tools about card 11's mistake. Both shrug
#   make clean    empty results/, keep sources

SRC   := src
RES   := results
IV    := iverilog -g2012
CARDS := $(sort $(notdir $(basename $(wildcard $(SRC)/[0-9]*.sv))))

.PHONY: all run check synth card broken lint clean

all: run check

run: | $(RES)
	@echo "=============================================================="
	@echo " TWELVE CARDS.  Each file is complete and runs on its own."
	@echo "=============================================================="
	@rm -f $(RES)/card.log
	@cd $(RES) && for n in $(CARDS); do \
	    $(IV) -o $$n.vvp ../$(SRC)/$$n.sv || exit 1; \
	    vvp -n $$n.vvp | grep -v '^VCD info' | grep -v '\$$finish called' \
	      | tee -a card.log; \
	  done
	@echo ""
	@echo "  Card 12 also wrote $(RES)/card12.vcd and printed two lines this"
	@echo "  table drops: 'VCD info: dumpfile card12.vcd opened for output.'"
	@echo "  and '\$$finish called at 20000 (1ps)'. Both are normal."

check:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR CARDS vs THE REFERENCE RUN"
	@echo "=============================================================="
	@python3 $(SRC)/check_card.py

## broken — a FAIL you caused on purpose, so you know what one looks like
broken: | $(RES)
	@echo "=============================================================="
	@echo " THE CHECKER, FED THE ANSWER MOST PEOPLE PREDICT FOR CARD 11"
	@echo " (9+9 = 18, so a 4-bit sum says 18. Doesn't it?)"
	@echo "=============================================================="
	@cp broken/card.log $(RES)/card.log
	-@python3 $(SRC)/check_card.py; echo "    check_card.py exit $$?"
	@echo ""
	@echo "    That is what a FAIL reads like: the row, your value, the reference"
	@echo "    value, and nothing else shouting. Now put the real one back:"
	@echo "        make clean && make"

## card — run exactly one, e.g. make card N=11
card: | $(RES)
	@f=$$(ls $(SRC)/$$(printf '%02d' $(N))_*.sv); \
	  echo "--- $$f"; cd $(RES) && $(IV) -o one.vvp ../$$f && vvp -n one.vvp

## synth — the generate loop, on an FPGA
synth: | $(RES)
	@echo "=============================================================="
	@echo " CARD 08 THROUGH YOSYS.  How many LUTs does a generate loop cost?"
	@echo " Write a number down before you look."
	@echo "=============================================================="
	@yosys -p "read_verilog -sv $(SRC)/08_generate_for.sv; synth_ice40 -top ripple4; stat" \
	   > $(RES)/synth.log 2>&1; echo "    yosys exit $$?"
	@awk '/^=== ripple4 ===$$/{n++} n==2' $(RES)/synth.log | head -14
	@echo "    The four \$$scopeinfo are bookkeeping, not hardware. Eight SB_LUT4"
	@echo "    is the answer: the generate loop cost exactly what four full adders"
	@echo "    written out by hand cost. It is a typing shortcut, not a discount."

## lint — a second and a third opinion on a real bug. Neither has one.
lint: | $(RES)
	@echo "=============================================================="
	@echo " CARD 11's MISTAKE, ALONE IN A FILE, SHOWN TO TWO MORE TOOLS"
	@echo " (run unpiped first, THEN look -- a pipe eats the exit code)"
	@echo "=============================================================="
	@iverilog -g2012 -o /dev/null broken/narrow_only.sv; echo "    iverilog  exit $$? -- and it printed nothing at all"
	@verilator --lint-only -Wall broken/narrow_only.sv; echo "    verilator exit $$? -- the three lines above are its run report,"; echo "                       not a warning. -Wall found nothing to say."
	@echo ""
	@echo "    Reflex: nobody checks your widths for you. When you add two N-bit"
	@echo "    numbers and you want the carry, the destination is N+1 bits wide."

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.vvp $(RES)/*.vcd $(RES)/*.log
