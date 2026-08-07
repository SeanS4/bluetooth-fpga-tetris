`timescale 1ns / 1ps

module tb_rotation_checker;

    logic clk = 0, reset = 0;
    logic [4:0] piece_x, piece_y;
    logic [10:0] rotate_addr;
    logic [7:0] bram_dout;
    logic rotate_request;
    logic rotation_success;
    logic rotation_done;
    logic [4:0] new_piece_x, new_piece_y;
    logic [1:0] current_rotation;
    logic [1:0] new_rotation;
    logic [2:0] shape_type;

    logic [7:0] fake_bram [0:1199];

    rotation_checker dut (
        .clk(clk), .reset(reset),
        .rotate_request(rotate_request),
        .piece_x(piece_x),
        .piece_y(piece_y),
        .current_rotation(current_rotation),
        .shape_type(shape_type),
        .bram_dout(bram_dout),
        .rotate_addr(rotate_addr),
        .rotation_done(rotation_done),
        .rotation_success(rotation_success),
        .new_piece_x(new_piece_x),
        .new_piece_y(new_piece_y),
        .new_rotation(new_rotation)
    );

    always #5 clk = ~clk; // 100MHz clock

    // Feed BRAM output based on DUT request
    always_comb begin
        bram_dout = fake_bram[rotate_addr];
    end

    task automatic run_test(
        input [4:0] t_piece_x,
        input [4:0] t_piece_y,
        input [2:0] t_shape_type,
        input [1:0] t_current_rotation,
        input bit expect_success,
        input string desc
    );
        begin
            piece_x = t_piece_x;
            piece_y = t_piece_y;
            shape_type = t_shape_type;
            current_rotation = t_current_rotation;
            rotate_request = 0;

            @(posedge clk); reset = 1;
            @(posedge clk); reset = 0;
            @(posedge clk);

            rotate_request = 1;
            @(posedge clk);
            rotate_request = 0;

            wait (rotation_done);
            @(posedge clk); // allow outputs to settle

            $display("Test (%s):", desc);
            $display("  rotation_success = %b", rotation_success);
            $display("  new_piece_x = %0d, new_piece_y = %0d, new_rotation = %0d", new_piece_x, new_piece_y, new_rotation);
            if (rotation_success == expect_success)
                $display("  [PASS]");
            else
                $display("  [FAIL]");
            $display("-------------------------------------------\n");
        end
    endtask

    initial begin
        integer i, col, row;

        // Initialize fake BRAM
        for (i = 0; i < 1200; i = i + 1) begin
            col = i % 40;
            row = i / 40;
            if (col < 15 || col > 24 || row < 5 || row > 26)
                fake_bram[i] = 8'h88; // Wall regions
            else
                fake_bram[i] = 8'h00; // Playable space
        end

        // Place some "fake blocks" to create forced collision for bad rotations
        fake_bram[5*40 + 24] = 8'h88; // Block at right wall
        fake_bram[7*40 + 19] = 8'h88; // Block somewhere in center

        // ==============================================
        // Rotation Tests - EXPECT SUCCESS (Valid Rotations)
        // ==============================================
        run_test(18, 5, 3'd6, 2'd0, 1, "Rotate T shape safely (no collision)");
        run_test(17, 6, 3'd5, 2'd1, 1, "Rotate L shape safely");

        // ==============================================
        // Rotation Tests - EXPECT COLLISION (Invalid Rotations)
        // ==============================================
        run_test(23, 5, 3'd6, 2'd1, 0, "Rotate T shape into right wall (collision)");
        run_test(18, 7, 3'd5, 2'd1, 0, "Rotate L shape into occupied block (collision)");

        $display("All rotation_checker tests completed.");
        $finish;
    end

endmodule