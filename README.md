# 8-Bit Soft-Core FPGA Synthesized Microcontroller

## Introduction

This project implements a simple 8-bit soft-core processor using a Finite State Machine (FSM) model. The processor consists of various key modules such as the Arithmetic Logic Unit (ALU), Program Memory (PMem), Data Memory (DMem), and a series of control logic components. The Control_Logic module plays a crucial role in generating control signals based on the current state and instruction type, facilitating the execution of a set of basic operations. The processor follows a sequence of states—LOAD, FETCH, DECODE, and EXECUTE—to process instructions stored in program memory.

## System Architecture

The processor operates using a state-based approach, transitioning through the following states:

- **LOAD**: Initializes the processor by loading the program into memory.
- **FETCH**: Fetches instructions from Program Memory based on the Program Counter (PC).
- **DECODE**: Decodes the fetched instruction and prepares the necessary control signals.
- **EXECUTE**: Executes the instruction using the ALU and updates the relevant registers.

### Key Components:

- **Program Memory (PMem)**: Stores the instructions to be executed.
- **Data Memory (DMem)**: Stores and retrieves data during execution.
- **Arithmetic Logic Unit (ALU)**: Performs arithmetic and logical operations.
- **Multiplexers (MUX1 & MUX2)**: Select inputs for various operations.
- **Control Logic**: Generates control signals for registers, memory, ALU, and multiplexers based on the current state and instruction type.
- **Adder**: Increments the program counter to point to the next instruction.

## Module Descriptions

### 1. Project Module
The central module orchestrating the processor's functionality by defining and managing the state transitions. It coordinates the interaction between Program Memory, Data Memory, ALU, and Control Logic, ensuring seamless execution of instructions.

### 2. Control_Logic Module
Generates the necessary control signals to operate the processor's components based on the current state and the decoded instruction. It drives the behavior of registers, memory units, ALU, and multiplexers.

### 3. PMem Module
Represents the Program Memory, storing instructions and providing a mechanism to load instructions into memory using external files.

### 4. MUX1 Module
Implements a multiplexer for selecting between two inputs based on a selection signal. It's utilized for data and control signal multiplexing within the processor.

### 5. Adder Module
Performs simple addition, used primarily for incrementing the Program Counter.

### 6. DMem Module
Handles data storage and retrieval during program execution. Supports read and write operations controlled by enable signals.

### 7. ALU Module
Implements various arithmetic and logical operations. The ALU is responsible for performing core computations within the processor.

## Implementation Details

The processor is implemented in Verilog, adhering to a modular design approach with clear separation between data and control signals. The processor's FSM architecture facilitates easy understanding and extension. The processor initializes by loading instructions from an external file (`progr.dat`) into Program Memory.

### State Machine

The processor's FSM includes the following states:

- **LOAD**: Loads instructions into Program Memory.
- **FETCH**: Fetches instructions based on the Program Counter (PC).
- **DECODE**: Decodes the instruction to determine the operation.
- **EXECUTE**: Executes the instruction and updates the relevant components.

### Registers and Memory

- **Program Counter (PC)**: Tracks the address of the next instruction.
- **Accumulator (Acc)**: Stores results of arithmetic and logic operations.
- **Status Register (SR)**: Holds status flags such as zero, carry, sign, and overflow.
- **Data Register (DR)**: Temporarily holds data during execution.
- **Instruction Register (IR)**: Stores the currently fetched instruction.

### Control Logic

The Control_Logic module generates control signals to enable or disable various components during the execution process, ensuring proper synchronization and operation of the processor.

### Memory Handling

The processor utilizes Program Memory (PMem) to store instructions and Data Memory (DMem) to store data. Instructions are loaded into PMem during the LOAD state, while DMem handles data read and write operations during program execution.

### ALU Operations

The ALU supports a variety of operations, including addition, subtraction, bitwise operations, logical shifts, and two's complement negation. The ALU's operation mode is controlled by a 4-bit input signal.

## Simulation and Testing

The processor design has been simulated and tested using testbenches to verify its correct operation. The modular approach facilitates easy testing of individual components as well as the overall processor.

---

This repository contains all the necessary Verilog code and supporting files to synthesize the 8-bit soft-core processor on an FPGA. The code is well-commented, following best practices in digital design to ensure clarity and maintainability.
