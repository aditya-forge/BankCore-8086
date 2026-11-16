# BankCore-8086: College and Technical Interview Learning Guide

This document is a comprehensive study and preparation guide for university-level Computer Organization and Architecture (COA) / Microprocessor Systems (8086) courses, practical lab viva examinations, and low-level technical interviews.

It bridges theoretical hardware concepts with practical assembly implementations derived from the BankCore-8086 Banking Management System project (`bank.asm`).

---

## Table of Contents

- [Part 1: College Curriculum and COA Fundamentals](#part-1-college-curriculum-and-coa-fundamentals)
  - [1. 8086 Hardware Architecture: BIU and EU](#1-8086-hardware-architecture-biu-and-eu)
  - [2. Memory Banking: Even and Odd Banks](#2-memory-banking-even-and-odd-banks)
  - [3. Pin Functions and Bus Control Signals](#3-pin-functions-and-bus-control-signals)
  - [4. Minimum Mode vs. Maximum Mode](#4-minimum-mode-vs-maximum-mode)
  - [5. How Assemblers and Linkers Work (Two-Pass Assembly)](#5-how-assemblers-and-linkers-work-two-pass-assembly)
  - [6. Real-Mode Memory Segmentation and Addressing Modes](#6-real-mode-memory-segmentation-and-addressing-modes)
  - [7. Complete Flag Register Breakdown](#7-complete-flag-register-breakdown)
- [Part 2: Systems Programming and Software Mechanics](#part-2-systems-programming-and-software-mechanics)
  - [8. Real Mode vs. Protected Mode vs. Long Mode](#8-real-mode-vs-protected-mode-vs-long-mode)
  - [9. Stack Frames and Procedure Calling Conventions](#9-stack-frames-and-procedure-calling-conventions)
  - [10. Interrupt Architecture and DOS Dispatch (INT 21H)](#10-interrupt-architecture-and-dos-dispatch-int-21h)
  - [11. Number Conversion Algorithms](#11-number-conversion-algorithms)
  - [12. String Manipulation and Hardware Primitives](#12-string-manipulation-and-hardware-primitives)
- [Part 3: College Lab Viva Questions and Answers](#part-3-college-lab-viva-questions-and-answers)
- [Part 4: Technical Interview Questions and Answers](#part-4-technical-interview-questions-and-answers)
- [Part 5: Quick Revision Cheat Sheet](#part-5-quick-revision-cheat-sheet)

---

# Part 1: College Curriculum and COA Fundamentals

## 1. 8086 Hardware Architecture: BIU and EU

The 8086 internal architecture is split into two independent processing blocks that operate concurrently. This allows instruction fetching to overlap with instruction execution.

```
+-----------------------------------------------------------------------+
|                      BUS INTERFACE UNIT (BIU)                         |
|                                                                       |
|   Segment Registers: CS (Code), DS (Data), SS (Stack), ES (Extra)     |
|   Instruction Pointer: IP                                             |
|   20-bit Dedicated Address Generation Adder                           |
|   6-Byte First-In-First-Out (FIFO) Instruction Prefetch Queue         |
|   Bus Control Logic (Generates memory and I/O control strobes)        |
+-----------------------------------+-----------------------------------+
                                    |
                                    | 8-bit instruction stream
                                    v
+-----------------------------------+-----------------------------------+
|                       EXECUTION UNIT (EU)                             |
|                                                                       |
|   General Registers: AX, BX, CX, DX                                   |
|   Pointer and Index Registers: SP, BP, SI, DI                         |
|   16-Bit Arithmetic and Logic Unit (ALU)                              |
|   Flags Register (9 active status and control flags)                  |
|   Instruction Decoder and Control Unit                                |
+-----------------------------------------------------------------------+
```

### Bus Interface Unit (BIU)
- Fetches instruction bytes from memory ahead of time and stores them in a 6-byte prefetch queue.
- Computes 20-bit physical addresses using its dedicated hardware adder.
- Manages all reads and writes to external RAM, ROM, and peripheral I/O ports.

### Execution Unit (EU)
- Pulls prefetched instruction bytes from the BIU queue.
- Decodes instructions and executes arithmetic, logic, and shift operations.
- Updates the status flags in the Flags register.
- Has no direct connection to the system address/data buses; all external transfers must go through the BIU.

---

## 2. Memory Banking: Even and Odd Banks

The 8086 has a **16-bit external data bus** ($D_0$–$D_{15}$), but physical memory is **byte-addressable** ($1\text{ MB} = 1,048,576$ individual 8-bit bytes).

To allow the processor to access either 8 bits (1 byte) or 16 bits (1 word) in a single bus cycle, the physical memory is divided into two 512 KB banks:

```
+----------------------------------+     +----------------------------------+
|      ODD BANK (Upper Bank)       |     |      EVEN BANK (Lower Bank)      |
|           512 KB RAM             |     |           512 KB RAM             |
|   Connected to Data Bus D8-D15   |     |    Connected to Data Bus D0-D7   |
|   Addresses: 00001H, 00003H...   |     |   Addresses: 00000H, 00002H...   |
+----------------------------------+     +----------------------------------+
                 ^                                        ^
                 |                                        |
          Active Low BHE#                          Active Low A0
```

- **Even Bank (Lower Bank)**:
  - Contains all even physical addresses (`00000H`, `00002H`, `00004H`, etc.).
  - Connected to data bus lines $D_0$–$D_7$.
  - Selected by address line $A_0 = 0$.
- **Odd Bank (Upper Bank)**:
  - Contains all odd physical addresses (`00001H`, `00003H`, `00005H`, etc.).
  - Connected to data bus lines $D_8$–$D_{15}$.
  - Selected by the active-low Bus High Enable signal $\overline{BHE} = 0$.

### Memory Access Truth Table

| $\overline{BHE}$ | $A_0$ | Operation Type | Bus Lines Used | Bus Cycles Required |
| :---: | :---: | :--- | :---: | :---: |
| `0` | `0` | 16-bit word at an **even** address (aligned) | $D_0$–$D_{15}$ | **1 Cycle** |
| `1` | `0` | 8-bit byte at an **even** address | $D_0$–$D_7$ | **1 Cycle** |
| `0` | `1` | 8-bit byte at an **odd** address | $D_8$–$D_{15}$ | **1 Cycle** |
| `0` | `1` | 16-bit word at an **odd** address (misaligned) | First $D_8$–$D_{15}$, then $D_0$–$D_7$ | **2 Cycles** |

> **Viva / Interview Takeaway**: An aligned 16-bit word access (at an even address) takes only 1 bus cycle. A misaligned 16-bit word access (at an odd address) requires 2 consecutive bus cycles, cutting memory bandwidth in half for that access.

---

## 3. Pin Functions and Bus Control Signals

The 8086 is packaged in a 40-pin Dual In-line Package (DIP). Key pins frequently asked about in exams include:

- **$AD_0$–$AD_{15}$ (Address/Data Bus Multiplexed)**:
  - Pins serve as address lines $A_0$–$A_{15}$ during the first clock cycle ($T_1$) of a bus cycle.
  - Pins switch to serve as bidirectional data lines $D_0$–$D_{15}$ during later clock cycles ($T_2$, $T_3$, $T_4$).
- **`ALE` (Address Latch Enable)**:
  - An output pulse generated by the BIU during clock cycle $T_1$.
  - Tells external demultiplexing latches (e.g., 74LS373 ICs) to capture and hold the address before the bus switches to carrying data.
- **$\overline{BHE}$ (Bus High Enable)**:
  - Used alongside address line $A_0$ to select the odd memory bank on data lines $D_8$–$D_{15}$.
- **`M/IO#` (Memory or I/O selection)**:
  - High (`1`): Accessing memory space (00000H–FFFFFH).
  - Low (`0`): Accessing I/O port space (0000H–FFFFH).
- **`READY`**:
  - An input signal from slow memory or peripherals. If `READY` is low, the processor inserts Wait states ($T_w$) until the device is ready to complete the transfer.
- **`NMI` and `INTR`**:
  - `NMI` (Non-Maskable Interrupt): Edge-triggered input that forces an internal `Interrupt 2`. Cannot be disabled by software.
  - `INTR` (Interrupt Request): Level-triggered maskable input recognized only if the Interrupt Flag is set (`IF = 1`).

---

## 4. Minimum Mode vs. Maximum Mode

The 8086 can operate in one of two hardware configurations based on pin 33 (`MN/MX#`):

| Characteristic | Minimum Mode (`MN/MX# = Vcc`) | Maximum Mode (`MN/MX# = GND`) |
| :--- | :--- | :--- |
| **System Size** | Single-processor systems. | Multiprocessor systems (e.g., 8086 + 8087 Math Coprocessor). |
| **Control Signals** | Generated directly by the 8086 CPU pins (e.g., `RD#`, `WR#`, `M/IO#`, `ALE`). | Generated by an external 8288 Bus Controller IC. |
| **Status Pins** | Dedicated control lines are exposed on pins 24–31. | Pins 24–31 output status signals $\overline{S_0}$, $\overline{S_1}$, $\overline{S_2}$ indicating the bus cycle type. |
| **Bus Arbitration** | Uses `HOLD` and `HLDA` pins for DMA transfers. | Uses `RQ#/GT0#` and `RQ#/GT1#` bidirectional lines. |

---

## 5. How Assemblers and Linkers Work (Two-Pass Assembly)

When building an executable from source (`masm bank.asm;` followed by `link bank.obj;`), the build toolchain runs distinct stages:

### Two-Pass Assembler Mechanics

```
Source Code (.ASM) ──> [ PASS 1: Build Symbol Table & Assign Offsets ]
                             │
                             ▼ (Symbol Table + Intermediate Code)
                       [ PASS 2: Translate Opcodes & Generate Object Code ]
                             │
                             ▼
                       Relocatable Object File (.OBJ)
```

1. **Pass 1: Symbol Table Construction**
   - The assembler maintains a **Location Counter (LC)** initialized to zero for each segment.
   - It reads the source line by line.
   - When it encounters labels (e.g., `CREATE_ACCOUNT:`) or variable names (`BALANCE DW 0`), it records the symbol name, its segment, and its relative offset in the **Symbol Table**.
   - It calculates how many bytes each instruction and data declaration will consume and advances the LC.
   - It does not generate final machine code because forward-referenced symbols are not yet resolved.
2. **Pass 2: Code Generation**
   - The assembler reads the source file a second time.
   - It converts mnemonic instructions into machine opcodes.
   - It looks up symbol offsets from the Symbol Table built in Pass 1 to complete branch targets and memory addresses.
   - It emits the relocatable object file (`.OBJ`) and an optional listing file (`.LST`).

### Linker and Loader Roles
- **Linker (`LINK.EXE` / `TLINK.EXE`)**:
  - Combines multiple object modules into a single executable (`.EXE`).
  - Resolves cross-module external symbols.
  - Combines identical segments (e.g., merging all `.DATA` contributions).
  - Prepends a **512-byte header** to the `.EXE` file containing relocation pointers.
- **DOS Loader**:
  - Allocates a contiguous memory paragraph for the program.
  - Sets up the 256-byte Program Segment Prefix (PSP).
  - Reads the `.EXE` header, adjusts segment references to point to actual loaded physical addresses, sets `CS:IP` to the entry point (`MAIN`), sets `SS:SP` to the stack top, and hands over execution.

---

## 6. Real-Mode Memory Segmentation and Addressing Modes

### 20-bit Physical Address Calculation
The 8086 generates physical addresses through shifted segment-offset addition:

$$\text{Physical Address} = (\text{Segment Base} \times 16) + \text{Offset} = (\text{Segment Base} \ll 4) + \text{Offset}$$

*Example*: If `DS = 2000H` and offset `[0150H]` is referenced:
$$\text{Physical Address} = (2000\text{H} \times 10\text{H}) + 0150\text{H} = 20000\text{H} + 0150\text{H} = 20150\text{H}$$

### Addressing Modes Used in bank.asm

| Addressing Mode | Syntax in bank.asm | Effective Address (EA) Computation |
| :--- | :--- | :--- |
| **Immediate** | `MOV BX, 10` | Operand is part of the instruction opcode. |
| **Register** | `MOV AX, BX` | Operands reside in internal registers. No bus cycle needed for data. |
| **Direct** | `MOV BALANCE, AX` | $\text{EA} = \text{Direct 16-bit displacement}$ |
| **Register Indirect**| `MOV AL, [SI]` | $\text{EA} = [SI]$ (Segment is `DS` by default) |
| **Based Indexed** | `MOV AL, [BX+SI]` | $\text{EA} = [BX] + [SI]$ |
| **Direct with Offset**| `MOV CL, NAME_BUF+1`| $\text{EA} = \text{Offset}(\text{NAME\_BUF}) + 1$ |

---

## 7. Complete Flag Register Breakdown

```
Bit Position:  15 14 13 12  11  10   9   8   7   6   5   4   3   2   1   0
Flag Name:      -  -  -  -  OF  DF  IF  TF  SF  ZF   -  AF   -  PF   -  CF
Type:                       S   C   C   C   S   S       S       S       S
(S = Status Flag, C = Control Flag)
```

- **`CF` (Carry Flag)**: Set when an addition carries out of bit 15 (word) or bit 7 (byte), or subtraction borrows. Used in multi-word arithmetic (`ADC`, `SBB`) and unsigned comparisons (`JA`, `JB`).
- **`ZF` (Zero Flag)**: Set to `1` when the result of an arithmetic or logical operation is zero.
- **`SF` (Sign Flag)**: Matches the MSB of the result ($1 = \text{negative}$, $0 = \text{positive}$).
- **`OF` (Overflow Flag)**: Set when signed arithmetic produces a result that exceeds the register capacity (e.g., adding two large positive numbers produces a negative result).
- **`DF` (Direction Flag)**: Set with `STD` (decrement pointers), cleared with `CLD` (increment pointers). Governs `MOVSB`, `LODSB`, `STOSB`.
- **`IF` (Interrupt Flag)**: Set with `STI` to enable maskable interrupts on the `INTR` line; cleared with `CLI` to disable them.
- **`TF` (Trap Flag)**: Puts the processor into single-step execution mode for debugging.

---

# Part 2: Systems Programming and Software Mechanics

## 8. Real Mode vs. Protected Mode vs. Long Mode

The x86 architecture has evolved across three major execution modes:

| Feature | Real Mode (8086) | Protected Mode (80286 / 80386+) | Long Mode (x86-64) |
| :--- | :--- | :--- | :--- |
| **Address Bus Width** | 20 bits (1 MB) | 32 bits (4 GB) | 48 to 52 bits (Up to 4 PB) |
| **Register Width** | 16 bits (`AX`, `BX`...) | 32 bits (`EAX`, `EBX`...) | 64 bits (`RAX`, `RBX`...) |
| **Segmentation Scheme** | Physical $=$ $(\text{Segment} \ll 4) + \text{Offset}$ | Segment register holds a **Selector** pointing to a Descriptor Table (GDT/LDT). | Mostly flat memory model; `CS`, `DS`, `SS`, `ES` bases forced to 0. |
| **Memory Protection** | None. Any program can overwrite interrupt vectors or OS RAM. | Ring-based privilege levels (Ring 0 to Ring 3) with page faults. | Hardware page-level protection (NX bit, ring levels). |
| **Virtual Memory** | Not supported. | Paging hardware supported (4 KB pages). | 4-level or 5-level page tables. |

---

## 9. Stack Frames and Procedure Calling Conventions

### Stack Direction and Allocation
Under 8086 architecture, the stack grows **downward** toward lower memory addresses:
- `PUSH` decrements `SP` by 2, then stores the word at `SS:SP`.
- `POP` reads the word from `SS:SP`, then increments `SP` by 2.

### Subroutine Prologue and Epilogue Pattern
When building subroutines in `bank.asm`, register state is preserved using callee-save patterns:

```assembly
DISPLAY_NUMBER PROC
    ; --- Subroutine Prologue: Save Caller State ---
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- Subroutine Work Area ---
    ...

    ; --- Subroutine Epilogue: Restore in Inverted Order ---
    POP DX
    POP CX
    POP BX
    RET
DISPLAY_NUMBER ENDP
```

```
Stack State During Subroutine Execution:

High Memory
|------------------------------------|
| Caller Stack Context               |
|------------------------------------|
| Return Address (Caller's IP)       | <- Pushed automatically by CALL [SP+6]
|------------------------------------|
| Saved BX                           | <- Pushed by procedure prologue [SP+4]
|------------------------------------|
| Saved CX                           | <- Pushed by procedure prologue [SP+2]
|------------------------------------|
| Saved DX                           | <- Pushed by procedure prologue [SP] <- Current SP
|------------------------------------|
| Remainders pushed during loop      | <- SP grows further downward as digits are saved
Low Memory
```

---

## 10. Interrupt Architecture and DOS Dispatch (INT 21H)

### Interrupt Vector Table (IVT) Layout
The IVT occupies the lowest 1,024 bytes of RAM (`00000H` to `003FFH`). It maps 256 interrupts to 4-byte far pointers:

$$\text{Vector Address} = \text{Interrupt Number} \times 4$$

For `INT 21H`:
$$\text{Vector Address} = 21\text{H} \times 4 = 84\text{H} \quad (\text{stored at } 0000:0084\text{H})$$

### Execution Sequence of INT 21H
1. CPU pushes `FLAGS` onto the stack.
2. CPU clears `IF = 0` (disables maskable interrupts) and `TF = 0`.
3. CPU pushes current `CS` onto the stack.
4. CPU pushes current `IP` onto the stack.
5. CPU fetches `IP` from `0000:0084H` and `CS` from `0000:0086H`.
6. CPU jumps to the DOS kernel interrupt service routine (ISR).
7. DOS inspects the function code in `AH` and runs the requested handler.
8. DOS executes `IRET` (Interrupt Return), which pops `IP`, `CS`, and `FLAGS` from the stack to resume `bank.asm`.

---

## 11. Number Conversion Algorithms

### ASCII to 16-Bit Binary Integer (Horner's Method)
ASCII input from the keyboard represents digits as characters (`'0'` = $30\text{H}$ to `'9'` = $39\text{H}$).

`READ_NUMBER` evaluates the number iteratively:

$$\text{Accumulator} = (\text{Accumulator} \times 10) + (\text{ASCII Byte} - 30\text{H})$$

```assembly
READ_NUMBER PROC
    XOR BX, BX              ; Accumulator BX = 0
READ_LOOP:
    MOV AH, 01H             ; Read character with echo
    INT 21H
    CMP AL, 13              ; Carriage Return (Enter key)?
    JE READ_DONE
    CMP AL, '0'             ; Bounds check: '0' <= AL <= '9'
    JB READ_LOOP
    CMP AL, '9'
    JA READ_LOOP
    SUB AL, '0'             ; Convert ASCII to integer (0 to 9)
    XOR AH, AH
    MOV DI, AX              ; Store digit in DI
    MOV AX, BX
    MOV CX, 10
    MUL CX                  ; AX = BX * 10
    ADD AX, DI              ; AX = (BX * 10) + digit
    MOV BX, AX              ; Store result in BX
    JMP READ_LOOP
READ_DONE:
    MOV AX, BX              ; Return 16-bit integer in AX
    RET
READ_NUMBER ENDP
```

### 16-Bit Binary Integer to ASCII (Stack Remainder Reversal)
Dividing an integer by 10 decomposes it from right to left (least significant digit first). Because displays write text left to right, remainders are pushed onto the stack and then popped in reverse order:

```assembly
CONVERT_NUMBER:
    XOR DX, DX              ; Clear DX for 32-bit/16-bit DIV (DX:AX / BX)
    DIV BX                  ; AX = Quotient, DX = Remainder
    PUSH DX                 ; Push digit to stack
    INC CX                  ; Count total digits
    CMP AX, 0
    JNE CONVERT_NUMBER

PRINT_NUMBER:
    POP DX                  ; Pop digits in MSD to LSD order
    ADD DL, '0'             ; Convert to ASCII
    MOV AH, 02H             ; Print character
    INT 21H
    LOOP PRINT_NUMBER
```

---

## 12. String Manipulation and Hardware Primitives

In `bank.asm`, buffered string transfers are written using loops:
```assembly
COPY_NAME:
    MOV AL, [DI]
    MOV [SI], AL
    INC SI
    INC DI
    LOOP COPY_NAME
```

### Optimizing with 8086 String Primitives
The 8086 has dedicated string instructions that run directly in the BIU:

```assembly
    CLD                     ; Clear Direction Flag (DF=0: auto-increment SI and DI)
    MOV CL, NAME_BUF+1      ; Load character count
    XOR CH, CH              ; CX = length
    LEA SI, NAME_BUF+2      ; DS:SI = Source address
    LEA DI, NAME_DATA       ; ES:DI = Destination address
    REP MOVSB               ; Copy CX bytes hardware-accelerated
```

| String Instruction | Operands Used | Operation Performed | Flags Affected |
| :--- | :--- | :--- | :--- |
| **`MOVSB` / `MOVSW`** | `DS:SI` $\to$ `ES:DI` | Copies byte/word from source to destination; updates `SI` and `DI`. | None |
| **`LODSB` / `LODSW`** | `DS:SI` $\to$ `AL`/`AX` | Loads byte/word from memory into accumulator; updates `SI`. | None |
| **`STOSB` / `STOSW`** | `AL`/`AX` $\to$ `ES:DI` | Stores accumulator byte/word into memory; updates `DI`. | None |
| **`CMPSB` / `CMPSW`** | `DS:SI` vs. `ES:DI` | Compares memory operands by subtraction; updates status flags. | All status flags |
| **`SCASB` / `SCASW`** | `AL`/`AX` vs. `ES:DI` | Scans memory for matching accumulator value; updates flags. | All status flags |

---

# Part 3: College Lab Viva Questions and Answers

### Q1: What is the purpose of `.MODEL SMALL` in our program?
`.MODEL SMALL` instructs the assembler to allocate one 64 KB Code Segment and one 64 KB Data Segment. This allows all subroutine calls and memory references to use fast, compact 16-bit near pointers rather than 32-bit far pointers.

### Q2: Why cannot we write `MOV DS, @DATA` directly?
The 8086 instruction set does not support moving an immediate value directly into a segment register. Immediate data must first be loaded into a general-purpose register (such as `AX`) and then transferred to `DS`:
```assembly
MOV AX, @DATA
MOV DS, AX
```

### Q3: What is the difference between `INT 21H, AH=01H` and `INT 21H, AH=0AH`?
- **Function `01H`**: Reads a single character from the keyboard with echo, returning the ASCII value in `AL`.
- **Function `0AH`**: Reads an entire string into a structured memory buffer, providing built-in line editing (handling Backspace) and reporting the exact character count entered.

### Q4: Why must string variables output with `AH=09H` end with a `$` character?
DOS Function `09H` does not use null-terminated strings like C. Instead, it reads through memory until it encounters an ASCII dollar sign (`$` = `24H`). Without a `$`, DOS continues printing whatever happens to follow in memory.

### Q5: What is the purpose of the `ORG 100H` directive seen in `.COM` programs, and why is it absent in `bank.asm`?
`ORG 100H` is used in single-segment `.COM` programs (`.MODEL TINY`) to leave the first 256 bytes ($100\text{H}$) of memory free for the Program Segment Prefix (PSP). Because `bank.asm` is compiled as a multi-segment `.EXE` program, the linker and DOS loader manage the PSP automatically.

### Q6: What does the `DUP` operator mean in data declarations?
`DUP` duplicates a specified value a given number of times:
- `31 DUP(0)`: Allocates 31 consecutive bytes, each initialized to zero.
- `32 DUP('$')`: Allocates 32 consecutive bytes, each filled with the character `$`.

### Q7: Why do we use `XOR AX, AX` instead of `MOV AX, 0`?
`XOR AX, AX` requires only 2 bytes of machine code, whereas `MOV AX, 0` requires 3 bytes (including the 16-bit immediate zero). `XOR` also clears the register in fewer clock cycles on original 8086 silicon.

### Q8: What is the difference between an opcode and an operand?
- **Opcode (Operation Code)**: The machine instruction mnemonic that tells the CPU what operation to perform (e.g., `MOV`, `ADD`, `DIV`).
- **Operand**: The target data or storage location the opcode acts upon (e.g., registers, memory addresses, or immediate values).

---

# Part 4: Technical Interview Questions and Answers

### Q1: What happens if an input number exceeds 65,535 in `READ_NUMBER`?
During the conversion loop, `MUL CX` multiplies the running accumulator by 10. If the accumulated value exceeds 65,535, the product exceeds 16 bits. The high-order word of the product overflows into `DX`, and subsequent `ADD AX, DI` operations produce truncated values. If `DISPLAY_NUMBER` is later called on corrupted registers without clearing `DX`, `DIV BX` will trigger an `Interrupt 0` (Divide Error) crash.

### Q2: Why are signed comparison jumps (`JG`, `JL`) dangerous for financial systems in 16-bit assembly?
In 16-bit arithmetic, values from 32,768 to 65,535 have bit 15 set. Under signed representation (two's complement), bit 15 indicates a negative number:
- $40,000$ unsigned is interpreted as $-25,536$ signed.
Comparing a balance of $40,000$ with a withdrawal of $5,000$ using `JG` evaluates as $-25,536 > 5,000$, which is false. Using unsigned jumps (`JA`, `JB`) correctly checks the Carry and Zero flags instead.

### Q3: How would you debug an unresolved external symbol error from `LINK.EXE`?
1. Check that the source file ends with `END label` (e.g., `END MAIN`) so the linker knows the entry point.
2. Verify `.STACK 100H` is declared; otherwise, the linker emits warning `L4021: no stack segment`.
3. Ensure the linker was run with a trailing semicolon (`link bank.obj;`). Omitting the semicolon causes the linker to prompt for libraries and definitions that do not exist.

### Q4: Explain how re-entrancy issues can arise in DOS programs.
MS-DOS is a single-tasking, non-reentrant operating system. Its internal functions use fixed, static memory buffers rather than dynamically allocated per-call stack frames. If an interrupt service routine calls an `INT 21H` function while the main program is already inside an `INT 21H` service, the DOS internal variables are overwritten, corrupting the system state.

### Q5: How does the CPU distinguish between instructions and data in memory?
The CPU does not differentiate between instructions and data based on their byte contents. Any byte pointed to by the `CS:IP` register pair is treated as an instruction opcode and fetched into the instruction queue. Any byte referenced through `DS`, `SS`, or `ES` is treated as data.

### Q6: What is the difference between `TEST` and `CMP` instructions?
- `CMP Destination, Source`: Performs subtraction (`Destination - Source`) and updates all status flags (`CF`, `ZF`, `SF`, `OF`, `AF`, `PF`). It is used to compare relative magnitude.
- `TEST Destination, Source`: Performs a bitwise logical AND (`Destination & Source`) and updates flags (`ZF`, `SF`, `PF`), while clearing `CF` and `OF`. Operands remain unmodified. It is used to check whether specific individual bits are set.

---

# Part 5: Quick Revision Cheat Sheet

### Register Conventions

| Register | Common Usage |
| :--- | :--- |
| `AX` | Accumulator; arithmetic operations, function return values, I/O. |
| `BX` | Base register; holds memory base pointers in base-index addressing. |
| `CX` | Count register; default counter for `LOOP`, `REP`, shifts, and rotates. |
| `DX` | Data register; high 16 bits in 32-bit `MUL`/`DIV`, port numbers in `IN`/`OUT`. |
| `SI` | Source Index; default pointer into `DS` for string instructions. |
| `DI` | Destination Index; default pointer into `ES` for string instructions. |
| `BP` | Base Pointer; default pointer into `SS` for stack frame parameter access. |
| `SP` | Stack Pointer; points to current top of the stack (`SS:SP`). |

### Jump Conditions

| Jump Mnemonic | Condition | Description |
| :--- | :--- | :--- |
| `JE` / `JZ` | `ZF = 1` | Jump if Equal / Jump if Zero |
| `JNE` / `JNZ` | `ZF = 0` | Jump if Not Equal / Jump if Not Zero |
| `JA` / `JNBE` | `CF = 0` and `ZF = 0` | Jump if Above (Unsigned >) |
| `JAE` / `JNB` | `CF = 0` | Jump if Above or Equal (Unsigned >=) |
| `JB` / `JNAE` | `CF = 1` | Jump if Below (Unsigned <) |
| `JBE` / `JNA` | `CF = 1` or `ZF = 1` | Jump if Below or Equal (Unsigned <=) |
| `JG` / `JNLE` | `ZF = 0` and `SF = OF`| Jump if Greater (Signed >) |
| `JGE` / `JNL` | `SF = OF` | Jump if Greater or Equal (Signed >=) |
| `JL` / `JNGE` | `SF != OF` | Jump if Less (Signed <) |
| `JLE` / `JNG` | `ZF = 1` or `SF != OF`| Jump if Less or Equal (Signed <=) |
| `JCXZ` | `CX = 0` | Jump if CX is Zero |

### Common INT 21H Functions

| `AH` Value | Function | Inputs | Outputs |
| :---: | :--- | :--- | :--- |
| `01H` | Read character with echo | None | `AL` = ASCII character |
| `02H` | Write character to screen | `DL` = ASCII character | None |
| `09H` | Write string to screen | `DS:DX` = `$`-terminated string | None |
| `0AH` | Read buffered string | `DS:DX` = buffer address | Buffer filled |
| `4CH` | Terminate process | `AL` = exit code | Returns to DOS |
