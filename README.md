# 8-bit to QPSK Signal Converter (FPGA)

## Overview

This project implements a digital system on FPGA that takes an 8-bit input and generates a QPSK (Quadrature Phase Shift Keying) modulated signal. The output is an 8-bit digital value representing the QPSK waveform.

## How It Works

1. **Input:**  
   - The system receives an 8-bit digital value (from UART RX).

2. **Processing:**  
   - The input is mapped to QPSK symbols and processed through digital logic, including counters, multiplexers, a CORDIC module, and a register file.

3. **Output:**  
   - The result is an 8-bit digital QPSK signal, which can be sent to a DAC.

## Digital to Analog Conversion

- To get an analog QPSK signal, connect the 8-bit digital output to a parallel-input DAC (e.g., DAC0808 or AD9708).

## Usage

- Provide an 8-bit input.
- Press the start button to process.
- The system outputs the QPSK-modulated signal as an 8-bit digital value.
- Connect the output to a DAC for analog signal