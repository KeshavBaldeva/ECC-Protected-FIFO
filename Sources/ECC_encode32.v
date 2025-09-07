`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.08.2025 15:56:10
// Design Name: 
// Module Name: ECC_encode32
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


// Hamming SECDED encoder for 32-bit data -> 7 ECC bits
module ECC_encode32 (
  input  wire [31:0] d_in,
  output wire [6:0]  ecc_out   // {p[5:0], p0}
);
  function automatic integer is_pow2(input integer x);
    begin is_pow2 = (x & (x-1)) == 0; end
  endfunction

  reg [38:1] cw; // Codeword without overall parity (positions 1..38)
  integer i, di;
  always @* begin
    di = 0;
    for (i = 1; i <= 38; i = i + 1) begin
      if (!is_pow2(i)) begin
        cw[i] = d_in[di];
        di    = di + 1;
      end else begin
        cw[i] = 1'b0; // placeholder for parity
      end
    end
  end

  reg [5:0] p;
  integer k, j;
  always @* begin
    for (k = 0; k < 6; k = k + 1) begin
      p[k] = 1'b0;
      for (j = 1; j <= 38; j = j + 1)
        if (j & (1 << k))
          p[k] = p[k] ^ cw[j];
    end
  end

  reg [38:1] cw_full;
  always @* begin
    cw_full = cw;
    cw_full[1]  = p[0];
    cw_full[2]  = p[1];
    cw_full[4]  = p[2];
    cw_full[8]  = p[3];
    cw_full[16] = p[4];
    cw_full[32] = p[5];
  end

  reg p0;
  always @* begin
    p0 = 1'b0;
    for (j = 1; j <= 38; j = j + 1)
      p0 = p0 ^ cw_full[j];
  end

  assign ecc_out = {p, p0};
endmodule
