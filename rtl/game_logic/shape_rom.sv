`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 11:35:59 PM
// Design Name: 
// Module Name: shape_rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// // Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// shape_rom.sv
// Provides pre-rotated 4x4 shapes for all 7 Tetris pieces (I, O, T, S, Z, J, L)

module shape_rom (
    input  logic        clk,
    input  logic [2:0]  shape_type,        // 0-6 (I, O, T, S, Z, J, L)
    input  logic [1:0]  rotation,          // 0-3 (0°, 90°, 180°, 270°)
    output logic [3:0][3:0] shape_matrix   // Unpacked 4x4 matrix
);

    // ROM: 7 shapes × 4 rotations = 28 entries
    logic [15:0] shapes [0:27];

    // I-piece (horizontal line is rotation 0)
    initial begin
        shapes[ 0] = 16'b0000111100000000; // I0
        shapes[ 1] = 16'b0010001000100010; // I90
        shapes[ 2] = 16'b0000000011110000; // I180
        shapes[ 3] = 16'b0100010001000100; // I270

        // O-piece (square)
        shapes[ 4] = 16'b0110011000000000; // O0
        shapes[ 5] = 16'b0110011000000000; // O90
        shapes[ 6] = 16'b0110011000000000; // O180
        shapes[ 7] = 16'b0110011000000000; // O270

        // T-piece
        shapes[ 8] = 16'b0100111000000000; // T0
        shapes[ 9] = 16'b0100011001000000; // T90
        shapes[10] = 16'b0000111001000000; // T180
        shapes[11] = 16'b0100110001000000; // T270

        // S-piece
        shapes[12] = 16'b0110110000000000; // S0
        shapes[13] = 16'b0100011000100000; // S90
        shapes[14] = 16'b0000011011000000; // S180
        shapes[15] = 16'b1000110001000000; // S270

        // Z-piece
        shapes[16] = 16'b1100011000000000; // Z0
        shapes[17] = 16'b0010011001000000; // Z90
        shapes[18] = 16'b0000110001100000; // Z180
        shapes[19] = 16'b0100110010000000; // Z270

        // J-piece
        shapes[20] = 16'b1000111000000000; // J0
        shapes[21] = 16'b0110010001000000; // J90
        shapes[22] = 16'b0000111000100000; // J180
        shapes[23] = 16'b0100010011000000; // J270

        // L-piece
        shapes[24] = 16'b0010111000000000; // L0
        shapes[25] = 16'b0100010001100000; // L90
        shapes[26] = 16'b0000111010000000; // L180
        shapes[27] = 16'b1100010001000000; // L270
    end

    logic [15:0] shape_bits;
    assign shape_bits = shapes[shape_type * 4 + rotation];

    // Combinational unpacked 4x4 matrix (no delay)
    always_comb begin
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                shape_matrix[r][c] = shape_bits[15 - (r * 4 + c)];
            end
        end
    end

endmodule
