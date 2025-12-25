.PHONY: sim clean

SIM_TOP ?= miner_top_tb
SV_SOURCES = rtl/sha256_compress.sv \
	rtl/miner_top.sv \
	tb/sha256_compress_tb.sv \
	tb/miner_top_tb.sv

sim:
	vlib work
	vlog -sv $(SV_SOURCES)
	vsim -c work.$(SIM_TOP) -do "run -all; quit"
	make clean

clean:
	rm -r work transcript
