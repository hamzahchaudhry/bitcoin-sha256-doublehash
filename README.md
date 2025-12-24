# Bitcoin Double SHA-256 (SystemVerilog)

This repo contains a SystemVerilog SHA-256 compression core plus a small top-level that performs the Bitcoin-style double SHA-256 on an 80-byte block header. It is a focused educational prototype for the Bitcoin hashing pipeline.

## Overview

The current contents are focused on the compression core, a double-hash wrapper, and simulation:

- `rtl/sha256_compress.sv` implements the SHA-256 compression function.
- `rtl/sha256_doublehash_core.sv` feeds an 80-byte header through two SHA-256 blocks, then hashes the 32-byte result again (double SHA-256).
- `tb/sha256_compress_tb.sv` is a basic testbench with a known test vector.
- `tb/sha256_doublehash_core_tb.sv` is a simple top-level integration testbench.

## Simulation

```bash
make sim
```

To pick a specific testbench:

```bash
make sim SIM_TOP=sha256_compress_tb
make sim SIM_TOP=sha256_doublehash_core_tb
```

## Current Status and Future Work

- **Current:** Working SHA-256 compression core, a Bitcoin-style double-hash wrapper for 80-byte headers, and basic simulation testbenches.
- **Next:** Document cycle counts/latency, add more test vectors (including full block headers), and consider a pipelined datapath for throughput.
- **Later:** Build a full mining-style pipeline (midstate, nonce scanning), integrate on FPGA hardware, and add a control/software stack to feed work and report performance.
