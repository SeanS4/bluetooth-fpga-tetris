`timescale 1ns / 1ps
// draw border time 
module draw_border #(
    parameter WIDTH = 40,
    parameter HEIGHT = 30,
    parameter BORDER_X = 14,
    parameter BORDER_Y = 4,
    parameter BORDER_W = 12,
    parameter BORDER_H = 22
)(
    input  logic clk,
    input  logic rst,
    input  logic start_init,
    output logic done,

    output logic [10:0] init_addr,  // 0-1199
    output logic [7:0]  init_data,
    output logic        init_wren
);

    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        DONE
    } state_t;

    state_t state, next_state;

    logic [5:0] x, y;
    logic is_border;

  
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x <= 0;
            y <= 0;
        end else begin
            state <= next_state;
            if (state == WRITE) begin
                if (x == WIDTH - 1) begin
                    x <= 0;
                    y <= y + 1;
                end else begin
                    x <= x + 1;
                end
            end
        end
    end

    // is the current global (x, y) a border tile?
    always_comb begin
        is_border = (
            x == BORDER_X || x == BORDER_X + BORDER_W - 1 ||
            y == BORDER_Y || y == BORDER_Y + BORDER_H - 1
        ) && 
        (x >= BORDER_X && x < BORDER_X + BORDER_W &&
         y >= BORDER_Y && y < BORDER_Y + BORDER_H);
    end

    // need to write to entire screen
    assign init_addr = y * WIDTH + x;
    assign init_data = is_border ? 8'hC0 : 8'h00;
    assign init_wren = (state == WRITE);

    // FSM transitions
    always_comb begin
        next_state = state;
        done = 0;

        case (state)
            IDLE: if (start_init) next_state = WRITE;

            WRITE: if (y == HEIGHT - 1 && x == WIDTH - 1)
                next_state = DONE;

            DONE: begin
                done = 1;
                next_state = DONE;
            end
        endcase
    end

endmodule