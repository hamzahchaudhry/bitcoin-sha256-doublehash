# Bitcoin Double SHA-256 (SystemVerilog)

SystemVerilog implementation of the Bitcoin double SHA-256 flow: a standalone compression core and a miner-style top that loops over nonces. This is meant as a small, readable prototype for the hashing pipeline.

## Overview

RTL:

- `rtl/sha256_compress.sv` — SHA-256 compression function (64 rounds).
- `rtl/miner_top.sv` — midstate + nonce loop: hashes the 76-byte header prefix, appends nonce, double-hashes, compares to target, and reports the first “golden” nonce.

Testbenches (ModelSim/Questa):

- `tb/sha256_compress_tb.sv` — unit test for the compression core (empty string, “abc” vectors).
- `tb/miner_top_tb.sv` — default sim; uses the Bitcoin test header with nonce 0 and checks digest/nonce.

## Simulation

```bash
make sim
```

By default this runs `miner_top_tb`. Pick another top with `SIM_TOP`:

```bash
make sim SIM_TOP=sha256_compress_tb
make sim SIM_TOP=miner_top_tb
```

## Notes and Future Work

- **Real block testing:** Fetch an 80-byte header (e.g., via `bitcoin-cli getblock <hash> 0`), split the first 76 bytes into `blockHeader_noNonce`, keep the last 4 bytes as the nonce, compute target from `nBits`, and plug into the TB. To avoid simulating billions of nonces, force the known nonce or lower the target so a hit occurs quickly.
- **Cycle counts:** SHA-256 core is ~70 cycles per block (load + 64 rounds); miner flow is ~2 blocks for first hash + 1 block for second hash per nonce.
- **Future:** Add more vectors (real blocks), optional start-nonce input, pipelined or multi-core variants, and latency/throughput documentation.
