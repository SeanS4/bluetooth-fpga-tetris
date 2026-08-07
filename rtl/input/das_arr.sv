`timescale 1ns / 1ps 




//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04/25/2025  
// Module Name: das_arr_input
// Description: Single-move on tap; after DAS_FRAMES frames of holding, repeat every ARR_FRAMES
//////////////////////////////////////////////////////////////////////////////////

module das_arr_input #(
    parameter int DAS_FRAMES = 12,  // # of vga_frame_tick cycles before auto-shift
    parameter int ARR_FRAMES = 3    // # of vga_frame_tick cycles between auto-repeats
)(
    input  logic      clk,            
    input  logic      reset,          
    input  logic      vga_frame_tick, // pulses once per frame
    input  logic      key,            // raw button input
    output logic      action_tick     // one-cycle pulse when we want a move
);

    // internal state
    logic        key_d;           // previous raw key sample
    logic        pending_press;   // "I saw a tap; fire at next frame tick"
    logic [7:0]  das_cnt;         // frames waited so far in DAS
    logic [7:0]  arr_cnt;         // frames waited so far in ARR

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_d         <= 1'b0;
            pending_press <= 1'b0;
            das_cnt       <= 8'd0;
            arr_cnt       <= 8'd0;
            action_tick   <= 1'b0;
        end else begin
            // 1) catch any new key press (edge)
            if (key & ~key_d)
                pending_press <= 1'b1;

            // 2) update our delayed sample
            key_d <= key;

            // 3) default: no move this cycle
            action_tick <= 1'b0;

            // 4) on each frame tick, decide what to do
            if (vga_frame_tick) begin
                if (pending_press) begin
                    // first tap ? fire immediately
                    action_tick   <= 1'b1;
                    pending_press <= 1'b0;
                    das_cnt       <= 8'd1;     // start counting DAS
                    arr_cnt       <= 8'd0;
                end
                else if (key) begin
                    // still holding
                    if (das_cnt < DAS_FRAMES) begin
                        das_cnt <= das_cnt + 1;  // waiting out DAS
                    end else begin
                        // in auto-repeat zone
                        if (arr_cnt < ARR_FRAMES) begin
                            arr_cnt <= arr_cnt + 1;
                        end else begin
                            action_tick <= 1'b1;  
                            arr_cnt     <= 8'd1;   // restart ARR
                        end
                    end
                end
                else begin
                    // key released ? reset both timers
                    das_cnt <= 8'd0;
                    arr_cnt <= 8'd0;
                end
            end
        end
    end

endmodule