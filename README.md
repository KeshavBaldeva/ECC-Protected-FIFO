# ECC-Protected-FIFO
This project implements a 32-bit RAM-based FIFO in Verilog with integrated Hamming SECDED (Single Error Correction, Double Error Detection) Error-Correcting Code (ECC). It ensures reliable and fault-tolerant data storage by detecting and correcting memory errors on-the-fly.

## 🔹 Block Diagram
<img width="4460" height="1776" alt="Block Diagram" src="https://github.com/user-attachments/assets/de525a3d-2f12-4755-bc9e-0fdede546fc9" />

## 🔹 Features
- Hamming SECDED ECC integration for error detection and correction.
- Separate ECC Encoder and ECC Decoder modules.
- Supports:
1. Single-bit error correction → Raises sec_err flag.
2. Double-bit error detection → Raises ded_err flag.
- FIFO control logic implemented using read/write pointers with wrap-around addressing.
- Synthesizable and verified using Xilinx Vivado.

## 🔹 Data Flow

**Write Path**  
Input data (din) → ECC Encoder → Generates 7-bit ECC → Store (32-bit data + 7-bit ECC = 39 bits) into FIFO memory.

**Read Path**  
Fetch 39-bit word from memory → ECC Decoder → Output Register.
Corrects single-bit errors and raises sec_err.  
Detects double-bit errors and raises ded_err.  
Outputs corrected data on dout.

