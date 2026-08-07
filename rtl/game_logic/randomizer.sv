`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 08:50:32 PM
// Design Name: 
// Module Name: randomizer
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


module randomizer (
    input  logic clk,
    input  logic reset,
    input  logic enable,         // advance LFSR only when spawning
    output logic [2:0] random_out
);

    logic [2:0] lfsr_reg;

    always_ff @(posedge clk) begin
        if (reset)
            lfsr_reg <= 3'b001; // seed must not be 0
        else if (enable) begin
            // XOR feedback for 3-bit LFSR taps: x^3 + x + 1
            lfsr_reg <= {lfsr_reg[1:0], lfsr_reg[2] ^ lfsr_reg[0]};
        end
    end

    assign random_out = lfsr_reg;
endmodule
