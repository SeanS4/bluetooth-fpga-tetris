`timescale 1ns / 1ps

module collision_checker #(
    parameter GRID_WIDTH = 12,
    parameter GRID_HEIGHT = 22,
    parameter GRID_CORNER_X = 14,
    parameter GRID_CORNER_Y = 4
) (
    input  logic        clk,
    input  logic        reset,

    input  logic [4:0]  piece_x,
    input  logic [4:0]  piece_y,
    input  logic [3:0][3:0] shape_matrix,

    output logic [10:0] collision_addr,
    input  logic [7:0]  bram_dout,

    input  logic        check_left,
    input  logic        check_right,
    input  logic        check_down,
    input  logic        check_spawn,

    output logic        valid_left,
    output logic        valid_right,
    output logic        valid_down,
    output logic        collision_spawn,
    output logic        done_spawn,
    output logic        done
);

    typedef enum logic [2:0] {
        IDLE, ISSUE, WAIT, CHECK, DONE
    } state_t;

    state_t state;
    logic [3:0] r, c;
    logic [4:0] test_x, test_y;
    logic [10:0] grid_index;

    logic temp_valid;
    logic [1:0] direction;
    logic spawn_mode;

    logic issued_check;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            valid_left <= 0;
            valid_right <= 0;
            valid_down <= 0;
            collision_spawn <= 0;
            done_spawn <= 0;
            done <= 0;
            issued_check <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    done_spawn <= 0;
                    issued_check <= 0;
                    valid_left <= 0;
                    valid_right <= 0;
                    valid_down <= 0;
                    collision_spawn <= 0;

                    if (!issued_check && (check_left || check_right || check_down || check_spawn)) begin
                        r <= 0;
                        c <= 0;
                        temp_valid <= 1;
                        issued_check <= 1;
                        spawn_mode <= check_spawn;
                        if (check_left)      direction <= 2'd0;
                        else if (check_right) direction <= 2'd1;
                        else if (check_down)  direction <= 2'd2;
                        state <= ISSUE;
                    end
                end

                ISSUE: begin
                    logic [4:0] tmp_x, tmp_y;
                    if (shape_matrix[r][c]) begin
                        if (spawn_mode) begin
                            tmp_x = piece_x + c;
                            tmp_y = piece_y + r;
                        end else begin
                            case (direction)
                                2'd0: begin tmp_x = piece_x + c - 1; tmp_y = piece_y + r; end
                                2'd1: begin tmp_x = piece_x + c + 1; tmp_y = piece_y + r; end
                                2'd2: begin tmp_x = piece_x + c;     tmp_y = piece_y + r + 1; end
                            endcase
                        end

                        if (tmp_x <= GRID_CORNER_X || tmp_x >= (GRID_CORNER_X + GRID_WIDTH - 1)  ||
                            tmp_y <= GRID_CORNER_Y || tmp_y >= (GRID_CORNER_Y + GRID_HEIGHT - 1)) begin
                            temp_valid <= 0;
                        end else begin
                            grid_index <= tmp_y * 40 + tmp_x;
                            collision_addr <= tmp_y * 40 + tmp_x;
                        end

                        test_x <= tmp_x;
                        test_y <= tmp_y;
                        state <= WAIT;
                    end else begin
                        if (c == 3) begin
                            c <= 0;
                            if (r == 3) state <= DONE;
                            else r <= r + 1;
                        end else c <= c + 1;
                    end
                end

                WAIT: state <= CHECK;

                CHECK: begin
                    if (bram_dout[7]) temp_valid <= 0;
                    if (c == 3) begin
                        c <= 0;
                        if (r == 3) state <= DONE;
                        else r <= r + 1;
                    end else c <= c + 1;
                    state <= ISSUE;
                end

                DONE: begin
                    if (spawn_mode) begin
                        collision_spawn <= ~temp_valid;
                        done_spawn <= 1;
                    end else begin
                        done <= 1;
                        case (direction)
                            2'd0: valid_left <= temp_valid;
                            2'd1: valid_right <= temp_valid;
                            2'd2: valid_down <= temp_valid;
                        endcase
                    end
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
