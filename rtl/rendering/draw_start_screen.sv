`timescale 1ns / 1ps
module draw_start_screen #(
    parameter WIDTH  = 40,
    parameter HEIGHT = 30
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        start_init,
    output logic        done,
    output logic [10:0] init_addr,
    output logic [7:0]  init_data,
    output logic        init_wren
);

    typedef enum logic [1:0] { IDLE, WRITE, DONE } state_t;
    state_t state, next_state;

    logic [5:0] x, y;

    logic        is_block;
    logic [3:0]  palette_index;
    logic signed [6:0] ly;

    assign init_addr = y * WIDTH + x;
    assign init_data = is_block ? {1'b0, palette_index, 3'b000} : 8'h00;
    assign init_wren = (state == WRITE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x     <= 0;
            y     <= 0;
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

    always_comb begin
        ly = y - 12;

        is_block      = 0;
        palette_index = 4'd0;

        case (ly)
            0: begin
                if      (x >=  7 && x <=  9) palette_index = 4'd2; // T = red
                else if (x >= 12 && x <= 14) palette_index = 4'd7; // E = orange
                else if (x >= 17 && x <= 19) palette_index = 4'd5; // T = yellow
                else if (x >= 22 && x <= 23) palette_index = 4'd3; // R = green
                else if (x == 27)            palette_index = 4'd1; // I = cyan / light blue
                else if (x >= 30 && x <= 31) palette_index = 4'd6; // S = magenta / purple
            end

            1: begin
                if      (x ==  8)            palette_index = 4'd2; // T
                else if (x == 12)            palette_index = 4'd7; // E
                else if (x == 18)            palette_index = 4'd5; // T
                else if (x == 22 || x == 24) palette_index = 4'd3; // R
                else if (x == 27)            palette_index = 4'd1; // I
                else if (x == 30)            palette_index = 4'd6; // S
            end

            2: begin
                if      (x ==  8)            palette_index = 4'd2; // T
                else if (x >= 12 && x <= 14) palette_index = 4'd7; // E
                else if (x == 18)            palette_index = 4'd5; // T
                else if (x >= 22 && x <= 23) palette_index = 4'd3; // R
                else if (x == 27)            palette_index = 4'd1; // I
                else if (x >= 30 && x <= 31) palette_index = 4'd6; // S
            end

            3: begin
                if      (x ==  8)            palette_index = 4'd2; // T
                else if (x == 12)            palette_index = 4'd7; // E
                else if (x == 18)            palette_index = 4'd5; // T
                else if (x == 22 || x == 24) palette_index = 4'd3; // R
                else if (x == 27)            palette_index = 4'd1; // I
                else if (x == 31)            palette_index = 4'd6; // S
            end

            4: begin
                if      (x ==  8)            palette_index = 4'd2; // T
                else if (x >= 12 && x <= 14) palette_index = 4'd7; // E
                else if (x == 18)            palette_index = 4'd5; // T
                else if (x == 22 || x == 24) palette_index = 4'd3; // R
                else if (x == 27)            palette_index = 4'd1; // I
                else if (x >= 30 && x <= 31) palette_index = 4'd6; // S
            end
        endcase

        if (palette_index != 4'd0)
            is_block = 1;

        // Centered blue border.
        // Border spans x = 4..34 and y = 10..18.
        // Letters occupy y = 12..16.
        // There is one blank row above and below the letters.
        // There are two blank columns between the border and end letters.
        // There are two blank columns between each letter.
        if (
            (x == 4  && y >= 10 && y <= 18) ||
            (x == 34 && y >= 10 && y <= 18) ||
            (y == 10 && x >= 4  && x <= 34) ||
            (y == 18 && x >= 4  && x <= 34)
        ) begin
            is_block      = 1;
            palette_index = 4'd4; // dark blue border
        end
    end

    always_comb begin
        next_state = state;
        done       = 0;
        case (state)
            IDLE:  if (start_init)         next_state = WRITE;
            WRITE: if (y == 29 && x == 39) next_state = DONE;
            DONE:  begin
                done = 1;
                next_state = DONE;
            end
        endcase
    end

endmodule