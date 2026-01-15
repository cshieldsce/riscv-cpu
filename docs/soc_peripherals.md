# SoC Peripherals

This document describes the memory-mapped peripherals integrated into the riscv-5 SoC.

## Memory Map

| Peripheral | Base Address | End Address | Description |
| ---------- | ------------ | ----------- | ----------- |
| **LEDs**   | `0x80000000` | `0x80000003` | 4-bit output to onboard LEDs. |
| **UART TX**| `0x80000004` | `0x80000007` | UART Transmitter Data Register (Write-only). |
| **UART STA**| `0x80000008` | `0x8000000B` | UART Status Register (Read-only). |
| **TOHOST** | `0x80001000` | `0x80001003` | Test termination register (Compliance suite). |

---

## UART Transmitter (`uart_tx`)

The UART transmitter provides a simple serial interface for debugging and console output.

### 1. Data Register (`0x80000004`)
Writing a byte to this address triggers a transmission. 
- **Wait Requirement**: Software should check the Status Register before writing to ensure the UART is not busy. If written while busy, the data will be ignored.

### 2. Status Register (`0x80000008`)
Provides information about the UART's current state.
- **Bit 0 (`BUSY`)**: 
    - `1`: UART is currently transmitting a byte.
    - `0`: UART is idle and ready for a new byte.

### Software Example (C)

```c
#define UART_DATA   ((volatile char*)0x80000004)
#define UART_STATUS ((volatile int*) 0x80000008)

void uart_putc(char c) {
    // Wait until not busy
    while ((*UART_STATUS) & 1);
    // Send character
    *UART_DATA = c;
}

void uart_print(const char* s) {
    while (*s) {
        uart_putc(*s++);
    }
}
```

### Hardware Configuration
- **Baud Rate**: Default is 115200 (assuming 100MHz clock).
- **Format**: 8N1 (8 data bits, No parity, 1 stop bit).
