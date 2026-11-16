# BankCore-8086: 16-Bit Real-Mode Banking Management System

An interactive, menu-driven banking management system written in 16-bit x86 Intel 8086 Assembly Language (`bank.asm`). Developed for Computer Organization and Architecture (COA) and Microprocessor Systems coursework, and hosted at [https://github.com/aditya-forge/BankCore-8086](https://github.com/aditya-forge/BankCore-8086).

The project demonstrates real-mode x86 memory segmentation, DOS software interrupt handling (`INT 21H`), stack-based register preservation, string buffer management, numeric base conversion, and input validation.

---

## Table of Contents

- [Features](#features)
- [Technical Specifications](#technical-specifications)
- [Terminal Simulation](#terminal-simulation)
- [Architecture and Memory Layout](#architecture-and-memory-layout)
- [Real-Mode Segmented Memory Addressing](#real-mode-segmented-memory-addressing)
  - [Memory Map](#memory-map)
  - [Segment Registers](#segment-registers)
  - [Stack Frame and Register Preservation](#stack-frame-and-register-preservation)
  - [Interrupt Vector Table (IVT) and DOS Dispatch](#interrupt-vector-table-ivt-and-dos-dispatch)
  - [DOS Function 0AH Buffer Layout](#dos-function-0ah-buffer-layout)
  - [Data Segment Variables](#data-segment-variables)
- [DOS Interrupt Reference (INT 21H)](#dos-interrupt-reference-int-21h)
- [Register Allocation](#register-allocation)
- [Common Assembly Pitfalls and Solutions](#common-assembly-pitfalls-and-solutions)
- [Module Walkthrough](#module-walkthrough)
  - [1. Program Initialization](#1-program-initialization)
  - [2. Account Creation](#2-account-creation)
  - [3. Authentication and Login](#3-authentication-and-login)
  - [4. Dashboard Operations](#4-dashboard-operations)
  - [5. Helper Subroutines](#5-helper-subroutines)
- [Setup and Execution Guide](#setup-and-execution-guide)
  - [Method 1: DOSBox with MASM / TASM](#method-1-dosbox-with-masm--tasm)
  - [Method 2: EMU8086](#method-2-emu8086)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Input Validation and Error Handling](#input-validation-and-error-handling)
- [College and Interview Learning Guide](LEARN_GUIDE.md)
- [Security Policy](SECURITY.md)
- [Project Structure](#project-structure)
- [License](#license)

---

## Features

| Feature | Description |
| :--- | :--- |
| **Account Creation** | Takes user name, age, 10-digit mobile number, 4-digit PIN, and initial deposit amount. |
| **PIN Validation** | Checks for an exact 4-character length and verifies each character is an ASCII digit ('0' to '9'). |
| **Account Number Generation** | Assigns a default account number (`1001`) upon registration. |
| **Authentication** | Verifies both the account number and the 4-digit PIN before allowing access to the dashboard. |
| **Check Balance** | Displays current available balance formatted with a currency prefix (`Rs.`). |
| **Deposit Money** | Takes a numeric amount and adds it to the balance. |
| **Withdraw Money** | Compares the requested amount against the balance and prevents overdraft using unsigned checks. |
| **Change PIN** | Allows updating the 4-digit PIN with length and digit validation. |
| **Account Statement** | Displays user details including name, age, mobile number, and account number. |
| **Session Logout** | Returns to the main menu without terminating the program. |

---

## Technical Specifications

| Parameter | Value | Notes |
| :--- | :--- | :--- |
| **Target Processor** | Intel 8086 / 8088 | 16-bit CISC architecture |
| **Execution Mode** | Real Mode | 20-bit physical address space (1 MB) |
| **Memory Model** | `.MODEL SMALL` | Single code segment (up to 64 KB), single data segment (up to 64 KB) |
| **Stack Allocation** | `.STACK 100H` | 256 bytes (128 words) |
| **Integer Representation**| 16-bit Unsigned | Range: 0 to 65,535 |
| **Input / Output** | MS-DOS API (`INT 21H`) | Functions 01H, 02H, 09H, 0AH |
| **Exit Mechanism** | `INT 21H, AH=4CH` | Clean exit code return to DOS |
| **Assemblers** | MASM 5.x/6.x, TASM 3.x/4.x, EMU8086 | Standard 16-bit real-mode linkers |

---

## Terminal Simulation

### Main Menu
```text
====================================
     BANKCORE-8086 BANK SYSTEM
====================================
1. Create Account
2. Login
3. Exit
Enter Choice: 1
```

### Account Creation
```text
Enter Full Name: Sarah Connor
Enter Age: 28
Enter Mobile Number: 9876543210
Create 4 Digit PIN: 1337
Enter Initial Deposit: 15000

Account Created Successfully!
Your Account Number: 1001
```

### Login and Dashboard
```text
Enter Account Number: 1001
Enter PIN: 1337

Login Successful!

========== BANK DASHBOARD ==========
1. Check Balance
2. Deposit Money
3. Withdraw Money
4. Change PIN
5. Account Details
6. Logout
Enter Choice: 1

Available Balance: Rs. 15000
```

### Withdrawal and Balance Update
```text
Enter Choice: 3
Enter Withdrawal Amount: 20000
Insufficient Balance!

Enter Choice: 3
Enter Withdrawal Amount: 5000
Withdrawal Successful!

Enter Choice: 1
Available Balance: Rs. 10000
```

---

## Architecture and Memory Layout

### Real-Mode Segmented Memory Addressing

The Intel 8086 has a 16-bit internal architecture and a 20-bit external address bus, allowing it to address 1 MB ($2^{20}$ bytes) of memory from `00000H` to `FFFFFH`.

Because registers are only 16 bits wide, memory is addressed using a **Segment:Offset** scheme. The Bus Interface Unit (BIU) computes the 20-bit physical address by shifting the segment base 4 bits to the left and adding the 16-bit offset:

$$\text{Physical Address} = (\text{Segment} \times 16) + \text{Offset} = (\text{Segment} \ll 4) + \text{Offset}$$

```
+-----------------------------------+-------------------+
|         16-bit Segment Base       |       0 0 0 0     |  (Shifted left by 4 bits)
+-----------------------------------+-------------------+
                          +
+-----------------------------------+-------------------+
|               0 0 0 0             |    16-bit Offset  |
+-----------------------------------+-------------------+
                          =
+-------------------------------------------------------+
|                 20-bit Physical Address               |
+-------------------------------------------------------+
```

For example, if `DS = 1380H` and the offset `DX = 0042H`:
$$\text{Physical Address} = (1380\text{H} \times 10\text{H}) + 0042\text{H} = 13800\text{H} + 0042\text{H} = 13842\text{H}$$

---

### Memory Map

The 1 MB address space under MS-DOS is partitioned as follows:

```
+-------------------------+ 0FFFFFH (Top of 1 MB)
| System ROM BIOS         | 64 KB BIOS code and reset vectors
+-------------------------+ 0F0000H
| Video and Expansion RAM | Video text/graphics buffers (B800H, A000H)
+-------------------------+ 0A0000H (640 KB conventional memory limit)
| Free Conventional RAM   | Transient execution space
+-------------------------+
| Stack Segment (SS)      | Allocated by .STACK 100H (256 bytes)
+-------------------------+
| Data Segment (DS)       | Variables, buffers, and string literals
+-------------------------+
| Code Segment (CS)       | Executable instructions of bank.asm
+-------------------------+
| Program Segment Prefix  | 256-byte PSP built by DOS loader
+-------------------------+
| DOS Kernel and Drivers  | System tables and device drivers
+-------------------------+ 00500H
| BIOS Data Area (BDA)    | Keyboard queue and system state flags
+-------------------------+ 00400H
| Interrupt Vector Table  | 256 vector pointers (4 bytes each)
+-------------------------+ 00000H
```

---

### Segment Registers

The program uses three primary segment registers:

| Register | Name | Role in bank.asm | Initialization |
| :---: | :--- | :--- | :--- |
| **`CS`** | Code Segment | Contains executable instructions. Paired with `IP` to fetch the next opcode. | Initialized automatically by the DOS loader when starting `MAIN`. |
| **`DS`** | Data Segment | Points to variables, message strings, and input buffers. | Initialized manually at startup via `AX` (`MOV AX, @DATA` / `MOV DS, AX`). |
| **`SS`** | Stack Segment | Points to the stack region used by `CALL`, `RET`, `PUSH`, and `POP`. | Managed by the DOS loader as defined by `.STACK 100H`. |
| **`ES`** | Extra Segment | Secondary data pointer used for string operations. | Unused or shared with `DS` in `.MODEL SMALL`. |

Notice that the 8086 cannot move an immediate value directly into a segment register. An intermediate register such as `AX` must be used.

---

### Stack Frame and Register Preservation

The 8086 stack is a downward-growing Last-In-First-Out (LIFO) structure controlled by the `SS:SP` register pair.

- **`PUSH Reg16`**: Decrements `SP` by 2 ($\text{SP} \leftarrow \text{SP} - 2$), then writes the 16-bit word at `SS:SP`.
- **`POP Reg16`**: Reads the 16-bit word at `SS:SP`, then increments `SP` by 2 ($\text{SP} \leftarrow \text{SP} + 2$).

In `DISPLAY_NUMBER`, callee-save conventions are followed so the subroutine does not overwrite values the caller expects to keep:

```assembly
DISPLAY_NUMBER PROC
    ; Save registers used by this routine
    PUSH BX
    PUSH CX
    PUSH DX

    ; Subroutine body (divides by 10 and prints characters)
    ...

    ; Restore registers in reverse order
    POP DX
    POP CX
    POP BX
    RET                     ; Pop return address into IP
DISPLAY_NUMBER ENDP
```

#### Stack State During DISPLAY_NUMBER Execution

```
High Memory
|------------------------------------|
| Caller stack data                  |
|------------------------------------|
| Return Address (Caller's IP)       | <- Pushed by CALL [SP+6]
|------------------------------------|
| Saved BX                           | <- PUSH BX        [SP+4]
|------------------------------------|
| Saved CX                           | <- PUSH CX        [SP+2]
|------------------------------------|
| Saved DX                           | <- PUSH DX        [SP] <- SP after prologue
|------------------------------------|
| Remainders pushed during loop      | <- SP continues down as digits are saved
Low Memory
```

If the number of `POP` operations does not match the `PUSH` operations before `RET`, the wrong value is popped into `IP`, causing the CPU to jump to garbage memory.

---

### Interrupt Vector Table (IVT) and DOS Dispatch

The first 1,024 bytes of physical memory (`00000H` to `003FFH`) hold the Interrupt Vector Table. There are 256 vectors, each taking 4 bytes (a 16-bit offset followed by a 16-bit segment):

$$\text{Vector Address} = \text{Interrupt Number} \times 4$$

For `INT 21H`:
$$\text{Vector Address} = 21\text{H} \times 4 = 84\text{H} \quad (\text{stored at } 0000:0084\text{H})$$

When `INT 21H` is executed:
1. The CPU pushes `FLAGS`, `CS`, and `IP` onto the stack.
2. It clears the Interrupt Flag (`IF = 0`) and Trap Flag (`TF = 0`).
3. It loads `IP` and `CS` from `0000:0084H` and jumps to the DOS kernel dispatcher.
4. DOS reads the function number in `AH` (`01H`, `02H`, `09H`, `0AH`, `4CH`) and runs the requested routine.
5. DOS executes `IRET`, which pops `IP`, `CS`, and `FLAGS` from the stack, returning execution to `bank.asm`.

---

### DOS Function 0AH Buffer Layout

Function `0AH` reads a line of input from the keyboard into a structured buffer:

```
Byte Index:     [ 0 ]         [ 1 ]         [ 2 ]   [ 3 ]   ...   [ N+1 ]     [ N+2 ]
Contents:       MAX_LEN       ACT_LEN       CHAR1   CHAR2   ...   CHAR_N      0DH (CR)
Set by:         Programmer    DOS           User input                        Enter key
```

```assembly
NAME_BUF    DB 30, 0, 31 DUP(0)     ; Max 30 chars for Name
MOBILE_BUF  DB 11, 0, 12 DUP(0)     ; Max 11 chars for Mobile
PIN_BUF     DB 5,  0, 6 DUP(0)      ; Max 4 chars for PIN (+1 for Enter)
NEW_PIN_BUF DB 5,  0, 6 DUP(0)      ; Max 4 chars for New PIN
```

- **Byte 0 (`MAX_LEN`)**: Maximum number of characters DOS will accept.
- **Byte 1 (`ACT_LEN`)**: Number of characters actually typed, set by DOS.
- **Bytes 2+**: ASCII characters typed, ending with a carriage return (`0DH`).

---

### Data Segment Variables

```assembly
NAME_BUF        DB 30,0,31 DUP(0)   ; Input buffer for name
MOBILE_BUF      DB 11,0,12 DUP(0)   ; Input buffer for phone number
PIN_BUF         DB 5,0,6 DUP(0)     ; Input buffer for login PIN
NEW_PIN_BUF     DB 5,0,6 DUP(0)     ; Input buffer for change PIN
NAME_DATA       DB 32 DUP('$')      ; Stored name, terminated with '$' for INT 21H, AH=09H
MOBILE_DATA     DB 12 DUP('$')      ; Stored mobile number, terminated with '$'
PIN_DATA        DB '0000'           ; Stored 4-digit PIN
AGE             DW 0                ; Stored user age (16-bit binary integer)
ACCOUNT_NO      DW 1001             ; Default account number
BALANCE         DW 0                ; Current balance (16-bit unsigned, max 65535)
ACCOUNT_CREATED DB 0                ; 0 = no account, 1 = account created
CHOICE          DB ?                ; Menu choice temporary storage
```

---

## DOS Interrupt Reference (INT 21H)

| Function (`AH`) | Purpose | Input | Output | Notes |
| :---: | :--- | :--- | :--- | :--- |
| **`01H`** | Read Character with Echo | None | `AL` = ASCII character | Used for menu selection and digit entry in `READ_NUMBER`. |
| **`02H`** | Print Single Character | `DL` = ASCII character | None | Used by `DISPLAY_NUMBER` to print individual digits. |
| **`09H`** | Print String | `DS:DX` = string pointer | None | String must be terminated with a dollar sign (`$`). |
| **`0AH`** | Buffered String Input | `DS:DX` = buffer pointer | Fills buffer bytes 1 and 2+ | Used for name, mobile number, and PIN input. |
| **`4CH`** | Terminate Program | `AL` = return code | None | Yields control back to DOS. |

---

## Register Allocation

| Register | Primary Purpose in bank.asm |
| :---: | :--- |
| **`AX`** | General accumulator. Holds interrupt function codes in `AH`, single characters in `AL`. Used for 16-bit arithmetic with `BALANCE`, holds the dividend in `DIV`, and returns values from `READ_NUMBER`. |
| **`BX`** | Base accumulator. Accumulates running base-10 value in `READ_NUMBER`. Serves as constant divisor (`BX = 10`) in `DISPLAY_NUMBER`. |
| **`CX`** | Loop counter for string copy loops (`COPY_NAME`, `COPY_MOBILE`) and for counting remainder digits pushed onto the stack. |
| **`DX`** | Pointer to strings and buffers for `INT 21H` (`AH=09H` and `AH=0AH`). Cleared before `DIV` and holds remainder after `DIV`. |
| **`SI`** | Source index pointer during string copy and verification routines. |
| **`DI`** | Destination index pointer during string copy and verification routines. |
| **`SP`** | Stack pointer tracking the top of the stack. |
| **`DS`** | Data Segment base address pointer. |

---

## Common Assembly Pitfalls and Solutions

### 1. 16-Bit Integer Divide Overflow (Interrupt 0)
- **Problem**: The instruction `DIV BX` divides the 32-bit register pair `DX:AX` by `BX`. If `DX` is not cleared before dividing, it contains residual data. If $DX \ge BX$, the quotient does not fit in 16-bit `AX`, and the processor triggers an `Interrupt 0` (Divide Error) crash.
- **Solution**: Always clear `DX` before a 16-bit division:
  ```assembly
  XOR DX, DX              ; Clear high word of dividend
  MOV BX, 10              ; Divisor
  DIV BX                  ; AX = Quotient, DX = Remainder
  ```

### 2. String Buffer Overflow in DOS Function 0AH
- **Problem**: If the buffer capacity byte (byte 0) is not set or the buffer is not large enough, DOS writes incoming characters past the buffer boundary, corrupting neighboring variables in memory.
- **Solution**: Allocate the buffer with explicit capacity, reset actual length before reading, and check for empty input using `JCXZ`:
  ```assembly
  MOV BYTE PTR NAME_BUF+1, 0
  LEA DX, NAME_BUF
  MOV AH, 0AH
  INT 21H
  MOV CL, NAME_BUF+1
  XOR CH, CH
  JCXZ SKIP_COPY          ; If user pressed Enter without typing, don't copy
  ```

### 3. Leftover Carriage Return in Keyboard Stream
- **Problem**: Calling `INT 21H, AH=01H` reads one character. When the user presses Enter, the carriage return (`0DH`) remains in the keyboard buffer. The next input call reads that leftover Enter immediately, skipping the prompt.
- **Solution**: Consume the trailing Enter with a second read:
  ```assembly
  MOV AH, 01H
  INT 21H                 ; Read choice
  MOV CHOICE, AL

  MOV AH, 01H
  INT 21H                 ; Flush trailing Enter
  ```

### 4. Signed vs. Unsigned Jump in Balance Check
- **Problem**: Using `JG` (Jump if Greater) treats 16-bit numbers as signed two's complement. Any value from 32,768 to 65,535 has its sign bit set and is interpreted as negative. A balance of 40,000 would be seen as smaller than a withdrawal of 5,000.
- **Solution**: Always use unsigned conditional jumps (`JA`, `JB`, `JAE`, `JBE`) for balances and positive quantities:
  ```assembly
  CALL READ_NUMBER
  CMP AX, BALANCE
  JA INSUFFICIENT_BALANCE ; Triggers only if AX is genuinely greater as an unsigned number
  SUB BALANCE, AX
  ```

### 5. Runaway String Output from Missing '$' Terminator
- **Problem**: DOS Function `09H` prints characters until it encounters a `$`. If a user input string copied to memory does not end with `$`, DOS keeps printing whatever happens to be next in RAM.
- **Solution**: Always write a `$` byte at the end of the copied data:
  ```assembly
  NAME_DONE:
      MOV BYTE PTR [SI], '$'
  ```

---

## Module Walkthrough

```
                      +--------------------+
                      |     MAIN PROC      |
                      | Initialize DS=@DATA|
                      +---------+----------+
                                |
                                v
                       /-----------------\
                      <     MAIN_MENU     >
                       \-----------------/
                         /      |      \
               Choice='1'/   '2'|       \'3'
                        /       |        \
                       v        |         v
       +------------------+     |     +---------------+
       |  CREATE_ACCOUNT  |     |     |  EXIT_SYSTEM  |
       | - Check Created  |     |     | (INT 21H, 4CH)|
       | - Name / Age     |     |     +---------------+
       | - Mobile / PIN   |     |
       | - Deposit        |     |
       +--------+---------+     |
                |               |
                v               v
         [Back to Menu]   +-------------+
                          |    LOGIN    |
                          | Check Acc#  |
                          | Check PIN   |
                          +------+------+
                                 |
                         Valid?  |
                       +---------+---------+
                       |                   |
                     [YES]                [NO]
                       |                   |
                       v                   v
              +------------------+    +-------------+
              |    BANK_MENU     |    | Error Alert |
              | (User Dashboard) |    | Jump Menu   |
              +--------+---------+    +-------------+
                       |
   +-------+-------+---+---+-------+-------+
   |       |       |       |       |       |
   v       v       v       v       v       v
[Balance][Deposit][Withdraw][PIN]  [Details][Logout]
```

### 1. Program Initialization
The program starts at `MAIN PROC`. The data segment is loaded, and the title banner is displayed:
```assembly
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    LEA DX, TITLE_MSG
    MOV AH, 09H
    INT 21H
```

### 2. Account Creation
- Checks if an account already exists via `ACCOUNT_CREATED`.
- Reads the name and mobile number into temporary buffers, then copies them into `NAME_DATA` and `MOBILE_DATA` using `SI`, `DI`, and `LOOP`.
- Reads age and initial deposit using `CALL READ_NUMBER`.
- Validates the PIN:
  ```assembly
  CMP BYTE PTR PIN_BUF+1, 4    ; Length must be 4
  JNE PIN_ERROR

  LEA SI, PIN_BUF+2
  LEA DI, PIN_DATA
  MOV CX, 4

  COPY_INITIAL_PIN:
      MOV AL, [SI]
      CMP AL, '0'
      JB PIN_ERROR
      CMP AL, '9'
      JA PIN_ERROR
      MOV [DI], AL
      INC SI
      INC DI
      LOOP COPY_INITIAL_PIN
  ```
- Sets `ACCOUNT_CREATED = 1` and displays the assigned account number.

### 3. Authentication and Login
- Checks that `ACCOUNT_CREATED == 1`.
- Prompts for account number, reads it with `READ_NUMBER`, and compares against `ACCOUNT_NO`:
  ```assembly
  CMP AX, ACCOUNT_NO
  JNE LOGIN_ERROR
  ```
- Reads PIN into `PIN_BUF` and compares character by character with `PIN_DATA`:
  ```assembly
  LEA SI, PIN_BUF+2
  LEA DI, PIN_DATA
  MOV CX, 4
  CHECK_LOGIN_PIN:
      MOV AL, [SI]
      CMP AL, [DI]
      JNE LOGIN_ERROR
      INC SI
      INC DI
      LOOP CHECK_LOGIN_PIN
  ```

### 4. Dashboard Operations
- **Check Balance**: Moves `BALANCE` into `AX` and calls `DISPLAY_NUMBER`.
- **Deposit Money**: Reads amount into `AX` and performs `ADD BALANCE, AX`.
- **Withdraw Money**: Compares requested amount with available balance:
  ```assembly
  CALL READ_NUMBER
  CMP AX, BALANCE
  JA INSUFFICIENT_BALANCE
  SUB BALANCE, AX
  ```
- **Change PIN**: Takes a new 4-digit PIN, validates it, and updates `PIN_DATA`.
- **Account Details**: Prints name, age, mobile number, and account number.
- **Logout**: Returns to `MAIN_MENU`.

### 5. Helper Subroutines

#### `READ_NUMBER PROC` (ASCII to 16-Bit Integer)
Converts numeric characters typed at the keyboard into a binary integer in `AX`:

$$\text{New Total} = (\text{Old Total} \times 10) + (\text{Input Character} - \text{'0'})$$

```assembly
READ_NUMBER PROC
    XOR BX, BX              ; Clear accumulator

READ_LOOP:
    MOV AH, 01H             ; Read character with echo
    INT 21H

    CMP AL, 13              ; Enter pressed?
    JE READ_DONE

    CMP AL, '0'             ; Ignore non-numeric input
    JB READ_LOOP
    CMP AL, '9'
    JA READ_LOOP

    SUB AL, '0'             ; Convert ASCII to digit value
    XOR AH, AH

    MOV DI, AX              ; Save digit in DI
    MOV AX, BX
    MOV CX, 10
    MUL CX                  ; AX = BX * 10
    ADD AX, DI              ; Add current digit
    MOV BX, AX              ; Store back in BX

    JMP READ_LOOP

READ_DONE:
    MOV AX, BX              ; Return value in AX
    RET
READ_NUMBER ENDP
```

#### `DISPLAY_NUMBER PROC` (16-Bit Integer to Decimal Output)
Divides the value in `AX` by 10 repeatedly, pushes remainders onto the stack, and pops them to print from left to right:

```assembly
DISPLAY_NUMBER PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10
    XOR CX, CX              ; Digit counter

    CMP AX, 0
    JNE CONVERT_NUMBER
    MOV DL, '0'             ; Handle zero explicitly
    MOV AH, 02H
    INT 21H
    JMP DISPLAY_DONE

CONVERT_NUMBER:
    XOR DX, DX              ; Clear DX before division
    DIV BX                  ; AX = quotient, DX = remainder
    PUSH DX                 ; Push digit to stack
    INC CX
    CMP AX, 0
    JNE CONVERT_NUMBER

PRINT_NUMBER:
    POP DX                  ; Pop digits in MSD to LSD order
    ADD DL, '0'             ; Convert to ASCII
    MOV AH, 02H             ; Print character
    INT 21H
    LOOP PRINT_NUMBER

DISPLAY_DONE:
    POP DX
    POP CX
    POP BX
    RET
DISPLAY_NUMBER ENDP
```

---

## Setup and Execution Guide

### Quick Start: Automated Script (run.bat)

If you are running Windows with DOSBox installed, double-click `run.bat` or run it from PowerShell:
```cmd
.\run.bat
```
The script locates your DOSBox installation (in Program Files or on PATH), automatically mounts the project folder, assembles `bank.asm`, links `bank.obj`, and runs `bank.exe`.

---

### Method 1: DOSBox with MASM / TASM (Manual)

#### Step 1: Prepare Directory
Create a folder on your machine (e.g., `C:\dosbox\bank`) and place `bank.asm` along with your assembler files (`MASM.EXE`, `LINK.EXE` or `TASM.EXE`, `TLINK.EXE`).

#### Step 2: Mount in DOSBox
Open DOSBox and mount the directory:
```dos
Z:\> mount c C:\dosbox\bank
Z:\> c:
```

#### Step 3: Build and Run

- **With Microsoft Macro Assembler (MASM)**:
  ```dos
  C:\> masm bank.asm;
  C:\> link bank.obj;
  C:\> bank.exe
  ```
  *(The semicolon after the filename tells MASM/LINK to use defaults and avoid interactive prompts).*

- **With Turbo Assembler (TASM)**:
  ```dos
  C:\> tasm bank.asm
  C:\> tlink bank.obj
  C:\> bank.exe
  ```

---

### Method 2: EMU8086

1. Open **EMU8086**.
2. Go to **File -> Open** and select `bank.asm`.
3. Click **Emulate** (or press `F5`).
4. In the emulator window, click **Run** to execute the program, or use **Single Step** (`F8`) to trace instructions line by line.

---

## Troubleshooting Guide

### 1. Unresolved External Symbol or Missing Stack Segment
- **Error**: `LINK : warning L4021: no stack segment` or `unresolved external symbol`.
- **Cause**:
  - Missing `.STACK 100H` directive.
  - Omitting the label after `END` (must be `END MAIN`, which tells the linker where execution starts).
  - Leaving off the trailing semicolon in `link bank.obj;` causes the linker to prompt for libraries and object files that do not exist.
- **Fix**: Check that line 3 has `.STACK 100H`, the file ends with `END MAIN`, and link with `link bank.obj;`.

### 2. Divide Error / Interrupt 0 During Execution
- **Error**: DOSBox displays `Divide error` and halts, or EMU8086 shows an unhandled exception at `DIV`.
- **Cause**:
  - The number entered is greater than 65,535, causing 16-bit multiplication in `READ_NUMBER` to overflow.
  - `DX` was not zeroed out before calling `DIV BX`. The CPU divides `DX:AX` by 10, producing a quotient too large for `AX`.
- **Fix**: Keep numbers within the 0 to 65,535 range, and ensure `XOR DX, DX` appears immediately before every `DIV BX` instruction.

### 3. Gibberish Characters or Smilies on Screen
- **Error**: Prompts display strange characters (like `$$$`, unprintable ASCII, or blank lines).
- **Cause**: `DS` was not initialized. When DOS loads a `.EXE`, `DS` initially points to the Program Segment Prefix (PSP), not the data segment.
- **Fix**: Ensure the first two instructions of `MAIN PROC` load `@DATA` into `DS`:
  ```assembly
  MOV AX, @DATA
  MOV DS, AX
  ```

### 4. DOSBox Path Errors
- **Error**: `Directory does not exist` or `File not found`.
- **Cause**: Spaces in folder paths or paths longer than 8 characters can confuse DOSBox.
- **Fix**: Keep folder paths short and simple without spaces, such as `C:\dosbox\bank`.

---

## Input Validation and Error Handling

1. **Duplicate Account Guard**: `ACCOUNT_CREATED` flag ensures account setup runs only once per session.
2. **PIN Length and Digit Check**: Rejects inputs that are not exactly 4 characters or contain non-digit ASCII values.
3. **Overdraft Protection**: Unsigned comparison `CMP AX, BALANCE` followed by `JA` ensures withdrawals cannot exceed available funds.
4. **Buffer Flush**: Additional character reads consume trailing Enter keystrokes to prevent menu skips.
5. **Character Filtering**: `READ_NUMBER` ignores non-numeric keystrokes during number entry.

---

## College and Interview Learning Guide

For comprehensive academic preparation covering 8086 microprocessor theory, COA curriculum requirements, lab viva questions, and technical interview preparation, refer to the dedicated guide:

- [8086 College and Technical Interview Learning Guide](LEARN_GUIDE.md)

This separate document includes:
- Hardware architecture details: BIU vs. EU, Even/Odd memory banking, multiplexed bus timing, and pin functions (ALE, BHE, M/IO, READY).
- Minimum mode vs. Maximum mode comparison.
- Assembler and linker mechanics: Symbol table creation, location counter, and two-pass assembly.
- Flag register breakdown, memory models, and 8086 addressing modes.
- Procedure calling conventions, downward stack frames, and interrupt dispatch via the IVT.
- Decimal base conversion algorithms (Horner's method and stack remainder reversal).
- Dedicated College Lab Viva Q&A and Systems Engineering Interview Q&A.
- Instruction timing and jump condition cheat sheets.

---

## Project Structure

```
BankCore-8086/
├── .gitignore        Git ignore rules for DOS and assembly build artifacts
├── CONTRIBUTING.md   Contribution guidelines and assembly coding standards
├── LEARN_GUIDE.md    College curriculum, lab viva, and interview preparation guide
├── LICENSE           MIT License
├── README.md         Main project architecture and setup documentation
├── SECURITY.md       Security policy and real-mode memory safety guidelines
├── bank.asm          Main 8086 assembly source code
└── run.bat           Automated build and launch script for DOSBox
```

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.
