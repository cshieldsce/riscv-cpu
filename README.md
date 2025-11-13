# 32-bit RISC-V CPU Core

This repository contains the design and verification files for a 32-bit RISC-V (RV32I) CPU core, implemented from scratch in SystemVerilog.

## Architecture Overview

The CPU follows a classic RISC single-cycle architecture where each instruction completes in one clock cycle. The datapath flows from left to right: instructions are fetched from memory, decoded to extract operands and control signals, executed in the ALU, optionally access data memory, and finally write results back to the register file.

```mermaid
graph LR
    PC[PC] -->|addr| IMEM[Instruction<br/>Memory]
    IMEM -->|inst| DECODE[Decode &<br/>Control]
    
    DECODE -->|rs1,rs2| RF[Register<br/>File]
    DECODE -->|imm| ALU
    
    RF -->|data1| ALU[ALU]
    RF -->|data2| ALU
    
    ALU -->|addr| DMEM[Data<br/>Memory]
    ALU -->|result| MUX{WB Mux}
    DMEM -->|data| MUX
    
    MUX -->|wr_data| RF
    
    ALU -.branch.-> PC
    PC -.+4.-> PC
    
    style PC fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style IMEM fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style DECODE fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style RF fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    style ALU fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style DMEM fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style MUX fill:#6366f1,stroke:#4338ca,stroke-width:2px,color:#fff
```

## Features

The goal is to build a **complete and robust single-cycle RISC-V (RV32I) CPU core** that can execute all major instruction types.

* [x] **R-Type:** `add`, `sub`.
* [x] **I-Type (Immediate):** Add support for `addi`. This requires an Immediate Generator and a new MUX for the ALU.
* [x] **I-Type (Load):** Add support for `lw` (load word). This requires adding a Data Memory and a MUX for the write-back data.
* [x] **S-Type (Store):** Add support for `sw` (store word), which uses the Data Memory.
* [X] **B-Type (Branch):** Add support for `beq` (branch if equal). This requires new logic to check the ALU's Zero flag and update the PC.
* [ ] **J-Type (Jump):** Add support for `jal` (jump and link).
* [ ] **Complete Instructions:** Add all remaining instructions.
* [ ] **Final Verification:** Create a comprehensive test program that uses all supported instructions to verify the full design.

## Detailed Architecture

The complete datapath illustrates all major components and their interconnections. Instructions flow through the Instruction Memory to multiple decode units simultaneously: the Control Unit generates control signals, the Immediate Generator extracts immediate values, and the Register File reads source operands. The ALU Src mux selects between register data and immediates for the second ALU operand. After execution, results either access Data Memory for load/store operations or bypass directly to the Write Back mux, which selects the final value to write back to the register file.

```mermaid
graph LR
    PCMUX{PC<br/>Mux} --> PC[Program<br/>Counter]
    PC --> IMEM[Instruction<br/>Memory]
    
    IMEM --> CTRL[Control<br/>Unit]
    IMEM --> IMMGEN[Immediate<br/>Generator]
    IMEM --> REGFILE[Register<br/>File]
    
    CTRL --> ALUSRC{ALU<br/>Src}
    CTRL --> WBMUX{WB<br/>Mux}
    
    REGFILE --> ALU[ALU]
    REGFILE --> ALUSRC
    IMMGEN --> ALUSRC
    ALUSRC --> ALU
    
    ALU --> DMEM[Data<br/>Memory]
    REGFILE --> DMEM
    CTRL --> DMEM
    
    ALU --> WBMUX
    DMEM --> WBMUX
    WBMUX --> REGFILE
    
    PC --> PCMUX
    ALU --> PCMUX
    
    style PCMUX fill:#06b6d4,stroke:#0891b2,stroke-width:2px,color:#fff
    style PC fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style IMEM fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style CTRL fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style IMMGEN fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style REGFILE fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    style ALUSRC fill:#6366f1,stroke:#4338ca,stroke-width:2px,color:#fff
    style ALU fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style DMEM fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style WBMUX fill:#6366f1,stroke:#4338ca,stroke-width:2px,color:#fff
```

* **Arithmetic Logic Unit (ALU):** A 32-bit combinational ALU capable of performing ADD, SUB, AND, and OR operations.
* **Register File:** A 32x32 synchronous-write, asynchronous-read register file, correctly handling the zero-register (`x0`).
* **Instruction Fetch Stage:** A complete `IF_Stage` module with a Program Counter (`PC`) and Instruction Memory (`InstructionMemory`) that correctly fetches instructions from a program file.
* **Control Unit:** A combinational `ControlUnit` that decodes instruction `opcodes` and generates the correct control signals.
* **Single-Cycle CPU Core:** A top-level `SingleCycleCPU` module that integrates all components to fetch and execute a multi-instruction program.
* **Verification:** The core has been verified with a top-level, self-checking testbench (`single_cycle_cpu_tb.sv`) that initializes registers, runs a program from memory, and verifies the register values.

## Module Organization

The design is organized hierarchically with `SingleCycleCPU` as the top-level module that instantiates and connects all datapath components. The `IF_Stage` encapsulates instruction fetch logic (PC and Instruction Memory), while other components (Control Unit, Register File, ALU, Immediate Generator) are instantiated directly at the top level.

```mermaid
graph TD
    CPU[SingleCycleCPU]
    
    CPU --> IFS[IF_Stage]
    CPU --> CU[ControlUnit]
    CPU --> RF[RegFile]
    CPU --> ALU[ALU]
    CPU --> IG[ImmGen]
    
    IFS --> PC[PC]
    IFS --> IM[InstructionMemory]
    
    style CPU fill:#1e293b,stroke:#0f172a,stroke-width:3px,color:#fff
    style IFS fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style CU fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style RF fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    style ALU fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style IG fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style PC fill:#60a5fa,stroke:#2563eb,stroke-width:2px,color:#fff
    style IM fill:#60a5fa,stroke:#2563eb,stroke-width:2px,color:#fff
```

## Instruction Execution

Every instruction follows the same execution pipeline: fetch from instruction memory, decode and generate control signals, execute the operation in the ALU, access data memory if needed (loads/stores), write the result back to the register file, and update the PC.

```mermaid
graph LR
    START([Start]) --> FETCH[Fetch<br/>Instruction]
    FETCH --> DECODE[Decode &<br/>Control]
    DECODE --> EXECUTE[Execute<br/>ALU]
    EXECUTE --> DECISION{Memory?}
    
    DECISION -->|Yes| MEMORY[Memory<br/>Access]
    DECISION -->|No| WRITEBACK
    
    MEMORY --> WRITEBACK[Write<br/>Back]
    WRITEBACK --> UPDATE[Update<br/>PC]
    UPDATE -.next cycle.-> FETCH
    
    style START fill:#64748b,stroke:#475569,stroke-width:2px,color:#fff
    style FETCH fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style DECODE fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style EXECUTE fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style MEMORY fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style WRITEBACK fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    style DECISION fill:#eab308,stroke:#ca8a04,stroke-width:2px,color:#000
    style UPDATE fill:#06b6d4,stroke:#0891b2,stroke-width:2px,color:#fff
```

## Tools & Requirements

* **Simulator:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`) is used for compiling and simulating the design.
* **Language:** SystemVerilog (IEEE 1800-2012)

## Future Improvements (5-Stage Pipeline)

After the single-cycle core is complete and fully verified, the project will be extended to a 5-stage pipelined processor to improve performance.

* [ ] **Convert to 5-Stage Pipeline:** Add pipeline registers to separate the design into IF, ID, EX, MEM, and WB stages.
* [ ] **Hazard & Forwarding Unit:** Implement logic to handle data and control hazards.

## Running the project

To compile all the source files and the datapath testbench:

```bash
iverilog -g2012 -o cpu.out src/pc.sv src/instruction_memory.sv src/if_stage.sv src/alu.sv src/reg_file.sv src/control_unit.sv src/single_cycle_cpu.sv src/imm_gen.sv test/single_cycle_cpu_tb.sv
```

To run the simulation:

```bash
vvp sim.out
```
