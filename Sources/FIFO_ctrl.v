`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2025 23:50:16
// Design Name: 
// Module Name: FIFO_ctrl
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


// FIFO control logic for depth = 16 entries (single clock)
module FIFO_ctrl (
  input  wire       clk,
  input  wire       rst_n,

  // External interface
  input  wire       wr_en,
  output wire       full,
  input  wire       rd_en,
  output wire       empty,

  // To raw memory
  output wire       mem_wr_en,
  output wire [3:0] mem_wr_addr,
  output wire       mem_rd_en,
  output wire [3:0] mem_rd_addr
);

  reg [4:0] wr_ptr, rd_ptr; // 4 bits index + 1 wrap bit

  assign empty = (wr_ptr == rd_ptr);
  assign full  = (wr_ptr[4] != rd_ptr[4]) && (wr_ptr[3:0] == rd_ptr[3:0]);

  assign mem_wr_en   = wr_en && !full;
  assign mem_rd_en   = rd_en && !empty;
  assign mem_wr_addr = wr_ptr[3:0];
  assign mem_rd_addr = rd_ptr[3:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      wr_ptr <= 5'd0;
    else if (mem_wr_en)
      wr_ptr <= wr_ptr + 5'd1;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rd_ptr <= 5'd0;
    else if (mem_rd_en)
      rd_ptr <= rd_ptr + 5'd1;
  end

endmodule

