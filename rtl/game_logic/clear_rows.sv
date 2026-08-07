`timescale 1ns / 1ps

module clear_rows #(
    parameter WIDTH = 10,
    parameter ROWS_TO_CHECK = 4
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         clear_check,
    input  logic [4:0]   locked_piece_y,

    output logic [10:0]  clear_addr,
    input  logic [7:0]   bram_dout,
    output logic         clear_wren,
    output logic [7:0]   clear_data,

    output logic         clear_done
);

    typedef enum logic [4:0] {
        IDLE,
        INIT,
        START_VALID,
        START_ROW,
        WAIT_ROW,
        ISSUE_READ,
        WAIT_READ,
        SAMPLE_READ,
        SET_EVAL_ROW,
        EVAL_ROW,
        CLEAR_PREP,
        CLEAR_WRITE,
        PREP_SHIFT,
        SHIFT_ISSUE_READ,
        SHIFT_WAIT_READ,
        SHIFT_SAMPLE_READ,
        SHIFT_WRITE,
        EVAL_SHIFT_WRITE,
        DONE
    } state_t;

    state_t state, next_state;

    logic [4:0]  current_y;
    logic [5:0]  col;
    logic [9:0]  nonzero_flags;
    logic full_row_found;
    logic [7:0] shift_data_buffer;
    logic [2:0] rows_checked;
    logic [1:0] rows_cleared;
    logic [4:0] target_shift_y;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            current_y        <= 0;
            col              <= 0;
            nonzero_flags    <= 0;
            clear_addr       <= 0;
            clear_wren       <= 0;
            clear_data       <= 8'h00;
            clear_done       <= 0;
            full_row_found   <= 0;
            shift_data_buffer<= 0;
            rows_checked     <= 0;
            target_shift_y   <= 0;
            rows_cleared     <= 0;
        end else begin
            state      <= next_state;
            clear_wren <= 0;
            clear_data <= 8'h00;
            clear_done <= 0;

            case (state)
                INIT: begin
                current_y        <= 0;
                col              <= 0;
                nonzero_flags    <= 0;
                clear_addr       <= 0;
                clear_wren       <= 0;
                clear_data       <= 8'h00;
                clear_done       <= 0;
                full_row_found   <= 0;
                shift_data_buffer<= 0;
                rows_checked     <= 0;
                target_shift_y   <= 0;
                rows_cleared     <= 0;
                end
                
                START_ROW: begin
                    current_y <= locked_piece_y + rows_checked;
                    col       <= 0;
                    nonzero_flags <= 0;
                end

                WAIT_ROW: begin
                    // Allow a cycle for BRAM to prepare
                end

                ISSUE_READ: begin
                    clear_addr <= (current_y * 40) + (15 + col);
                end

                WAIT_READ: begin
                    // Wait for BRAM read latency
                end

                SAMPLE_READ: begin
                    nonzero_flags[col] <= bram_dout[7];
                    col <= col + 1;
                end

                SET_EVAL_ROW: begin
                    full_row_found <= &nonzero_flags;
                    rows_checked <= rows_checked + 1;
                    col <= 0;
                end

                CLEAR_PREP: begin
                    clear_addr <= (current_y * 40) + (15 + col);
                    clear_data <= 8'h00;
                    clear_wren <= 1;
                end

                CLEAR_WRITE: begin
                    col <= col + 1;
                end

                PREP_SHIFT: begin
                    target_shift_y <= current_y;
                    current_y <= current_y - 1;
                    col <= 0;
                end

                SHIFT_ISSUE_READ: begin
                    clear_addr <= (current_y * 40) + (15 + col);
                end

                SHIFT_WAIT_READ: begin
                    // Wait for BRAM read latency
                end

                SHIFT_SAMPLE_READ: begin
                    if (current_y < 5)
                        shift_data_buffer <= 8'h00;
                    else
                        shift_data_buffer <= bram_dout;
                end

                SHIFT_WRITE: begin
                    clear_wren <= 1;
                    clear_addr <= (target_shift_y * 40) + (15 + col);
                    clear_data <= shift_data_buffer;
                    if (col == WIDTH-1) begin
                        current_y <= current_y - 1;
                        target_shift_y <= target_shift_y - 1;
                        col <= 0;
                    end else begin
                        col <= col + 1;
                    end
                end

                DONE: begin
                    clear_done <= 1;
                end

                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = IDLE;
        case (state)
            IDLE:               next_state = clear_check ? INIT : IDLE;
            INIT:               next_state = START_VALID;
            START_VALID:        next_state = ((rows_checked == ROWS_TO_CHECK) || (locked_piece_y + rows_checked) > 24) ? DONE: START_ROW;
            START_ROW:          next_state = WAIT_ROW;
            WAIT_ROW:           next_state = ISSUE_READ;
            ISSUE_READ:         next_state = WAIT_READ;
            WAIT_READ:          next_state = SAMPLE_READ;
            SAMPLE_READ:        next_state = (col == WIDTH - 1) ? SET_EVAL_ROW : ISSUE_READ;
            SET_EVAL_ROW:       next_state = EVAL_ROW;
            EVAL_ROW:           next_state = (full_row_found) ? CLEAR_PREP :  START_VALID;
            CLEAR_PREP:         next_state = CLEAR_WRITE;
            CLEAR_WRITE:        next_state = (col == WIDTH - 1) ? PREP_SHIFT : CLEAR_PREP;
            PREP_SHIFT:         next_state = SHIFT_ISSUE_READ;
            SHIFT_ISSUE_READ:   next_state = SHIFT_WAIT_READ;
            SHIFT_WAIT_READ:    next_state = SHIFT_SAMPLE_READ;
            SHIFT_SAMPLE_READ:  next_state = SHIFT_WRITE;
            SHIFT_WRITE:        next_state = EVAL_SHIFT_WRITE;
            EVAL_SHIFT_WRITE:   next_state = (col == WIDTH - 1) ? (target_shift_y > 6 ? SHIFT_ISSUE_READ : START_VALID) : SHIFT_ISSUE_READ;
            DONE:               next_state = IDLE;
            default:            next_state = IDLE;
        endcase
    end

endmodule
