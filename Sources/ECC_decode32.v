`timescale 1ns / 1ps

module ECC_decode32 (
  input  wire [31:0] d_in,
  input  wire [6:0]  ecc_in, // {p[5:0], p0}
  output reg  [31:0] d_out,
  output reg         sec_err,
  output reg         ded_err
);
  // hammign parity positions: 1,2,4,8,16,32
  function automatic integer is_pow2(input integer x);
    begin
      is_pow2 = ((x & (x-1)) == 0);
    end
  endfunction

  wire [5:0] p_recv  = ecc_in[6:1]; 
  wire p0_recv = ecc_in[0];   
  
  // cw[i] -> Hamming position i 
  reg [38:1] cw;
  integer i, di;
  always@(*) begin
    di = 0;//tracking of data bits
    for (i = 1; i <= 38; i = i + 1) begin
      if (!is_pow2(i))
        begin
         cw[i] = d_in[di];
         di = di + 1;
        end else 
        begin
         case (i)
          1:cw[i] = p_recv[0];
          2:cw[i] = p_recv[1];
          4:cw[i] = p_recv[2];
          8:cw[i] = p_recv[3];
          16:cw[i] = p_recv[4];
          32:cw[i] = p_recv[5];
          default:cw[i] = 1'b0;
         endcase
        end
    end
  end

  // Compute syndrome (6 bits)
  reg [5:0] syndrome;
  integer k, j;
  always @* begin
    for (k = 0; k < 6; k = k + 1) begin
      syndrome[k] = 1'b0;
      for (j = 1; j <= 38; j = j + 1)
        if (j & (1 << k))
          syndrome[k] = syndrome[k] ^ cw[j];
    end
  end

  //calculation of overall_err signal 
  wire overall_err = p0_recv ^ (^cw);

  reg [38:1] cw_corr;
  reg [31:0] d_tmp;
  integer err_pos, idx, d_idx;

  always@(*) begin
    cw_corr = cw;
    sec_err = 1'b0;
    ded_err = 1'b0;
    err_pos = syndrome; // numeric position (0 == no hamming mismatch)

    // Decision table (SECDED, even parity)
    if (syndrome == 6'd0 && overall_err == 1'b0) 
     begin
      // No error
     end
    else if (syndrome == 6'd0 && overall_err == 1'b1) 
     begin
      // Only overall parity bit flipped (P0) -> data ok
      sec_err = 1'b1;
     end
    else if (syndrome != 6'd0 && overall_err == 1'b1)
     begin
      // Single-bit error at position 'err_pos' -> correct it
      if (err_pos >= 1 && err_pos <= 38)
        cw_corr[err_pos] = ~cw_corr[err_pos];
      sec_err = 1'b1;
     end
    else 
     begin
      // syndrome != 0 && overall_err == 0 => double-bit error -> leave as it is
      ded_err = 1'b1;
     end

    d_idx = 0; //for index tracking
    for (idx = 1; idx <= 38; idx = idx + 1) begin
      if (!is_pow2(idx)) begin
        d_tmp[d_idx] = cw_corr[idx];
        d_idx = d_idx + 1;
      end
    end
    d_out = d_tmp;
  end

endmodule
