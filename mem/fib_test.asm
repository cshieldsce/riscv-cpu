addi x1, x0, 10      # x1 = 10 (Calculate 10th number)
addi x2, x0, 1       # x2 = 1  (Current)
addi x3, x0, 0       # x3 = 0  (Previous)
addi x4, x0, 1       # x4 = 1  (Counter)

loop:
beq  x4, x1, done    # If counter == 10, jump to done
add  x5, x2, x3      # x5 (temp) = Current + Previous
add  x3, x0, x2      # Previous = Current
add  x2, x0, x5      # Current = Temp
addi x4, x4, 1       # Counter++
jal  x0, loop        # Jump back to start of loop

done:
sw   x2, 0(x0)       # Store result (55 or 0x37) to Memory[0]