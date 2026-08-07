`timescale 1ns / 1ps

module tb_piece_locker;
    logic clk = 0, reset = 0;
    logic lock_piece;
    logic [4:0] piece_x, piece_y;
    logic [2:0] shape_type;
    logic [3:0][3:0] shape_matrix;
    logic [11:0] lock_addr;
    logic [7:0] lock_data;
    logic lock_wren;
    logic done_locking;

    logic [7:0] fake_bram [0:1199];

    piece_locker dut (
        .clk(clk), .reset(reset), .lock_piece(lock_piece),
        .piece_x(piece_x), .piece_y(piece_y), .shape_type(shape_type), .shape_matrix(shape_matrix),
        .lock_addr(lock_addr), .lock_data(lock_data), .lock_wren(lock_wren), .done_locking(done_locking)
    );

    always #5 clk = ~clk;

    always_ff @(posedge clk) begin
        if (lock_wren)
            fake_bram[lock_addr] <= lock_data;
    end

    task automatic run_test(
        input [4:0] t_piece_x,
        input [4:0] t_piece_y,
        input [2:0] t_shape_type,
        input [15:0] t_shape_matrix
    );
        integer r, c, addr;
        begin
            piece_x = t_piece_x;
            piece_y = t_piece_y;
            shape_type = t_shape_type;
            lock_piece = 0;

            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    shape_matrix[r][c] = t_shape_matrix[15 - (r * 4 + c)];

            @(posedge clk); reset = 1;
            @(posedge clk); reset = 0;
            @(posedge clk); lock_piece = 1;
            wait (done_locking);
            @(posedge clk); lock_piece = 0;

            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    if (shape_matrix[r][c]) begin
                        addr = (piece_y + r) * 40 + (piece_x + c);
                        if (piece_x + c >= 15 && piece_x + c <= 24 && piece_y + r >= 5 && piece_y + r <= 24) begin
                            if (fake_bram[addr][7] !== 1'b1)
                                $display("[FAIL] Addr %0d (%0d,%0d): %b", addr, piece_x+c, piece_y+r, fake_bram[addr]);
                            else
                                $display("[PASS] Addr %0d (%0d,%0d): %b", addr, piece_x+c, piece_y+r, fake_bram[addr]);
                        end
                    end
                end
            end
            $display("-------------------------------------------\n");
        end
    endtask

    initial begin
        integer i, col, row;
        for (i = 0; i < 1200; i = i + 1) begin
            col = i % 40;
            row = i / 40;
            if (col < 15 || col > 24 || row < 5 || row > 24)
                fake_bram[i] = 8'h88;
            else
                fake_bram[i] = 8'h00;
        end

        run_test(15, 5, 3'd0, 16'b1111000000000000); // I shape flat at top left playable area
        run_test(20, 5, 3'd1, 16'b1100110000000000); // O shape near center top
        run_test(22, 10, 3'd2, 16'b0110011000000000); // S shape
        run_test(18, 15, 3'd3, 16'b0010011010000000); // Z shape
        run_test(16, 20, 3'd4, 16'b0100010011000000); // J shape
        run_test(21, 8, 3'd5, 16'b0010010011000000); // L shape
        run_test(17, 12, 3'd6, 16'b0100011010000000); // T shape

        // Randomized cases safely within bounds
        run_test(16, 6, 3'd0, 16'b1000100010001000);
        run_test(19, 10, 3'd1, 16'b1100110000000000);
        run_test(17, 18, 3'd2, 16'b0110011000000000);
        run_test(20, 14, 3'd3, 16'b0010011010000000);
        run_test(15, 22, 3'd4, 16'b0100010011000000);

        // New corner hugging tests
        run_test(15, 21, 3'd0, 16'b1111000000000000); // Horizontal I at bottom
        run_test(21, 5, 3'd1, 16'b1100110000000000); // O in top right
        run_test(15, 5, 3'd2, 16'b0110011000000000); // S touching left border
        run_test(22, 22, 3'd3, 16'b0010011010000000); // Z near bottom right
        run_test(16, 5, 3'd4, 16'b0100010011000000); // J barely inside top

        $display("All tests completed.");
        $finish;
    end
endmodule
