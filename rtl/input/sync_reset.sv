`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2025 10:47:17 PM
// Design Name: 
// Module Name: sync_reset
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


module sync_reset (
    input  logic clk,
    input  logic rst_n_async, // asynchronous external reset (active LOW if you want)
    output logic rst_sync     // synchronized reset output (active HIGH)
);

    logic rst_n_sync_ff1, rst_n_sync_ff2;

    // Synchronize the external reset into the clk domain
    always_ff @(posedge clk or negedge rst_n_async) begin
        if (~rst_n_async) begin
            rst_n_sync_ff1 <= 0;
            rst_n_sync_ff2 <= 0;
        end else begin
            rst_n_sync_ff1 <= 1;
            rst_n_sync_ff2 <= rst_n_sync_ff1;
        end
    end

    assign rst_sync = ~rst_n_sync_ff2; // Final synchronized active-HIGH reset

endmodule
