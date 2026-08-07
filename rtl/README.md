# RTL Directory

<p align="center">
  Navigate the SystemVerilog files by design area. All files are original work apart from vga_controller.sv which notes the authors in its comments.
</p>

<div align="center">

| Directory | Contents |
| --- | --- |
| [`bitstream/`](bitstream/) | Generated FPGA bitstream file used in the demo |
| [`constraints/`](constraints/) | FPGA pin assignments and timing constraints |
| [`game_logic/`](game_logic/) | Tetris control, collision, rotation, locking, row-clearing, and piece-selection logic |
| [`input/`](input/) | GPIO synchronization, pulse generation, and reset handling |
| [`ip/`](ip/) | Vivado IP configuration files for BRAM, clock generation, and HDMI output |
| [`rendering/`](rendering/) | VGA timing, color mapping, and rendering logic |
| [`testbenches/`](testbenches/) | Testbenches used for module verification |
| [`top/`](top/) | Top-level module logic |
