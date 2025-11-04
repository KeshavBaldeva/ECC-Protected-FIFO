`timescale 1ns / 1ps

module tb_FIFO_complex;

  // -----------------------
  // Testbench Signals
  // -----------------------
  reg        clk;
  reg        rst_n;
  reg        wr_en;
  reg [31:0] din;
  reg        rd_en;

  wire       full;
  wire [31:0] dout;
  wire       dout_valid;
  wire       empty;
  wire       sec_err;
  wire       ded_err;

  // ------------------------------
  // Scoreboard(Refrence Model) 
  // ------------------------------
  reg [31:0] queue_model [0:15]; // Array for 16 entries
  reg [3:0] queue_head; // Write pointer for queue
  reg [3:0] queue_tail; // Read pointer for queue
  reg [4:0] queue_count; // Counter(0 to 16)
  reg [31:0] expected_data;
  
  integer i;
  reg [38:0] corrupted_word; // To inject error
  reg test_failed; // Flag to track failure
  

  // To push data in refrence model
  task queue_push;
    input [31:0] data;
    begin
      if (queue_count < 16) begin
        queue_model[queue_head] = data;
        queue_head = queue_head + 1; 
        queue_count = queue_count + 1;
      end
    end
  endtask

  // To pop data from refrence model
  task queue_pop;
    output [31:0] data;
    begin
      if (queue_count > 0) begin
        data = queue_model[queue_tail];
        queue_tail = queue_tail + 1; 
        queue_count = queue_count - 1;
      end
    end
  endtask

// DUT Module
  FIFO_with_ECC u_dut (
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

  initial 
   begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz
   end

  
  initial begin
    $display("------------------------------------------------------");
    $display("TB START (Verilog): Resetting the DUT...");
    $display("------------------------------------------------------");

    //Instantiate all signals
    rst_n = 1'b0;
    wr_en = 1'b0;
    rd_en = 1'b0;
    din   = 32'd0;
    
    queue_head = 4'd0;
    queue_tail = 4'd0;
    queue_count = 5'd0;
    
    @(posedge clk); // to hold one clock edge for reset
    @(posedge clk);
    
    rst_n = 1'b1; // De-assert reset
    
    @(posedge clk);
    
    // Check reset state
    #1; 
    if (!(empty)) begin $display("[%0t] TEST FAILED: FIFO not empty after reset.", $time); $fatal(1); end
    if (full) begin $display("[%0t] TEST FAILED: FIFO full after reset.", $time); $fatal(1); end
    if (dout_valid) begin $display("[%0t] TEST FAILED: dout_valid high after reset.", $time); $fatal(1); end

    // ----------------------------------
    // Test 1: Basic Write/Read
    // ----------------------------------
    $display("\n[%0t] TEST 1: Basic Write/Read (No Error)", $time);
    test_failed = 1'b0; // Reset fail flag
    
    // Write
    din = 32'hAAAAAAAA;
    wr_en = 1'b1;
    queue_push(din); //To store in refrence model
    @(posedge clk);
    wr_en = 0;
    $display("[%0t]   Wrote: 0x%h", $time, din);

    // 2-cycle synchronous read
    @(posedge clk);
    rd_en = 1'b1;
    @(posedge clk);
    rd_en = 0;

    // Wait for the DUT to update outputs
    @(posedge clk); #1;

    queue_pop(expected_data);
    $display("[%0t]   Read: 0x%h (Expected: 0x%h)", $time, dout, expected_data);
    
    if (!(dout_valid)) begin $display("[%0t] TEST 1 FAILED: dout_valid not high on read.", $time); test_failed = 1'b1; $fatal(1); end
    if (dout != expected_data) begin $display("[%0t] TEST 1 FAILED: Data mismatch.", $time); test_failed = 1'b1; $fatal(1); end
    if (sec_err != 0) begin $display("[%0t] TEST 1 FAILED: sec_err was high.", $time); test_failed = 1'b1; $fatal(1); end
    if (ded_err != 0) begin $display("[%0t] TEST 1 FAILED: ded_err was high.", $time); test_failed = 1'b1; $fatal(1); end
    
    @(posedge clk); #1;
    if (!(empty)) begin $display("[%0t] TEST 1 FAILED: FIFO not empty after read.", $time); test_failed = 1'b1; $fatal(1); end
    
    if (!test_failed) $display("TEST 1 PASSED");

    // -------------------------------------------
    // Test 2: Full FIFO Condition
    // -------------------------------------------
    $display("\n[%0t] TEST 2: Fill FIFO (Full Condition)", $time);
    test_failed = 1'b0;
    
    for (i = 0; i < 16; i = i + 1) 
     begin
      if (full) begin $display("[%0t] TEST 2 FAILED: FIFO full prematurely.", $time); $fatal(1); end
      din = 32'hBEEF0000 + i;
      wr_en = 1'b1;
      queue_push(din);
      @(posedge clk);
      $display("[%0t]   Wrote: 0x%h (Count: %0d)", $time, din, i+1);
     end
    wr_en = 0;
    
    @(posedge clk); #1;
    if (!(full)) begin $display("[%0t] TEST 2 FAILED: FIFO not full after 16 writes.", $time); $fatal(1); end
    
    // Try to write to a full FIFO(Should not update )
    din = 32'hDEADBEEF;
    wr_en = 1'b1;
    @(posedge clk);
    wr_en = 0;
    
    $display("[%0t]   FIFO is full. Attempted overflow write.", $time);
    $display("[%0t]   Reading back 16 words...", $time);

    // Read all back
    for (i = 0; i < 16; i = i + 1)
     begin
      if (empty) begin $display("[%0t] TEST 2 FAILED: FIFO empty prematurely.", $time); $fatal(1); end
      rd_en = 1'b1;
       @(posedge clk); // Cycle 1 for read request
      rd_en = 0;
       @(posedge clk); #1; // Cycle 2 and small delay
      
      queue_pop(expected_data);
      if (!(dout_valid)) begin $display("[%0t] TEST 2 FAILED: dout_valid low on readback (i=%0d).", $time, i); test_failed = 1'b1; $fatal(1); end
      if (dout != expected_data) begin $display("[%0t] TEST 2 FAILED: Data mismatch on readback (i=%0d).", $time, i); test_failed = 1'b1; $fatal(1); end
      if (sec_err != 0) begin $display("[%0t] TEST 2 FAILED: sec_err high on readback (i=%0d).", $time, i); test_failed = 1'b1; $fatal(1); end
      if (ded_err != 0) begin $display("[%0t] TEST 2 FAILED: ded_err high on readback (i=%0d).", $time, i); test_failed = 1'b1; $fatal(1); end
     end
    
    @(posedge clk); #1;
    if (!(empty)) begin $display("[%0t] TEST 2 FAILED: FIFO not empty after reading 16 words.", $time); $fatal(1); end
    if (queue_count != 0) begin $display("[%0t] TEST 2 FAILED: Scoreboard not empty.", $time); $fatal(1); end
    
    if (!test_failed) $display("TEST 2 PASSED");

    // -------------------------------------------
    // Test 3: Read from Empty FIFO
    // -------------------------------------------
    $display("\n[%0t] TEST 3: Read from Empty FIFO", $time);
    test_failed = 1'b0;
    
    if (!(empty)) begin $display("[%0t] TEST 3 FAILED: FIFO not empty to start.", $time); $fatal(1); end
    
    rd_en = 1'b1;
    @(posedge clk); 
    rd_en = 0;
    @(posedge clk); #1; 
    
    if (dout_valid) begin $display("[%0t] TEST 3 FAILED: dout_valid went high on empty read.", $time); test_failed = 1'b1; $fatal(1); end
    
    if (!test_failed) $display("TEST 3 PASSED");

    // -------------------------------------------
    // Test 4: Single Error Correction
    // -------------------------------------------
    $display("\n[%0t] TEST 4: Single Error Correction (Data Bit)", $time);
    test_failed = 1'b0;
    
    din = 32'hCAFED00D;
    wr_en = 1'b1;
    queue_push(din);
    @(posedge clk);
    wr_en = 0;
    $display("[%0t]   Wrote: 0x%h", $time, din);

    rd_en = 1'b1;
    @(posedge clk); 
    rd_en = 0;
    
    // Error Injection
    #1;
    corrupted_word = u_dut.rd_word; // getting real word from internal port after trhe memory
    corrupted_word[10] = ~corrupted_word[10]; // one bit flip
    
    $display("[%0t]   INJECT: Forcing 1-bit error on internal rd_word[10]", $time);
    force u_dut.rd_word = corrupted_word;
    
    @(posedge clk); #1; // one cycle to register the corrupted word
    release u_dut.rd_word;

    // Check
    queue_pop(expected_data);
    $display("[%0t]   Read: 0x%h (Expected: 0x%h)", $time, dout, expected_data);

    if (!(dout_valid)) begin $display("[%0t] TEST 4 FAILED: dout_valid not high.", $time); test_failed = 1'b1; $fatal(1); end
    if (dout != expected_data) begin $display("[%0t] TEST 4 FAILED: Data was NOT corrected.", $time); test_failed = 1'b1; $fatal(1); end
    if (sec_err != 1) begin $display("[%0t] TEST 4 FAILED: sec_err was NOT high.", $time); test_failed = 1'b1; $fatal(1); end
    if (ded_err != 0) begin $display("[%0t] TEST 4 FAILED: ded_err was high.", $time); test_failed = 1'b1; $fatal(1); end

    if (!test_failed) $display("TEST 4 PASSED");

    // -------------------------------------------
    // Test 5: Double Error Detection
    // -------------------------------------------
    $display("\n[%0t] TEST 5: Double Error Detection (DED)", $time);
    test_failed = 1'b0;
    
    // Write
    din = 32'hDEADBEEF;
    wr_en = 1'b1;
    queue_push(din);
    @(posedge clk);
    wr_en = 0;
    $display("[%0t]   Wrote: 0x%h", $time, din);

    rd_en = 1'b1;
    @(posedge clk); 
    rd_en = 0;
    
    #1;
    corrupted_word = u_dut.rd_word;
    corrupted_word[10] = ~corrupted_word[10]; // one bit flip
    corrupted_word[20] = ~corrupted_word[20]; // one more bit flip
    
    $display("[%0t]   INJECT: Forcing 2-bit error on rd_word[10] and rd_word[20]", $time);
    force u_dut.rd_word = corrupted_word;
    
    @(posedge clk); #1; 
    release u_dut.rd_word;

    // Check 
    queue_pop(expected_data);
    $display("[%0t]   Read: 0x%h (Expected: 0x%h)", $time, dout, expected_data);

    if (!(dout_valid)) begin $display("[%0t] TEST 5 FAILED: dout_valid not high.", $time); test_failed = 1'b1; $fatal(1); end
    if (dout == expected_data) begin $display("[%0t] TEST 5 FAILED: Data was NOT corrupted (it should be).", $time); test_failed = 1'b1; $fatal(1); end
    if (sec_err != 0) begin $display("[%0t] TEST 5 FAILED: sec_err was high.", $time); test_failed = 1'b1; $fatal(1); end
    if (ded_err != 1) begin $display("[%0t] TEST 5 FAILED: ded_err was NOT high.", $time); test_failed = 1'b1; $fatal(1); end

    if (!test_failed) $display("TEST 5 PASSED");

    // -------------------------------------------
    // Test 6: Overall parity bit fliped only
    // -------------------------------------------
    $display("\n[%0t] TEST 6: Single Error Correction (p0 bit)", $time);
    test_failed = 1'b0;
    
    din = 32'hF0F0F0F0;
    wr_en = 1'b1;
    queue_push(din);
    @(posedge clk);
    wr_en = 0;
    $display("[%0t]   Wrote: 0x%h", $time, din);

    rd_en = 1'b1;
    @(posedge clk); 
    rd_en = 0;

    #1;
    corrupted_word = u_dut.rd_word;
    corrupted_word[0] = ~corrupted_word[0]; 
    
    $display("[%0t]   INJECT: Forcing 1-bit error on rd_word[0] (p0 bit)", $time);
    force u_dut.rd_word = corrupted_word;
    
    @(posedge clk); #1; 
    release u_dut.rd_word;

    // Check
    queue_pop(expected_data);
    $display("[%0t]   Read: 0x%h (Expected: 0x%h)", $time, dout, expected_data);

    if (!(dout_valid)) begin $display("[%0t] TEST 6 FAILED: dout_valid not high.", $time); test_failed = 1'b1; $fatal(1); end
    if (dout != expected_data) begin $display("[%0t] TEST 6 FAILED: Data was corrupted (it shouldn't be).", $time); test_failed = 1'b1; $fatal(1); end
    if (sec_err != 1) begin $display("[%0t] TEST 6 FAILED: sec_err was NOT high.", $time); test_failed = 1'b1; $fatal(1); end
    if (ded_err != 0) begin $display("[%0t] TEST 6 FAILED: ded_err was high.", $time); test_failed = 1'b1; $fatal(1); end

    if (!test_failed) $display("TEST 6 PASSED");

    // ------------------------
    // All Tests Passed
    // ------------------------
    $display("\n------------------------------------------------------");
    $display("All tests passed. $finish");
    $display("------------------------------------------------------");
    $finish;
  end

endmodule
