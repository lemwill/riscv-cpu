.section .text
.globl _start
_start:
    addi x1, x0, 10  # Set x1 to 10 (our comparison value)
    sw x1, 100(x0)     # Store the value of x1 at address 0
    nop
    nop
    lw x1, 100(x0)     # Load the value at address 0 into x3
    jal zero, _start

#_start:
    # If JAL works, we reach here and fall into an infinite loop.
#    addi x1, x0, 10  # Set x1 to 10 (our comparison value)
#reset_counter:
#    addi x2, x0, 0  # Set x2 to 0 (our comparison value)
#count:
#    addi x2, x2, 1   # Increment counter (x2)
#    beq x1, x2, reset_counter  # If counter (x2) equals 10, branch to 'end' label
#    jal zero, count
