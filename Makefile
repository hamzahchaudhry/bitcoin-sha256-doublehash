.PHONY: sim new core clean

SIM_TOP ?= top_level_tb
SV_SOURCES = rtl/top_level.sv rtl/sha256_compress.sv tb/top_level_tb.sv tb/sha256_compress_tb.sv

sim:
	vlib work
	vlog -sv $(SV_SOURCES)
	vsim -c work.$(SIM_TOP) -do "run -all; quit"
	make clean

clean:
	rm -r work transcript
