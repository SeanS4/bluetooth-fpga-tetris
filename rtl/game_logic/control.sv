`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 07:47:59 PM
// Design Name: 
// Module Name: control
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


module tetris_fsm (
    input  logic input_clk,
    input  logic reset,
    input  logic key_up, key_down, key_left, key_right, key_drop, key_start,
    input  logic gravity_tick,        // pulse from gravity timer
    input  logic left_valid, right_valid, down_valid, rotation_success, rotation_done, collision_checked,
    input  logic spawn_collision, spawn_checked, done_locking,     
    input  logic clear_done,       // true if rows need to be cleared
    input logic board_done,
    input logic game_start_done,   
    
    output logic board_init, game_init, spawn_piece, check_spawn,
    output logic move_left, move_right, move_down, rotate_piece,
    output logic check_left, check_right, check_down, check_rotate,
    output logic lock_piece,
    output logic game_over, check_clear,
    output logic clk,
    output logic [4:0] state_debug
);

    enum logic [4:0] {
        GAME_START,
        START,
        INIT,
        INIT_BOARD,
        SPAWN_CHECK,
        GAME_OVER,
        SPAWN,
        INPUT_GAURD,
        GAURD_CLEAR,
        INPUT_WAIT,
        PAUSE_1,
        DOWN_CHECK,
        DOWN,
        DROP_CHECK,
        DROP,
        RIGHT_CHECK,
        RIGHT,
        LEFT_CHECK,
        LEFT,
        ROTATE_CHECK,
        ROTATE,
        LOCK_DELAY,
        LOCK,
        CLEAR_CHECK,
        CLEAR_ANIM,
        SHIFT_ROWS,
        PAUSE_2
    } state, next_state;

    // State transition
    always_ff @ (posedge clk)
	begin
		if (reset) 
			state <= INIT;
		else 
			state <= next_state;
	end
 
 

//debug logic
always_comb begin
    case (state)
        GAME_START:     state_debug = 5'b00000;
        START:         state_debug = 5'b00001;
        INIT:          state_debug = 5'b00010;
        INIT_BOARD:    state_debug = 5'b00011;
        SPAWN_CHECK:   state_debug = 5'b00100;
        GAME_OVER:     state_debug = 5'b00101;
        SPAWN:         state_debug = 5'b00110;
        INPUT_WAIT:    state_debug = 5'b00111;
        PAUSE_1:         state_debug = 5'b01000;
        DOWN_CHECK:    state_debug = 5'b01001;
        DOWN:          state_debug = 5'b01010;
        DROP_CHECK:    state_debug = 5'b01011;
        DROP:          state_debug = 5'b01100;
        RIGHT_CHECK:   state_debug = 5'b01101;
        RIGHT:         state_debug = 5'b01110;
        LEFT_CHECK:    state_debug = 5'b01111;
        LEFT:          state_debug = 5'b10000;
        ROTATE_CHECK:  state_debug = 5'b10001;
        ROTATE:        state_debug = 5'b10010;
        LOCK_DELAY:    state_debug = 5'b10011;
        LOCK:          state_debug = 5'b10100;
        CLEAR_CHECK:   state_debug = 5'b10101;
        INPUT_GAURD:    state_debug = 5'b10110;
        PAUSE_2:    state_debug = 5'b10111;
        default:       state_debug = 5'b11111; // fallback for illegal state
    endcase
end
 
 
 //lock delay logic   
logic [5:0] lock_delay_counter; // Enough for up to 63 frames

always_ff @ (posedge clk) begin
if (reset)
        lock_delay_counter <= 0;
    else if (state == LOCK_DELAY)
        lock_delay_counter <= lock_delay_counter + 1;
    else
        lock_delay_counter <= 0;
end 

logic key_left_q, key_right_q, key_up_q;
logic key_left_d, key_right_d, key_up_d;

always_ff @(posedge clk) begin
    key_left_q <= key_left;
    key_right_q <= key_right;
    key_up_q <= key_up;
end

assign key_left_d = key_left & ~key_left_q;
assign key_right_d = key_right & ~key_right_q;
assign key_up_d = key_up & ~key_up_q;

logic moved_during_lock_delay;
assign moved_during_lock_delay = key_left_d || key_right_d || key_up_d;


    // conrtol signals ----------------------------------------------------
    always_comb begin
    // Default outputs
    clk = input_clk;
    game_init = 0;
    board_init = 0;
    spawn_piece = 0; 
    check_spawn = 0;
    move_left = 0; 
    move_right = 0; 
    move_down = 0; 
    rotate_piece = 0;
    check_left = 0; 
    check_right = 0;
    check_down = 0; 
    check_rotate = 0;
    lock_piece = 0;
    game_over = 0;  
    check_clear = 0;

    case (state)

        GAME_START: begin
            game_init = 1;
        end
        
        INIT_BOARD: begin
            board_init = 1;
        end
        
        SPAWN_CHECK: begin
            check_spawn = 1;
        end
        
          GAME_OVER: begin
            game_over = 1;
        end
        
        SPAWN: begin
            spawn_piece = 1;
        end
        
        DOWN_CHECK: begin
            check_down = 1;
        end
        
        DOWN: begin
            move_down = 1;
        end
        
        DROP_CHECK: begin
            check_down = 1;
        end
        
        DROP: begin
            move_down = 1;
        end
        
        LEFT_CHECK: begin
            check_left = 1;
        end
        
        LEFT: begin
            move_left = 1;
        end
        
        RIGHT_CHECK: begin
            check_right = 1;
        end
        
        RIGHT: begin
            move_right = 1;
        end
        
        ROTATE_CHECK: begin
            check_rotate = 1;
        end
   
        ROTATE: begin
            rotate_piece = 1;
        end

        LOCK: begin
            lock_piece = 1;
        end

        CLEAR_CHECK: begin
            check_clear = 1;
        end


        default: ;
    endcase
end

// State Transitions -------------------------------------------------------------
always_comb begin
    next_state = state;

    case (state)

        INIT: begin
            if (reset == 0)
                next_state = GAME_START;
        end

        GAME_START: begin
            if (game_start_done & key_start)
                next_state = INIT_BOARD;
        end

        INIT_BOARD: begin
            if (board_done)
                next_state = START;
        end

        START: begin
            next_state = SPAWN;   
        end

        SPAWN_CHECK: begin
            if (spawn_checked) 
                next_state = (spawn_collision) ? GAME_OVER : INPUT_GAURD;
        end
        
        SPAWN: begin
            next_state = SPAWN_CHECK;
        end
        
        GAME_OVER: begin
        if (key_start)
            next_state = INIT;
        end

        INPUT_GAURD: begin
    if ((key_drop | key_left | key_right | key_up | key_start) == 0) begin
        next_state = GAURD_CLEAR;
    end
end

        GAURD_CLEAR: begin
            next_state = INPUT_WAIT;
        end

        INPUT_WAIT: begin
            if (key_down || gravity_tick) begin
                next_state = DOWN_CHECK;
            end else if (key_up) begin
                next_state = ROTATE_CHECK;
            end else if (key_left) begin
                next_state = LEFT_CHECK;
            end else if (key_right) begin
                next_state = RIGHT_CHECK;
            end else if (key_drop) begin
                next_state = DROP_CHECK;
            end else if (key_start) begin
                next_state = PAUSE_1;
            end
        end


        PAUSE_1: begin
        if (key_start == 0)
            next_state = PAUSE_2;
        end 
        
        PAUSE_2: begin 
            if (key_start) 
                next_state = INPUT_GAURD;
        end
        
        DOWN_CHECK: begin
            if(collision_checked) 
                next_state = (down_valid) ? DOWN : LOCK_DELAY;
        end
        
        DOWN: begin
            next_state = INPUT_GAURD;
        end
        
        DROP_CHECK: begin
            if(collision_checked) 
                next_state = (down_valid) ? DROP : LOCK;
        end
        
        DROP: begin
            next_state = DROP_CHECK;
        end
        
        LEFT_CHECK: begin
            if(collision_checked) 
                next_state = (left_valid) ? LEFT : INPUT_GAURD;
        end
        
        LEFT: begin
            next_state = INPUT_GAURD;
        end
        
        RIGHT_CHECK: begin
            if(collision_checked) 
                next_state = (right_valid) ? RIGHT : INPUT_GAURD;
        end
        
        RIGHT: begin
            next_state = INPUT_GAURD;
        end
        
        ROTATE_CHECK: begin
            if(rotation_done) 
                next_state = (rotation_success) ? ROTATE : INPUT_GAURD;
        end
        
        ROTATE: begin
            next_state = INPUT_GAURD;
        end

        LOCK_DELAY: begin
            if (moved_during_lock_delay)
                next_state = INPUT_GAURD; // Cancel delay if moved
            else if (lock_delay_counter == 30) // about 0.5s at 60fps
                next_state = LOCK;
        end

        LOCK: begin
        if (done_locking)
            next_state = CLEAR_CHECK;
        end

        CLEAR_CHECK: begin
        if (clear_done)
            next_state = SPAWN;
        end

        default: next_state = INIT;
    endcase
end       
endmodule