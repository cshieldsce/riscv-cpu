# 32-bit RISC-V CPU Core

> This repository contains the design and verification files for a 5-Stage Pipelined 32-bit RISC-V (RV32I) CPU core, implemented from scratch in SystemVerilog.

## Architecture Overview

The CPU implements a 5-stage pipelined Harvard architecture (IF, ID, EX, MEM, WB). Its datapath is divided into stages to maximize instruction throughput. The design incorporates a Forwarding Unit to resolve data hazards via operand bypassing and Hazard Detection logic to manage pipeline stalls and control flow, ensuring correct execution of Arithmetic, Logic, Memory, Branch, and Jump operations. More detailed notes on the pipeline can be found [here](docs/pipeline_notes.md).

![alt text](docs/pipeline.png)

## Supported Instructions (RV32I)

The core has been validated against the **RISC-V Architectural Test Suite** and supports the following instruction types:

- **Arithmetic:** `add`, `sub`, `addi`, `slt`, `sltu`, `slti`, `sltiu`
- **Logic:** `and`, `or`, `xor`, `andi`, `ori`, `xori`
- **Shifts:** `sll`, `srl`, `sra`, `slli`, `srli`, `srai`
- **Memory:** `lw`, `sw`, `lb`, `lbu`, `lh`, `lhu`, `sb`, `sh`
- **Control Flow:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jal`, `jalr`
- **Large Constants:** `lui`, `auipc`

## Compliance Testing

This project utilizes [RISCOF](https://github.com/riscv-software-src/riscof) (RISC-V Architectural Test Framework) to ensure strict adherence to the RISC-V Unprivileged Specification.

### Testing Infrastructure
- **DUT Plugin:** Python plugin located in `compliance/` that compiles the RTL using Icarus Verilog and executes tests.
- **Reference Model:** Uses [Spike](https://github.com/riscv-software-src/riscv-isa-sim) (The official RISC-V ISA Simulator) for golden-model comparison.
- **Automated Verification:** Signatures are automatically extracted from the DUT's memory and compared against Spike's output.

### Running Compliance Tests Locally
To run the full suite (requires `riscof`, `spike`, and `riscv64-unknown-elf-gcc`):

```bash
chmod +x run_compliance.sh
./run_compliance.sh
```

## GitHub Actions CI/CD

The repository includes automated workflows to maintain code quality:
1.  **Basic CI (`ci.yml`)**: Runs to verify basic core functionality with custom assembly tests.
2.  **Compliance Suite (`compliance.yml`)**: A comprehensive workflow that builds Spike and runs the official RISC-V Architecture Test suite. 
    *   *Note: These are both configured with `workflow_dispatch` to be run manually or on PRs affecting core logic to optimize resource usage.*

## Tools & Requirements

- **Simulator:** [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`iverilog`) v12.0+
- **Toolchain:** `riscv64-unknown-elf-gcc` (for test compilation)
- **Framework:** `riscof` (for architectural compliance)
- **Language:** SystemVerilog (IEEE 1800-2012)

## Running the project

For simple verification (using the Fibonacci sequence test):

```bash
iverilog -g2012 -o sim.out riscv_pkg.sv src/*.sv test/pipelined_cpu_tb.sv
vvp sim.out +TEST=mem/fib_test.mem
```

## Roadmap

Phase 1: Single-Cycle Core (Completed)
Phase 2: 5-Stage Pipelining (Completed)
Phase 3: ISA Completeness (Completed)

Phase 4: C-Readiness & Hardening (Completed)

- [x] **Complex Branching:** Implement BNE, BLT, BGE, etc., to support standard C control flow.
- [x] **Compliance:** Integrated RISCOF and passed the official RV32I test suite.
- [x] **Memory Expansion:** Increased I-Mem and D-Mem to 4MB each to support large binaries.
- [x] **MMIO Hardening:** Standardized `tohost` (0x80001000) for test termination.

Phase 5: FPGA & Peripherals (Future)

- [ ] UART: Implement Serial Transmit (MMIO) for printf support.
- [ ] Physical Constraints: Map pins to the specific FPGA board.

## References

- [Computer Organization and Design | The Hardware/Software Interface | RISC-V Edition by David A. Patterson & John L. Hennessy | Chapter 4 - The Processor](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/books/HandP_RISCV.pdf)

- [The RISC-V Instruction Set Manual Volume I | Unprivileged Architecture](https://docs.riscv.org/reference/isa/_attachments/riscv-unprivileged.pdf)
