# Bluetooth-Controlled FPGA Tetris with HDMI Output

This system consists of Tetris game logic and HDMI video output logic implemented in SystemVerilog on FPGA hardware. User inputs are transmitted wirelessly from a gamepad within the Dabble iOS app to an ESP32-WROOM-32 microcontroller over Bluetooth. The ESP32 firmware maps those received gamepad inputs to GPIO outputs, which are wired into the FPGA’s GPIO ports and processed by the synthesized Tetris game logic. The final design does not use a soft processor. The complete game controller and video output generator are implemented directly as synthesized SystemVerilog hardware, with the ESP32 serving only as a wireless input bridge.

## Demo

<p align="center">
  <img src="images/tetris_start.png" alt="Tetris start screen" width="300">
</p>

[Watch the gameplay demo](media/demo.mp4)

## Features

The completed game supports left and right movement, 90-degree rotations, soft drops, hard drops, start, and reset inputs. Passive mechanics include automatic gravity, piece spawning, collision detection, piece locking, and the clearing of up to four adjacent rows simultaneously. The design also includes pseudorandom Tetris piece selection to vary piece spawning. Shaded block rendering gives each cube on the game board a 3-D appearance.

The ESP32 input path includes more than simply forwarding voltages through wired GPIO pins. FPGA-side modules synchronize the incoming signals, generate clean action pulses, and distinguish held buttons from individual button presses. This enables smoother gameplay and increases the responsiveness and accuracy of the wireless gamepad.

## Architecture Overview

The FPGA stores the persistent display state in dual-port BRAM as a 40 × 30 grid of 16 × 16-pixel cells. Game logic uses one memory port to update the board, while the rendering path uses the other to generate video continuously. The actively falling piece is rendered as an overlay, and the completed image is mapped to shaded RGB values before being transmitted through the HDMI output IP.

<p align="center">
  <img src="images/tetris_gameboard.png" alt="FPGA Tetris gameplay displayed over HDMI" width="300">
  <br>
  <em>HDMI rendering of Tetris gameplay board through FPGA logic.</em>
</p>

## Verification

Selected BRAM-writing modules, including piece locking and row clearing, were tested using SystemVerilog testbenches and waveform analysis during development. The integrated design was then validated on FPGA hardware using wireless input and HDMI output.

## Documentation

| Document | Description |
| --- | --- |
| [`docs/architecture.md`](docs/architecture.md) | A detailed description of the system architecture |
| [`docs/design_statistics.md`](docs/design_statistics.md) | FPGA resource utilization and implementation statistics |
| [`docs/verification.md`](docs/verification.md) | An outline of the verification and testing process |

## Repository Structure

| Path | Description |
| --- | --- |
| [`rtl/`](rtl/) | SystemVerilog source files for the FPGA design |
| [`esp32_firmware/`](esp32_firmware/) | ESP32 firmware for receiving Dabble Bluetooth input and driving GPIO outputs |
| [`docs/`](docs/) | Documentation as outlined above |
| [`images/`](images/) | Diagrams and screenshots |
| [`media/`](media/) | Gameplay demo video |

## Hardware

This project used an Urbana Board featuring a Xilinx Spartan-7 FPGA, an ESP32-WROOM-32 microcontroller, an HDMI display, and an iOS device running the gamepad interface within the Dabble app.