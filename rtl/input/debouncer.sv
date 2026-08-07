module sync_debouncer (
    input logic clk,        // Clock signal
    input logic rst,        // Reset signal
    input logic in_signal, // Input signal to debounce
    output logic pulse_out // Debounced output pulse
);

    // Internal state to track the previous state of the input signal
    logic in_signal_d, in_signal_d2;

    // Edge detection and pulse generation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            in_signal_d  <= 0;
            in_signal_d2 <= 0;
            pulse_out    <= 0;
        end else begin
            // Shift the input signal to detect edges
            in_signal_d  <= in_signal;
            in_signal_d2 <= in_signal_d;
            
            // Check for rising edge (signal transitions from low to high)
            if (~in_signal_d2 && in_signal_d) begin
                pulse_out <= 1;  // Generate pulse when signal rises
            end else begin
                pulse_out <= 0;  // Clear pulse after one clock cycle
            end
        end
    end

endmodule
