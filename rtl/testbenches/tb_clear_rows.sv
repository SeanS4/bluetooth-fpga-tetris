`timescale 1ns / 1ps

module tb_clear_rows;

  logic          clk;
  logic          rst;
  logic          clear_check;
  logic  [4:0]   locked_piece_y;
  logic  [10:0]  clear_addr;
  logic  [7:0]   bram_dout;
  logic          clear_wren;
  logic  [7:0]   clear_data;
  logic          clear_done;

  logic [7:0] bram_mem [0:1199];
  logic [10:0] bram_addr_q;

  clear_rows uut (
    .clk(clk),
    .rst(rst),
    .clear_check(clear_check),
    .locked_piece_y(locked_piece_y),
    .clear_addr(clear_addr),
    .bram_dout(bram_dout),
    .clear_wren(clear_wren),
    .clear_data(clear_data),
    .clear_done(clear_done)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  // Simulate BRAM write on clear_wren
  always_ff @(posedge clk) begin
    if (clear_wren) begin
      bram_mem[clear_addr] <= clear_data;
      $display("[WRITE] Time=%0t : clear_addr=%0d, clear_data=0x%0h", $time, clear_addr, clear_data);
    end
  end

  // Simulate BRAM 1-cycle read latency
  always_ff @(posedge clk) begin
    if (rst)
      bram_addr_q <= 11'd0;
    else
      bram_addr_q <= clear_addr;
  end

  assign bram_dout = bram_mem[bram_addr_q];

  // === Tasks ===

  task initialize_bram();
    for (int i = 0; i < 1200; i++)
      bram_mem[i] = 8'h00;
    
    // Borders set to DIFFERENT value (8'hFF)
    for (int y = 4; y <= 25; y++) begin
      bram_mem[y*40 + 14] = 8'hFF;
      bram_mem[y*40 + 25] = 8'hFF;
    end
  endtask

  task fill_bottom_row();
    for (int x = 15; x <= 24; x++) begin
      bram_mem[24*40 + x] = 8'h80; // Fill playable area only
    end
  endtask

  task start_clear(input int start_y);
    locked_piece_y = start_y;
    clear_check = 1; #10; clear_check = 0;

    fork
      begin
        #500000; // Timeout
        $display("[TIMEOUT] UUT state: %0d", uut.state);
        $fatal("Timeout: clear_done never asserted!");
      end
      begin
        logic [3:0] prev_state;
        prev_state = uut.state;

        while (!clear_done) begin
          // Print once per interesting event (state transition)
          if (uut.state !== prev_state) begin
            prev_state = uut.state;

            case (uut.state)
              2: $display("[CHECK] Starting row check at time %0t", $time);           // START_ROW
              6: $display("[READ] Reading row data at time %0t", $time);               // SAMPLE_READ
              14: $display("[SHIFT] Shifting rows at time %0t", $time);                // SHIFT_WRITE
            endcase
          end

          #10;
        end
      end
    join_any
    disable fork;
  endtask

  task check_bottom_row_after_clear();
    $display("\n[CHECK] Verifying bottom row after clear...");

    // Check playable columns cleared
    for (int x = 15; x <= 24; x++) begin
      if (bram_mem[24*40 + x] !== 8'h00)
        $display("[FAIL] Playable cell (%0d,24) not cleared! Value=0x%0h", x, bram_mem[24*40 + x]);
      else
        $display("[PASS] Playable cell (%0d,24) cleared.", x);
    end

    // Check borders intact
    if (bram_mem[24*40 + 14] !== 8'hFF)
      $display("[FAIL] Left border at (14,24) was altered! Value=0x%0h", bram_mem[24*40 + 14]);
    else
      $display("[PASS] Left border (14,24) intact.");

    if (bram_mem[24*40 + 25] !== 8'hFF)
      $display("[FAIL] Right border at (25,24) was altered! Value=0x%0h", bram_mem[24*40 + 25]);
    else
      $display("[PASS] Right border (25,24) intact.");
  endtask

  // === Main test ===
  initial begin
    rst = 1;
    clear_check = 0;
    #20; rst = 0;

    $display("\n[SETUP] Initialize BRAM with borders");
    initialize_bram();

    $display("\n[SETUP] Fill bottom playable row (row 24)");
    fill_bottom_row();

    $display("\n[START CLEAR]");
    start_clear(24);

    check_bottom_row_after_clear();

    $display("\n[ALL TESTS DONE]");
    $finish;
  end

endmodule
