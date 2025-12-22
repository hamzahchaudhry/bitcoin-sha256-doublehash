# SHA-256 Core (Bitcoin-Oriented Prototype)

This repo currently contains a standalone SystemVerilog SHA-256 core plus a simple testbench and constant ROM files. It is an educational prototype for the Bitcoin double-hash workflow.

## Overview

The current contents are focused on the hashing core itself and simulation:

- `sha256_doublehash_core.sv` implements a SHA-256 core and a simple two-stage (double-hash) flow.
- `sha256_doublehash_core_tb.sv` is a basic testbench with one known test vector.
- `sha256_k.hex` and `sha256_h0.hex` provide round constants and initial hash values.

## Current Status and Future Work

- **Current:** SHA-256 core + basic testbench.
- **Next:** Add a clean interface (`start/ready`), predictable cycle counts, and a tighter testbench with multiple vectors.
- **Later:** Wrap the core in a miner pipeline (nonce scanning, midstate, target compare) and add board integration.
