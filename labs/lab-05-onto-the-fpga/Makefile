# Lab 05 — Onto the FPGA
# Runs inside hpretl/iic-osic-tools:2026.08
# (Yosys 0.68, nextpnr-0.11.1-9-gb17408e2, IceStorm, Python 3.12).
#
#   make            everything below, in order, then the verdict table
#   make fpga       your adder -> netlist -> placement -> a real bitstream
#   make sizes      two more designs. Predict their bitstream sizes first.
#   make fits       the design that does NOT fit, and how the tool says so
#   make pins       the same adder with a .pcf saying which physical pin is which
#   make contrast   the SAME two files sent to SKY130 instead. This is DD103.
#   make icetime    optional: the timing tool that looks official. Read the writeup.
#   make flash      optional: needs an actual iCE40 board. Nothing here does.
#   make check      re-run every verdict on artefacts you already have
#   make clean      delete results/, keep sources

RES   := results
CHECK := python3 src/check_lab05.py
DEV   := --up5k --package sg48
LIB   := /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
CHIPDB := /foss/tools/fpga/share/icebox/chipdb-5k.txt.gz

# Yosys prints its statistics more than once. This keeps only the last block.
LAST   = awk '/Printing statistics/{b=""} {b=b $$0 ORS} END{printf "%s", b}'

.PHONY: all fpga sizes fits pins contrast icetime flash check clean

all: fpga sizes fits pins contrast check

## fpga — three commands, and you have a bitstream
fpga: | $(RES)
	@echo "=============================================================="
	@echo " 1. YOUR ADDER, ONTO A REAL PART"
	@echo "=============================================================="
	yosys -p "read_verilog -sv src/ripple4.sv src/full_adder.sv; synth_ice40 -top ripple4 -json $(RES)/r4.json" > $(RES)/ys.log 2>&1
	@echo "    yosys wrote $$(wc -l < $(RES)/ys.log) lines to $(RES)/ys.log. The answer is one of them:"
	@$(LAST) $(RES)/ys.log | grep -E "SB_LUT4"
	@echo ""
	nextpnr-ice40 $(DEV) --json $(RES)/r4.json --asc $(RES)/r4.asc --write $(RES)/post.json --freq 50 > $(RES)/pnr.log 2>&1
	@grep -E "No PCF file specified" $(RES)/pnr.log
	@grep -E "(ICESTORM_LC|ICESTORM_RAM|SB_IO|SB_GB): +[0-9]+/" $(RES)/pnr.log
	@echo ""
	@echo "--- yosys said 8 SB_LUT4 and nextpnr says 10 cells. Here are all ten. ---"
	@$(CHECK) --lcs $(RES)/post.json
	@echo ""
	@echo "--- where the time goes on the longest path ---"
	@grep -E "ns logic, .* ns routing" $(RES)/pnr.log
	@grep -E "No Fmax available" $(RES)/pnr.log | head -1
	@echo ""
	icepack $(RES)/r4.asc $(RES)/r4.bin
	@ls -l $(RES)/r4.json $(RES)/r4.asc $(RES)/r4.bin | awk '{printf "  %-10s %s bytes\n", $$9, $$5}'

## sizes — the number nobody predicts correctly
sizes: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 2. TWO MORE DESIGNS."
	@echo "    src/one_gate.sv is one AND gate. src/big.sv is 4000 flip-flops."
	@echo "    Write down NOW what you think each bitstream will weigh."
	@echo "=============================================================="
	@for d in one_gate big; do \
	  yosys -p "read_verilog -sv src/$$d.sv; synth_ice40 -top $$d -json $(RES)/$$d.json" > $(RES)/ys_$$d.log 2>&1; \
	  nextpnr-ice40 $(DEV) --json $(RES)/$$d.json --asc $(RES)/$$d.asc --freq 50 > $(RES)/pnr_$$d.log 2>&1; \
	  icepack $(RES)/$$d.asc $(RES)/$$d.bin; \
	  printf "  %-9s " $$d; \
	  grep -E "ICESTORM_LC: +[0-9]+/" $(RES)/pnr_$$d.log | tr -s ' \t' ' '; \
	done
	@echo ""
	@$(CHECK) --sizes $(RES)/one_gate.bin $(RES)/r4.bin $(RES)/big.bin
	@echo ""
	@echo "--- so how many of those 104090 bytes actually differ? ---"
	@printf "  one_gate.bin vs r4.bin : %s bytes differ\n" "$$(cmp -l $(RES)/one_gate.bin $(RES)/r4.bin | wc -l)"
	@printf "  r4.bin       vs big.bin: %s bytes differ\n" "$$(cmp -l $(RES)/r4.bin $(RES)/big.bin | wc -l)"

## fits — running out of the warehouse
fits: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 3. src/toobig.sv — a 16x16 multiplier. 692 logic cells is fine."
	@echo "=============================================================="
	yosys -p "read_verilog -sv src/toobig.sv; synth_ice40 -top toobig -json $(RES)/toobig.json" > $(RES)/ys_toobig.log 2>&1
	@nextpnr-ice40 $(DEV) --json $(RES)/toobig.json --asc $(RES)/toobig.asc --freq 50 > $(RES)/pnr_toobig.log 2>&1; \
	  echo "nextpnr exit status $$?"
	@grep -E "(ICESTORM_LC|SB_IO): +[0-9]+/" $(RES)/pnr_toobig.log
	@grep -E "^ERROR|warning, .* error" $(RES)/pnr_toobig.log
	@echo "    The error names ONE pin. The line above it names the real problem."

## pins — saying which physical pin is which
pins: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 4. THE SAME ADDER, WITH constraints/r4.pcf"
	@echo "=============================================================="
	nextpnr-ice40 $(DEV) --pcf constraints/r4.pcf --json $(RES)/r4.json --asc $(RES)/r4_pinned.asc --freq 50 > $(RES)/pnr_pinned.log 2>&1
	icepack $(RES)/r4_pinned.asc $(RES)/r4_pinned.bin
	@grep -E "Placed .* based on constraints" $(RES)/pnr_pinned.log
	@grep -E "(ICESTORM_LC|SB_IO): +[0-9]+/" $(RES)/pnr_pinned.log
	@grep -E "ns logic, .* ns routing" $(RES)/pnr_pinned.log
	@printf "  bitstream: %s bytes   (%s bytes differ from the unpinned one)\n" \
	   "$$(stat -c %s $(RES)/r4_pinned.bin)" "$$(cmp -l $(RES)/r4.bin $(RES)/r4_pinned.bin | wc -l)"

## contrast — the same source file, the other kind of target
contrast: | $(RES)
	@echo ""
	@echo "=============================================================="
	@echo " 5. SAME TWO FILES. NOT AN FPGA."
	@echo "=============================================================="
	yosys scripts/asic.ys > $(RES)/asic.log 2>&1
	@$(LAST) $(RES)/asic.log | grep -E "sky130|Chip area|is unknown"
	@echo ""
	@echo "  FPGA:  8 SB_LUT4, 10 of 5280 cells used, a 104090-byte bitstream."
	@echo "  ASIC:  12 named cells, 110.1056 um^2, and no chip yet. That is DD103."

## icetime — OPTIONAL. It looks like the tool you want. Read the writeup first.
icetime: | $(RES)
	@echo "  step 1: the obvious command"
	-icetime -d up5k -P sg48 -t $(RES)/r4.asc
	@echo ""
	@echo "  step 2: the obvious fix, pointing -C straight at the file"
	@icetime -d up5k -P sg48 -C $(CHIPDB) -t $(RES)/r4.asc; \
	  echo "    ^ icetime exit status $$? -- 139 means it segfaulted."
	@echo ""
	@echo "  step 3: what actually works (27 MB of chipdb, unpacked)"
	gunzip -c $(CHIPDB) > $(RES)/chipdb-5k.txt
	icetime -d up5k -P sg48 -C $(RES)/chipdb-5k.txt -t $(RES)/r4.asc | tail -12

## flash — OPTIONAL, and needs hardware nobody in this course is assumed to own
flash:
	@echo "  With no board attached this prints an error and exits 2. That is correct."
	-iceprog $(RES)/r4.bin

## check — every verdict in this lab, against the reference run
check:
	@echo ""
	@echo "=============================================================="
	@echo " YOUR VERDICTS"
	@echo "=============================================================="
	@$(CHECK) $(RES)/ys.log         --expect luts
	@$(CHECK) $(RES)/pnr.log        --expect util
	@$(CHECK) --lcs $(RES)/post.json | tail -1
	@$(CHECK) $(RES)/pnr.log        --expect path
	@$(CHECK) $(RES)/pnr.log        --expect nofmax
	@$(CHECK) $(RES)/r4.bin         --expect bitstream
	@$(CHECK) $(RES)/pnr_one_gate.log --expect one_gate
	@$(CHECK) $(RES)/pnr_big.log    --expect big
	@$(CHECK) $(RES)/pnr_toobig.log --expect toobig
	@$(CHECK) $(RES)/pnr_pinned.log --expect pins
	@$(CHECK) $(RES)/asic.log       --expect asic
	@$(CHECK) --sizes $(RES)/one_gate.bin $(RES)/r4.bin $(RES)/big.bin $(RES)/r4_pinned.bin

$(RES):
	@mkdir -p $(RES)

clean:
	rm -f $(RES)/*.log $(RES)/*.json $(RES)/*.asc $(RES)/*.bin $(RES)/*.txt
