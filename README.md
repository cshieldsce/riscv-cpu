# 32-bit RISC-V CPU Core

This repository contains the design and verification files for a 32-bit RISC-V (RV32I) CPU core, implemented from scratch in SystemVerilog.

## Architecture Overview

The CPU implements a classic single-cycle Harvard architecture. It features a dedicated control unit handling 10 different control signals and a datapath capable of executing Arithmetic, Logic, Memory, Branch, and Jump operations in a single clock cycle.

```mermaid
graph LR
    %% --- Styling Definitions ---
    classDef stage fill:none,stroke:#555,stroke-width:1px,stroke-dasharray: 5 5
    
    %% --- STAGE: Instruction Fetch ---
    subgraph IF [Fetch]
        direction TB
        PCMUX{PC Mux}
        PC[PC]
        IMEM[Instruction<br/>Memory]
        PC_ADD[PC + 4]
    end

    %% --- STAGE: Decode ---
    subgraph ID [Decode]
        direction TB
        CTRL[Control<br/>Unit]
        RF[Register<br/>File]
        IMM[Imm<br/>Gen]
    end

    %% --- STAGE: Execute ---
    subgraph EX [Execute]
        direction TB
        ALU_SRC{ALU<br/>Src}
        ALU[ALU]
        BR_ADD[Branch<br/>Adder]
    end

    %% --- STAGE: Memory ---
    subgraph MEM [Memory]
        DMEM[Data<br/>Memory]
    end

    %% --- STAGE: Write Back ---
    subgraph WB [Write Back]
        WBMUX{Write<br/>Back}
    end

    %% ==========================================
    %% DATA PATH CONNECTIONS (Thick Solid Lines)
    %% ==========================================

    %% Fetch Path
    PCMUX ==> PC
    PC ==> IMEM
    PC ==> PC_ADD
    PC ==> BR_ADD

    %% Decode Path (Abstracting bit-slicing for clarity)
    IMEM ==> RF
    IMEM ==> IMM
    IMEM ==> CTRL

    %% Execute Path
    RF ==> ALU
    RF ==> ALU_SRC
    IMM ==> ALU_SRC
    IMM ==> BR_ADD
    ALU_SRC ==> ALU

    %% Memory Path
    RF ==> DMEM
    ALU ==> DMEM

    %% Writeback Path
    ALU ==> WBMUX
    DMEM ==> WBMUX
    PC_ADD ==> WBMUX
    WBMUX ==> RF

    %% PC Feedback Loops
    PC_ADD --> PCMUX
    BR_ADD --> PCMUX
    ALU --> PCMUX

    %% ==========================================
    %% CONTROL SIGNALS (Thin Dotted Lines)
    %% ==========================================
    
    CTRL -.-> RF
    CTRL -.-> ALU_SRC
    CTRL -.-> ALU
    CTRL -.-> DMEM
    CTRL -.-> WBMUX
    CTRL -.-> PCMUX

    %% ==========================================
    %% COLOR STYLING
    %% ==========================================
    
    style PCMUX fill:#06b6d4,stroke:#0891b2,stroke-width:2px,color:#fff
    style PC fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style IMEM fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    style PC_ADD fill:#3b82f6,stroke:#1e40af,stroke-width:2px,color:#fff
    
    style CTRL fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    style IMM fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#fff
    
    style RF fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff
    
    style ALU fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style BR_ADD fill:#ec4899,stroke:#be185d,stroke-width:2px,color:#fff
    style ALU_SRC fill:#6366f1,stroke:#4338ca,stroke-width:2px,color:#fff
    
    style DMEM fill:#10b981,stroke:#059669,stroke-width:2px,color:#fff
    
    style WBMUX fill:#6366f1,stroke:#4338ca,stroke-width:2px,color:#fff

    %% Apply Invisible Stage Styling
    class IF,ID,EX,MEM,WB stage
```

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
