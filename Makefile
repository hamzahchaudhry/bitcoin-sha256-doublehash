.PHONY: sim new core clean

SIM_TOP ?= sha256_doublehash_core_tb
SV_SOURCES = rtl/sha256_doublehash_core.sv rtl/sha256_compress.sv tb/sha256_doublehash_core_tb.sv tb/sha256_compress_tb.sv

sim:
	vlib work
	vlog -sv $(SV_SOURCES)
	vsim -c work.$(SIM_TOP) -do "run -all; quit"
	make clean

clean:
	rm -r work transcript
