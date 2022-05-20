# yul-greatest-hits
A collection of my work done in Yul/Yul+ from basic token standards, to advanced Defi primitives

## Background

Yul (previously also called JULIA or IULIA) is an intermediate language that can be compiled to bytecode for different backends.

Yul is a good target for high-level optimisation stages that can benefit all target platforms equally.

### About Yul

  - Yul provides for loops, if and switch statements
  - No explicit statements for SWAP, DUP, JUMPDEST, JUMP and JUMPI are provided (as they obfuscate data flow and control flow)
  - Statements such as mul(add(x, y),z) are preferred over 7 y x add mul, because it becomes easier to see which opcode is being used for which operand
  - Yul is desigend for a stack based machine (EVM) but it does not expose the programmer to the complexity of the stack itself
  - Yul is statically typed, but also there is a default type (integer word of the target machine) that can be omitted.
  - Yul does not have any built-in operations, functions or types in its pure form. 6.1 There exists only one specified dialect of Yul and that uses the EVM opcodes as builtin functions and defines only the type u256 (native 256-bit type of EVM)

### Tools


