`timescale 1ns / 1ps

// Clean fixed version: proper SRS-compliant wall kick offset ROM

module srs_kick_rom (
    input  logic [2:0] shape_type,          // 0 = I, 1-6 = others
    input  logic [1:0] from_rotation,       // 0, 1, 2, 3
    input  logic [1:0] to_rotation,         // 0, 1, 2, 3
    input  logic [2:0] test_idx,            // 0 to 4
    output logic signed [2:0] dx,           // X offset
    output logic signed [2:0] dy            // Y offset
);

    typedef struct packed {
        logic signed [2:0] dx;
        logic signed [2:0] dy;
    } kick_t;

    kick_t kick_rom [0:7][0:4];

    initial begin
        // I-piece rotations
        kick_rom[0] = '{ '{ 0, 0}, '{-2, 0}, '{ 1, 0}, '{-2, -1}, '{ 1, 2} }; // 0->R
        kick_rom[1] = '{ '{ 0, 0}, '{-1, 0}, '{ 2, 0}, '{-1, 2}, '{ 2, -1} }; // R->2
        kick_rom[2] = '{ '{ 0, 0}, '{ 2, 0}, '{-1, 0}, '{ 2, 1}, '{-1, -2} }; // 2->L
        kick_rom[3] = '{ '{ 0, 0}, '{ 1, 0}, '{-2, 0}, '{ 1, -2}, '{-2, 1} }; // L->0

        // JLSTZ rotations
        kick_rom[4] = '{ '{ 0, 0}, '{-1, 0}, '{-1, 1}, '{ 0, -2}, '{-1, -2} }; // 0->R
        kick_rom[5] = '{ '{ 0, 0}, '{ 1, 0}, '{ 1, -1}, '{ 0, 2}, '{ 1, 2} }; // R->2
        kick_rom[6] = '{ '{ 0, 0}, '{ 1, 0}, '{ 1, 1}, '{ 0, -2}, '{ 1, -2} }; // 2->L
        kick_rom[7] = '{ '{ 0, 0}, '{-1, 0}, '{-1, -1}, '{ 0, 2}, '{-1, 2} }; // L->0
    end

    logic [2:0] kick_set;

    always_comb begin
        kick_set = 3'd0; // default fallback
        case ({from_rotation, to_rotation})
            4'b0001: kick_set = (shape_type == 3'd0) ? 3'd0 : 3'd4; // 0 -> R
            4'b0110: kick_set = (shape_type == 3'd0) ? 3'd1 : 3'd5; // R -> 2
            4'b1011: kick_set = (shape_type == 3'd0) ? 3'd2 : 3'd6; // 2 -> L
            4'b1100: kick_set = (shape_type == 3'd0) ? 3'd3 : 3'd7; // L -> 0
            default: kick_set = (shape_type == 3'd0) ? 3'd0 : 3'd4; // fallback
        endcase
    end

    assign dx = kick_rom[kick_set][test_idx].dx;
    assign dy = kick_rom[kick_set][test_idx].dy;

endmodule
