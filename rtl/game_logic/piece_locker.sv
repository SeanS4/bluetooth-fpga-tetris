`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 10:14:39 PM
// Design Name: 
// Module Name: piece_locker
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

// Handles locking a falling piece into BRAM one block per cycle

module piece_locker #(parameter ADDR_WIDTH = 12) (
    input  logic             clk,
    input  logic             reset,
    input  logic             lock_piece,           // Held high during locking
    input  logic [4:0]       piece_x,
    input  logic [4:0]       piece_y,
    input  logic [2:0]       shape_type,
    input  logic [3:0][3:0]  shape_matrix,

    // BRAM interface
    output logic [ADDR_WIDTH-1:0] lock_addr,
    output logic [7:0]            lock_data,
    output logic                  lock_wren,

    output logic                  done_locking        // High for one cycle when done
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP_WRITE,
        DO_WRITE,
        WAIT_RELEASE
    } lock_state_t;

    lock_state_t state;
    logic [1:0] row, col;
    logic [ADDR_WIDTH-1:0] next_addr;
    logic [7:0] next_data;
    logic [3:0] color_index;

    assign color_index = shape_type + 1;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            lock_wren <= 0;
            row <= 0;
            col <= 0;
            done_locking <= 0;
            lock_addr <= 0;
            lock_data <= 0;
        end else begin
            done_locking <= 0;
            lock_wren <= 0;

            case (state)
                IDLE: begin
                    if (lock_piece) begin
                        row <= 0;
                        col <= 0;
                        state <= SETUP_WRITE;
                    end
                end

                SETUP_WRITE: begin
                    if (shape_matrix[row][col]) begin
                        next_addr <= (piece_y + row) * 40 + (piece_x + col);
                        next_data <= {1'b1, color_index, 3'b000};
                    end else begin
                        next_addr <= 0;
                        next_data <= 0;
                    end
                    state <= DO_WRITE;
                end

                DO_WRITE: begin
                    if (shape_matrix[row][col]) begin
                        lock_addr <= next_addr;
                        lock_data <= next_data;
                        lock_wren <= 1;
                    end

                    if (col == 3) begin
                        col <= 0;
                        if (row == 3) begin
                            row <= 0;
                            done_locking <= 1;
                            state <= WAIT_RELEASE;
                        end else begin
                            row <= row + 1;
                            state <= SETUP_WRITE;
                        end
                    end else begin
                        col <= col + 1;
                        state <= SETUP_WRITE;
                    end
                end

                WAIT_RELEASE: begin
                    if (!lock_piece)
                        state <= IDLE;
                end
            endcase
        end
    end

endmodule
