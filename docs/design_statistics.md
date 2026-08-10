# Design Statistics

The final implementation achieved a compact resource footprint by synthesizing SystemVerilog modules which contained the entirety of the game logic. Vivado reported the following resource utilization, timing, and power results:

| Metric | Result |
| --- | --- |
| LUTs | 910 |
| DSPs | 0 |
| Memory (BRAM) | 0.50 |
| Flip-flops | 532 |
| Latches | 8 |
| Frequency | 139.33 MHz |
| Static power | 0.072 W |
| Dynamic power | 0.256 W |
| Total power | 0.329 W |

The eight reported latches are associated with data entering and leaving the generated BRAM IP core. No additional unintended latches were identified in the design.
