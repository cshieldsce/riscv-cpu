# Theory of Operation: RISC-V 5-Stage Pipelined CPU

## 1. Architecture Overview

The `riscv-5` core is a classic 5-stage pipelined processor implementing the **RV32I** base integer instruction set. It is designed for modularity, supporting configurable data width (`XLEN`) and address width (`ALEN`) via the SystemVerilog package `riscv_pkg`.

### Pipeline Stages

1.  **IF (Instruction Fetch):**
    *   Fetches the instruction from memory pointed to by the PC.
    *   Updates the PC to `PC + 4` (default) or the target address (branch/jump).
    *   **IF/ID Register:** Captures the instruction and PC.

2.  **ID (Instruction Decode):**
    *   Decodes the opcode, funct3, and funct7 fields.
    *   Reads source operands (`rs1`, `rs2`) from the Register File.
    *   Generates immediate values (`ImmGen`).
    *   **Control Unit:** Generates control signals for ALU, Memory, and Writeback.
    *   **Hazard Detection:** Detects Load-Use hazards and stalls the pipeline.
    *   **Early JAL Resolution:** Resolves Unconditional Jumps (JAL) immediately in this stage to reduce branch penalty.

3.  **EX (Execute):**
    *   Performs arithmetic and logical operations (`ALU`).
    *   Calculates effective addresses for Load/Store.
    *   **Branch Resolution:** Resolves Conditional Branches (BEQ, BNE, etc.) and JALR.
    *   **Forwarding Unit:** Detects data hazards and forwards results from MEM or WB stages to ALU inputs to avoid stalls.

4.  **MEM (Memory Access):**
    *   Accesses Data Memory for Load and Store instructions.
    *   Handles MMIO (Memory Mapped I/O) writes.

5.  **WB (Writeback):**
    *   Writes the result (ALU result, Memory data, or PC+4) back to the Register File.

## 2. Split-Jump Mechanism

To optimize performance, Jump instructions are handled differently depending on their type:

*   **JAL (Jump and Link):**
    *   Resolved in the **ID (Decode)** stage.
    *   Since the target is `PC + Immediate`, it can be calculated immediately after fetch.
    *   **Flush:** Only the **IF** stage (instruction currently being fetched) needs to be flushed. This results in a 1-cycle penalty (or 0 if predicted, but here we assume static not-taken).

*   **JALR (Jump and Link Register) & Branches:**
    *   Resolved in the **EX (Execute)** stage.
    *   Requires reading a register value (`rs1`), which may depend on previous instructions (data hazards).
    *   **Flush:** Both **IF** and **ID** stages must be flushed if the branch is taken. This results in a 2-cycle penalty.

## 3. Memory Map

The processor uses a flat 32-bit address space (configurable via `ALEN`).

| Address Range          | Description                  |
| ---------------------- | ---------------------------- |
| `0x0000_0000` - `...`  | Instruction & Data Memory    |
| `0xFFFF_FFF0`          | **MMIO LED Register** (Write-only) |

*   **MMIO LED:** Writing to address `0xFFFF_FFF0` updates the 4-bit LED output port (`leds_out`). Only the lower 4 bits of the write data are used.

## 4. Modularity and Configuration

The core is designed to be agnostic to the specific XLEN (32-bit or 64-bit), although the current implementation focuses on RV32I.

### `riscv_pkg.sv`

All architectural parameters are defined in `riscv_pkg.sv`:

*   `XLEN`: Data width (Register size, ALU width). Default is `32`.
*   `ALEN`: Address width. Default is `32`.
*   `MMIO_LED_ADDR`: The memory-mapped address for LEDs.

To switch to a 64-bit implementation (RV64I base), one would theoretically change `XLEN` to `64` and update the `ALU` and `ImmGen` logic to handle 64-bit specific operations (like `addw`, `ld`), though the current logic primarily supports the 32-bit subset genericized to `XLEN`.
