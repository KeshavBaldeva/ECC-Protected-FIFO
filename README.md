# ECC-Protected-FIFO
This project implements a 16-entry, 32-bit synchronous FIFO in Verilog with integrated (39, 32) Hamming code for fault-tolerant data storage.\
It automatically corrects single-bit errors (SEC) and detects uncorrectable double-bit errors (DED) on all read operations, making it suitable for systems where memory corruption (e.g., soft errors) is a concern.

## 🔹Block Diagram
<img width="4460" height="1776" alt="Block Diagram" src="https://github.com/user-attachments/assets/de525a3d-2f12-4755-bc9e-0fdede546fc9" />

## 🔹Features
* Hamming SECDED ECC integration for error detection and correction.
* Separate ECC Encoder and ECC Decoder modules.
* FIFO control logic implemented using read/write pointers with wrap-around addressing.
* Error Handling:
  *Single-bit error correction → Raises sec_err flag.
  *Double-bit error detection → Raises ded_err flag.
* Interface: Synchronous, single-clock.
* Latency:
  *Write: 1 cycle.
  *Read: 2 cycles (from rd_en assertion to dout_valid assertion).


## 🔹 Data Flow

**Write Path**  
Input data (din) → ECC Encoder → Generates 7-bit ECC → Store (32-bit data + 7-bit ECC = 39 bits) into FIFO memory.

**Read Path**  
Fetch 39-bit word from memory → ECC Decoder → Output Register.

Corrects single-bit errors and raises sec_err.  
Detects double-bit errors and raises ded_err.  
Outputs corrected data on dout.

