`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 01:05:46 AM
// Design Name: 
// Module Name: gravity_timer
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

module gravity_timer #(
    parameter CLK_FREQ = 100_000_000  // 100 MHz
)(
    input  logic         clk,
    input  logic         reset,
    input  logic  [3:0]  level,
    output logic         gravity_tick
);

    logic [31:0] counter;
    logic [31:0] tick_interval;

    // Lookup speed based on level - fixed to match intended delays
    always_comb begin
        case (level)
            0: tick_interval = 32'd300_000_000; // 3.00 sec
            1: tick_interval = 32'd240_000_000; // 2.40 sec
            2: tick_interval = 32'd210_000_000; // 2.10 sec
            3: tick_interval = 32'd180_000_000; // 1.80 sec
            4: tick_interval = 32'd150_000_000; // 1.50 sec
            5: tick_interval = 32'd120_000_000; // 1.20 sec
            6: tick_interval = 32'd90_000_000;  // 0.90 sec
            7: tick_interval = 32'd75_000_000;  // 0.75 sec
            8: tick_interval = 32'd60_000_000;  // 0.60 sec
            9: tick_interval = 32'd45_000_000;  // 0.45 sec
            10: tick_interval = 32'd30_000_000; // 0.30 sec
            11: tick_interval = 32'd24_000_000; // 0.24 sec
            12: tick_interval = 32'd18_000_000; // 0.18 sec
            13: tick_interval = 32'd12_000_000; // 0.12 sec
            14: tick_interval = 32'd6_000_000;  // 0.06 sec
            default: tick_interval = 32'd3_000_000;  // level 15+: 0.03 sec
        endcase
    end

    // Tick logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter       <= 0;
            gravity_tick  <= 0;
        end else begin
            if (tick_interval > 0 && counter == tick_interval) begin
                counter <= 0;
                gravity_tick <= 1;
            end else begin
                counter <= counter + 1;
                gravity_tick <= 0;
            end
        end
    end

endmodule