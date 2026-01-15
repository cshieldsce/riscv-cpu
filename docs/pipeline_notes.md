# Pipeline Notes

> still in progess; writing as i finish the pipeline

## Pipeline Registers

The pipeline register is like the handoff zone in a relay race.

- **Before the register**: The current stage (e.g., Fetch) is doing its work.
- **At the clock edge**: The runner hands the baton (data) to the next runner.
- **After the register**: The previous stage is free to start a new instruction, while the next stage (e.g., Decode) starts working on the data it just received.

Without these registers, signals would race from the beginning to the end of the CPU in one cycle, forcing the clock to run very slowly. With these registers, we "save" the work done so far, allowing every stage to work on a different instruction simultaneously.

### <ins>Implementation</ins>

The implementation in `src/pipeline_reg.sv` is a standard D Flip-Flop with Enable and Clear.

```sv
module PipelineRegister #(parameter WIDTH = 32)(
    input  logic clk, rst, en, clear,
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);
```

It has three critical modes used for controlling the pipeline:

1. **Normal Operation** (`en=1`, `clear=0`): On the clock edge, out becomes in. The instruction moves to the next stage.
2. **Stall** (`en=0`): The register ignores the input and keeps holding the old value.
    - Used for **Hazards**: "Freeze" the instruction in the **Decode** stage when you detect a Load-Use hazard.
3. **Flush / Bubble** (`clear=1`): The register sets out to 0 (nop).
    - Used for **Control Hazards**: If a branch is taken, "flush" the wrong instructions currently in the pipeline by clearing their registers.

### <ins>Registers</ins>

| Register | Name | What data does it transfer? |
| -------- | ---- | --------------- |
| **IF/ID** | `if_id_reg` | The 32-bit instruction and the PC where it was found. It bridges **Fetch** and **Decode**. |
| **ID/EX** | `id_ex_reg` | Read values from registers (`rs1`, `rs2`), the immediate value, and Control Signals (like `ALUControl`). It bridges **Decode** and **Execute**. |
| **EX/MEM** | `ex_mem_reg` | The ALU result (math or address) and the data to write to memory (for stores). It bridges **Execute and Memory**. |
| **MEM/WB** | `mem_wb_reg` | The data read from memory or the final ALU result, ready to be written back to the register file. |

> TLDR; its just a dumb storage box

## Forwarding Unit

This unit "spies" on the pipeline registers. If it sees that a later stage (**MEM** or **WB**) is writing to a register that the current stage (**EX**) needs, it will "forward" that data directly to the ALU, skipping the Register File.

**Example**:
The result of an instruction (like `add x1, x2, x3`) is calculated in the **EX** stage. The next instruction needs it immediately. Instead of waiting for it to be written to the Register File (**WB** stage), we "forward" the wire directly from the pipeline register back to the ALU input.

### <ins>Implementation</ins>

The implementation in `src/forwarding_unit.sv` compares the registers used by the current instruction against the registers written by the previous two instructions.

**Case A: The "EX Hazard" (1 Cycle Delay)**:

- **Scenario**: `add x1`, ... followed immediately by `sub ..., x1`.
- **Logic**: If the instruction in **MEM** is writing to a register (`ex_mem_rd`) that matches source (`id_ex_rs1`), grab the data from the **EX/MEM** register.

```sv
if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) begin
    forward_a = 2'b10; // Select data from EX/MEM pipeline register
end
```

**Case B: The "MEM Hazard" (2 Cycle Delay)**:

- **Scenario**: `add x1`, ..., then `nop`, then `sub ..., x1`.
- **Logic**: If the instruction in **WB** is writing to source, grab it from the **MEM/WB** register.

```sv
if (mem_wb_reg_write && ... && !(ex_mem_reg_write ...)) begin
    forward_a = 2'b01; // Select data from MEM/WB pipeline register
end
```

The "Double Hazard" Check: Note the extra condition `&& !(ex_mem_reg_write ...)`. This is critical. If both previous instructions write to `x1`, we want the most recent one (the **EX** Hazard), not the older one (**MEM** Hazard).

### <ins>Control</ins>

In `src/pipelined_cpu.sv`, these forward_a and forward_b signals control 3-way MUXes placed before the ALU.

| Signal Value | Source | Meaning |
| ----------- | ----------- | ----- |
| `2'b00` | `id_ex_read_data`   | No Forwarding. Use value from Register File (normal). |
| `2'b10` | `ex_mem_alu_result` | EX Hazard. Use the result calculated just 1 cycle ago. |
| `2'b01` | `wb_write_data`     | Use the result calculated 2 cycles ago. |

### <ins>Problem!</ins> There is one specific case where forwarding is impossible: the Load-Use Hazard

**Example**:

```asm
lw  x1, 0(x2)   # 1. Load value from memory into x1
add x4, x1, x5  # 2. Use x1 immediately
```

1. **Cycle N**: The lw instruction is in the EX stage. It is calculating the address. The data is still in RAM. It hasn't been read yet.
2. **Cycle N**: The add instruction is in the ID stage. It needs the value of x1 right now to send to the ALU.

We cant forward the data because it doesn't exist inside the CPU yet. It will only be available at the end of the **MEM** stage.

### **How to fix this?**

Since we can't speed up the data fetch, we must slow down the pipeline. We can insert a "bubble" (a NOP) into the pipeline to delay the dependent instruction by one cycle.

To do this, we must do three things **simultaneously**:

1. **Freeze the PC**: Stop fetching new instructions.
2. **Freeze the IF/ID Register**: Keep the add instruction in the Decode stage so it can try again next cycle.
3. **Flush the ID/EX Register**: Turn the instruction currently moving into the Execute stage into a NOP (zeros) so it doesn't do anything harmful.

We can implement this into our new Hazard Unit

## Hazard Unit

This unit looks at the instruction in the Decode (ID) stage and the instruction in the Execute (EX) stage.

```logic
IF (Instruction in EX is a Load) AND (Destination of Load == Source 1 or Source 2 of ID instruction) THEN Stall.
```

## FPGA Silicon Adaptation (BRAM Timing)

To support real FPGA hardware, the memory architecture has been adapted to use **Synchronous Block RAM (BRAM)**, which has a 1-cycle read latency.

### 1. Instruction Memory (Fetch)
- **Old Behavior**: Combinational read. Address in cycle N -> Data in cycle N.
- **New Behavior**: Synchronous read. Address in cycle N -> Data in cycle N+1.
- **Impact**: The output of `InstructionMemory` effectively acts as the `Instruction` field of the **IF/ID Pipeline Register**.
- **Changes**:
    - `InstructionMemory` output is connected *directly* to the `ID_Stage`.
    - The `IF_ID` register's `Instruction` field is bypassed/ignored.
    - `imem_en` signal added to control stalls (connected to `~stall_id`).

### 2. Data Memory (Load/Store)
- **Old Behavior**: Combinational read. Address in EX stage -> Data valid in MEM stage.
- **New Behavior**: Synchronous read. Address in MEM stage -> Data valid in WB stage.
- **Impact**: The output of `DataMemory` effectively acts as the `ReadData` field of the **MEM/WB Pipeline Register**.
- **Changes**:
    - `DataMemory` output is connected *directly* to the Writeback Mux.
    - The `MEM/WB` register's `ReadData` field is bypassed.
    - Writes now use Byte Enables (`be`) for true hardware support.

