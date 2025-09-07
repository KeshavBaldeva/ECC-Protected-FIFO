`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.08.2025 16:02:08
// Design Name: 
// Module Name: FIFO_with_ECC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Top-level FIFO with ECC Hamming SECDED (32-bit data, 7-bit ECC)
module FIFO_with_ECC (
  input  wire        clk,
  input  wire        rst_n,

  // External write
  input  wire        wr_en,
  input  wire [31:0] din,
  output wire        full,

  // External read
  input  wire        rd_en,
  output reg  [31:0] dout,
  output reg         dout_valid,
  output wire        empty,

  // Error flags
  output reg         sec_err,
  output reg         ded_err
);
  // ---------------- Control ----------------
  wire mem_wr_en, mem_rd_en;
  wire [3:0] mem_wr_addr, mem_rd_addr;

  FIFO_ctrl u_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .full(full),
    .rd_en(rd_en),
    .empty(empty),
    .mem_wr_en(mem_wr_en),
    .mem_wr_addr(mem_wr_addr),
    .mem_rd_en(mem_rd_en),
    .mem_rd_addr(mem_rd_addr)
  );

  // ---------------- ECC encode (write) ----------------
  wire [6:0] ecc_w;
  ECC_encode32 u_enc (
    .d_in(din),
    .ecc_out(ecc_w)
  );

  wire [38:0] wr_word = {din, ecc_w};

  // ---------------- Raw memory ----------------
  wire [38:0] rd_word;
  Memory_39x16 u_mem (
    .clk(clk),
    .wr_en(mem_wr_en),
    .wr_addr(mem_wr_addr),
    .wr_word(wr_word),
    .rd_en(mem_rd_en),
    .rd_addr(mem_rd_addr),
    .rd_word(rd_word)
  );

  // ---------------- ECC decode (read) ----------------
  wire [31:0] d_corr;
  wire sec_w, ded_w;
  ECC_decode32 u_dec (
    .d_in(rd_word[38:7]),
    .ecc_in(rd_word[6:0]),
    .d_out(d_corr),
    .sec_err(sec_w),
    .ded_err(ded_w)
  );

  // ---------------- Output register ----------------
  reg rd_fire_d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rd_fire_d <= 1'b0;
    else
      rd_fire_d <= mem_rd_en;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dout       <= 32'd0;
      dout_valid <= 1'b0;
      sec_err    <= 1'b0;
      ded_err    <= 1'b0;
    end else begin
      dout_valid <= rd_fire_d;
      if (rd_fire_d) begin
        dout    <= d_corr;
        sec_err <= sec_w;
        ded_err <= ded_w;
      end else begin
        sec_err <= 1'b0;
        ded_err <= 1'b0;
      end
    end
  end
endmodule

