`timescale 1ns / 1ps

module rotation_checker #(
    parameter GRID_WIDTH = 12,
    parameter GRID_HEIGHT = 22,
    parameter GRID_CORNER_X = 14,
    parameter GRID_CORNER_Y = 4
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        rotate_request,
    input  logic [4:0]  piece_x,
    input  logic [4:0]  piece_y,
    input  logic [1:0]  current_rotation,
    input  logic [2:0]  shape_type,
    input  logic [7:0]  bram_dout,

    output logic [10:0] rotate_addr,

    output logic        rotation_done,
    output logic        rotation_success,
    output logic [4:0]  new_piece_x,
    output logic [4:0]  new_piece_y,
    output logic [1:0]  new_rotation
);

    typedef enum logic [2:0] {
        IDLE, LOAD_SHAPE, ISSUE, WAIT, CHECK, NEXT_OFFSET, DONE
    } state_t;

    state_t state;
    logic [2:0] offset_idx;
    logic [4:0] trial_x, trial_y;
    logic [3:0][3:0] shape_matrix;
    logic [3:0] row, col;
    logic temp_valid;

    logic [4:0] x, y;
    logic [1:0] trial_rotation;

    logic rotate_latched;

    logic signed [2:0] dx, dy;

    shape_rom shape_table(
        .clk(clk),
        .shape_type(shape_type),
        .rotation(trial_rotation),
        .shape_matrix(shape_matrix)
    );

    srs_kick_rom kick_table(
        .shape_type(shape_type == 3'd0 ? 3'd0 : 3'd1),
        .from_rotation(current_rotation),
        .to_rotation(trial_rotation),
        .test_idx(offset_idx),
        .dx(dx),
        .dy(dy)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            rotation_done <= 0;
            rotation_success <= 0;
            rotate_latched <= 0;
        end else begin
            case (state)

                IDLE: begin
                    rotation_done <= 0;
                    rotation_success <= 0;
                    if (!rotate_latched && rotate_request) begin
                        rotate_latched <= 1;
                        trial_rotation <= (current_rotation == 2'd3) ? 2'd0 : current_rotation + 1;
                        offset_idx <= 0;
                        state <= LOAD_SHAPE;
                    end
                    if (!rotate_request) begin
                        rotate_latched <= 0;
                    end
                end

                LOAD_SHAPE: begin
                    row <= 0;
                    col <= 0;
                    temp_valid <= 1;
                    trial_x <= piece_x + dx;
                    trial_y <= piece_y + dy;
                    state <= ISSUE;
                end

                ISSUE: begin
                    x = trial_x + col;
                    y = trial_y + row;

                    if (shape_matrix[row][col]) begin
                        if (x < GRID_CORNER_X || x >= (GRID_CORNER_X + GRID_WIDTH) ||
                            y < GRID_CORNER_Y || y >= (GRID_CORNER_Y + GRID_HEIGHT)) begin
                            temp_valid <= 0;
                            $display("[Rotation Fail] Out of bounds at (x=%0d, y=%0d)", x, y);
                            state <= NEXT_OFFSET;
                        end else begin
                            rotate_addr <= y * 40 + x;
                            state <= WAIT;
                        end
                    end else begin
                        if (col == 3) begin
                            col <= 0;
                            if (row == 3) state <= DONE;
                            else row <= row + 1;
                        end else begin
                            col <= col + 1;
                        end
                    end
                end

                WAIT: begin
                    state <= CHECK;
                end

                CHECK: begin
                    if (shape_matrix[row][col] && bram_dout[7]) begin
                        temp_valid <= 0;
                        $display("[Rotation Fail] Collision at (x=%0d, y=%0d)", x, y);
                        state <= NEXT_OFFSET;
                    end else begin
                        if (col == 3) begin
                            col <= 0;
                            if (row == 3) state <= DONE;
                            else begin
                                row <= row + 1;
                                state <= ISSUE;
                            end
                        end else begin
                            col <= col + 1;
                            state <= ISSUE;
                        end
                    end
                end

                NEXT_OFFSET: begin
                    if (offset_idx == 4) begin
                        rotation_success <= 0;
                        rotation_done <= 1;
                        state <= IDLE;
                    end else begin
                        offset_idx <= offset_idx + 1;
                        state <= LOAD_SHAPE;
                    end
                end

                DONE: begin
                    if (temp_valid) begin
                        new_piece_x <= trial_x;
                        new_piece_y <= trial_y;
                        new_rotation <= trial_rotation;
                        rotation_success <= 1;
                    end else begin
                        rotation_success <= 0;
                    end
                    rotation_done <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule