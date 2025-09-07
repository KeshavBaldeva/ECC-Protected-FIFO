`timescale 1ns/1ps

module tb_FIFO_with_ECC;

  reg clk;
  reg rst_n;
  reg wr_en;
  reg rd_en;
  reg [31:0] din;
  wire [31:0] dout;
  wire dout_valid;
  wire full;
  wire empty;
  wire sec_err;
  wire ded_err;

  integer addr;
  reg [38:0] temp_word;

  // DUT instance
  FIFO_with_ECC dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .din(din),
    .full(full),
    .rd_en(rd_en),
    .dout(dout),
    .dout_valid(dout_valid),
    .empty(empty),
    .sec_err(sec_err),
    .ded_err(ded_err)
  );

  // Clock generation: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // Data to send
  reg [31:0] data_array [0:4];
  initial begin
    data_array[0] = 32'd1000;
    data_array[1] = 32'd2000;
    data_array[2] = 32'd3000;
    data_array[3] = 32'd4000;
    data_array[4] = 32'd5000;
  end

  // Main stimulus
  initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, tb_FIFO_with_ECC);

    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    din   = 0;
    #20;
    rst_n = 1;

    fork
      drive_writes();
      drive_reads();
    join

    #200;
    $finish;
  end

  // Write process: every 2 cycles
  task drive_writes;
    integer i;
    begin
      for (i = 0; i < 5; i = i + 1) begin
        @(negedge clk);
        wr_en = 1;
        din   = data_array[i];
        @(negedge clk);
        wr_en = 0;
        din   = 0;

        // Inject errors right after writing specific words
        if (i == 1) begin
          // After writing word 2 (2000) -> flip 1 data bit
          @(negedge clk);
          addr = (dut.mem_wr_addr - 1) & 4'hF;
          temp_word = dut.u_mem.mem[addr];
          dut.u_mem.mem[addr] = temp_word ^ (39'h1 << 7);  // flip data bit0
          $display("** Injected 1-bit error into word at addr %0d", addr);
        end
        if (i == 3) begin
          // After writing word 4 (4000) -> flip 2 data bits
          @(negedge clk);
          addr = (dut.mem_wr_addr - 1) & 4'hF;
          temp_word = dut.u_mem.mem[addr];
          dut.u_mem.mem[addr] = temp_word ^ ((39'h1 << 7) | (39'h1 << 8)); // flip data bit0, bit1
          $display("** Injected 2-bit error into word at addr %0d", addr);
        end

        // Wait remaining cycles to make total gap 2 cycles between writes
        repeat (0) @(negedge clk); // no extra wait here, 2 cycles total per write
      end
    end
  endtask

  // Read process: every 3 cycles
  task drive_reads;
    begin
      // small delay so reads lag behind writes
      #30;
      forever begin
        @(negedge clk);
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;
        // gap to make it every 3 cycles total
        repeat (1) @(negedge clk);
      end
    end
  endtask

  // Monitor output
  always @(posedge clk) begin
    if (dout_valid) begin
      $display("TIME %0t ns: Read %0d | SEC=%b | DED=%b",
               $time, dout, sec_err, ded_err);
    end
  end

endmodule
