`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.08.2025 16:00:31
// Design Name: 
// Module Name: Memory_39x16
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


// 39 bit is width for both data and parity bits and 16 is the depth
module Memory_39x16 (
  input  wire clk,

  // Write
  input  wire wr_en,
  input  wire [3:0]wr_addr,
  input  wire [38:0]wr_word,

  // Read
  input  wire rd_en,
  input  wire [3:0]rd_addr,
  output reg [38:0]rd_word
);
  reg [38:0]mem [0:15];

  always @(posedge clk) 
   begin
    if (wr_en)
      mem[wr_addr] <= wr_word;
    if (rd_en)
      rd_word <= mem[rd_addr];
   end
  
endmodule

