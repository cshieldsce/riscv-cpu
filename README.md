# 32-bit RISC-V CPU Core

This repository contains the design and verification files for a 32-bit RISC-V (RV32I) CPU core, implemented from scratch in SystemVerilog.

## Architecture Overview

The CPU implements a classic single-cycle Harvard architecture. It features a dedicated control unit handling 10 different control signals and a datapath capable of executing Arithmetic, Logic, Memory, Branch, and Jump operations in a single clock cycle.

![alt text](docs/pipeline.png)

## Supported Instructions (RV32I)

The core passes comprehensive verification tests for the following instruction types:

- **Arithmetic:** `add`, `sub`, `addi`, `slt`, `sltu`, `slti`, `sltiu`
- **Logic:** `and`, `or`, `xor`, `andi`, `ori`, `xori`
- **Shifts:** `sll`, `srl`, `sra`, `slli`, `srli`, `srai`
- **Memory:** `lw` (Load Word), `sw` (Store Word)
- **Control Flow:** `beq` (Branch Equal), `jal` (Jump & Link), `jalr` (Jump Register)

## Module Organization

The project is structured with the top-level `SingleCycleCPU` instantiating specific pipeline stages and logic units.

```mermaid
graph TD
    CPU[SingleCycleCPU]
    
    CPU --> IFS[IF_Stage]
    CPU --> CU[ControlUnit]
    CPU --> RF[RegFile]
    CPU --> ALU[ALU]
    CPU --> IG[ImmGen]
    CPU --> DM[DataMemory]
    
    IFS --> PC[PC]
    IFS --> IM[InstructionMemory]
    
    style CPU fill:#1e293b,stroke:#0f172a,stroke-width:3px,color:#fff
    style IFS fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style CU fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style RF fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    style ALU fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style IG fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    style DM fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
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

- **Simulator:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`) is used for compiling and simulating the design.
- **Language:** SystemVerilog (IEEE 1800-2012)

## Running the project

The project includes a full regression testbench that verifies R-Type, I-Type, Memory, and Control Flow instructions in a single simulation run.

```bash
iverilog -g2012 -o cpu.out src/*.sv test/single_cycle_cpu_tb.sv
```

To run the simulation:

```bash
vvp sim.out
```

You can also compile a run the Fibonacci Sequence program by changing the memory file in `instruction_memory.sv` on `line 11`. After you change the memory file from `program.mem` to `fib_test.mem` you can compile `test/fib_test_tb.sv` and run it.

## Roadmap

Phase 1: Single-Cycle Core (Completed)

- [x] Implemented full datapath for R, I, S, B, and J type instructions.
- [x] Developed modular Control Unit with ALU decoding.
- [x] Verified functionality with Fibonacci and regression testbenches.

Phase 2: 5-Stage Pipelining (In Progress)

- [ ] **Pipeline Registers:** Insert registers between IF, ID, EX, MEM, and WB stages.
- [ ] **Hazard Unit:** Detect data hazards and insert bubbles (stalls).
- [ ] **Forwarding Unit:** Implement operand forwarding to resolve RAW hazards without stalling.
