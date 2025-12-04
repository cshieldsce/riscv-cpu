# Project Notes

> random disorganized notes on this project taken while building it

## Forwarding Unit

This unit "spies" on the pipeline registers. If it sees that a later stage (MEM or WB) is writing to a register that the current stage (EX) needs, it will "forward" that data directly to the ALU, skipping the Register File.

### Problem! There is one specific case where forwarding is impossible: the Load-Use Hazard

Example:

```asm
lw  x1, 0(x2)   # 1. Load value from memory into x1
add x4, x1, x5  # 2. Use x1 immediately
```

1. **Cycle N**: The lw instruction is in the EX stage. It is calculating the address. The data is still in RAM. It hasn't been read yet.
2. **Cycle N**: The add instruction is in the ID stage. It needs the value of x1 right now to send to the ALU.

We cant forward the data because it doesn't exist inside the CPU yet. It will only be available at the end of the **MEM** stage.

### **How to fix this?**

Since we can't speed up the data fetch, we must slow down the pipeline. We can insert a "bubble" (a NOP) into the pipeline to delay the dependent instruction by one cycle.

To do this, you must do three things **simultaneously**:

1. **Freeze the PC**: Stop fetching new instructions.
2. **Freeze the IF/ID Register**: Keep the add instruction in the Decode stage so it can try again next cycle.
3. **Flush the ID/EX Register**: Turn the instruction currently moving into the Execute stage into a NOP (zeros) so it doesn't do anything harmful.

We can implement this into a new Hazard Unit

## Hazard Unit

This unit looks at the instruction in the Decode (ID) stage and the instruction in the Execute (EX) stage.

```logic
IF (Instruction in EX is a Load) AND (Destination of Load == Source 1 or Source 2 of ID instruction) THEN Stall.
```
