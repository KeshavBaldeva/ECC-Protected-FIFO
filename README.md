# ECC-Protected-FIFO
This project implements a 32-bit RAM-based FIFO in Verilog with integrated Hamming SECDED (Single Error Correction, Double Error Detection) Error-Correcting Code (ECC). It ensures reliable and fault-tolerant data storage by detecting and correcting memory errors on-the-fly.
## Features
- Hamming SECDED ECC integration for error detection and correction.
- Separate ECC Encoder and ECC Decoder modules.
- Supports:
1. Single-bit error correction → Raises sec_err flag.
2. Double-bit error detection → Raises ded_err flag.
- FIFO control logic implemented using read/write pointers with wrap-around addressing.
- Synthesizable and verified using Xilinx Vivado.
