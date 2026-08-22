Two phase clock system; all internal bus writes are done on positive clock edge, all reads are done on the negative edge.

Instruction format
    Bit 0: Operation type
    Bit 1: Operation type
    Bit 2: Address mode
    Bit 3: Address mode
    Bit 4: Sub-op
    Bit 5: Sub-op
    Bit 6: Sub-op
    Bit 7: Sub-op

Operation types:
    00: alu
    01: register transfer
    10: jump
    11: 

Address modes:
    00: b register
    01: memory address
    10: indirect memory address
    11: pc

MMU sub-ops:
    0001: address buffer low byte load
    0010: address buffer high byte load
    0011: memory[address buffer] to system bus (standard read)
    0100: system bus to memory[address buffer] (standard write)
    0101: memory[PC] to {system bus/direct to CU} (op-read)
