TC2:

Two phase clock system; all internal bus writes are done on positive clock edge, all reads are done on the negative edge.

Instruction format
    Bit 7: Operation type
    Bit 6: Operation type
    Bit 5: Address mode
    Bit 4: Address mode
    Bit 3: Sub-op
    Bit 2: Sub-op
    Bit 1: Sub-op
    Bit 0: Sub-op

Operation types:
    00: ALU
    01: Registers transfer
    10: Jump
    11: Stack

Address modes (targets):
    00: B register (A register when operation is B register primary)
    01: Sum register (Load operations only, illegal to write to S)
    10: Memory
    11: Immediate operand

MMU sub-ops:
    0001: Address buffer low byte load
    0010: Address buffer high byte load
    0011: Memory at address buffer to system bus (standard read)
    0100: System bus to memory at address buffer (standard write)
    0101: Memory at PC to {system bus/direct to CU} (op-read)

Register sub-ops:
    0001: A to target
    0010: Target to A
    0011: B to target
    0100: Target to B