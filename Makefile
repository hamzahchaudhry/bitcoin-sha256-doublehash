.PHONY: sim clean

SIM_TOP = sha256_doublehash_core_tb
SV_SOURCES = sha256_doublehash_core.sv sha256_doublehash_core_tb.sv

sim:
	vlib work
	vlog -sv $(SV_SOURCES)
	vsim -c work.$(SIM_TOP) -do "run -all; quit"

clean:
	rm -rf work transcript
