# 8-bit to QPSK Signal Converter (FPGA)

## Overview

This FPGA-based system converts an 8-bit digital input into a QPSK (Quadrature Phase Shift Keying) modulated signal. The output is an 8-bit digital representation of the QPSK waveform, ready for conversion to analog using a DAC.

---

## How the System Works

### Input

- **8-bit digital data**: The system receives an 8-bit input, which determines the QPSK symbol to be generated.

### Processing

- The input data is mapped to QPSK symbols using digital logic.
- The system generates the corresponding QPSK waveform in digital form (8 bits wide).

### Output

- **8-bit digital QPSK signal**: This is the modulated QPSK signal in digital format.

---

## Digital to Analog Conversion

- The digital QPSK output can be connected to an **8-bit parallel-input DAC** (such as DAC0808 or AD9708).
- The DAC converts the digital signal into an analog QPSK waveform suitable for transmission or further analog processing.

**Recommended DAC:**  
- Use a fast, parallel 8-bit DAC for best results (e.g., DAC0808, AD9708).

---

## Usage

1. Provide an 8-bit digital input to the system.
2. The system outputs the corresponding QPSK-modulated signal as an 8-bit digital value.
3. Connect the output to an 8-bit DAC to obtain the analog QPSK signal.

---

**Note:**  
The system is fully digital. For analog output, a