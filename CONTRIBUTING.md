# Contributing to BankCore-8086

Thank you for your interest in contributing to BankCore-8086. This project is maintained as an open-source educational implementation of low-level systems programming in 16-bit x86 Real-Mode Assembly.

Contributions that improve stability, enhance documentation, or optimize algorithms are welcome.

---

## Code of Conduct

Please maintain a respectful, constructive, and collaborative tone in issues, discussions, and pull requests.

---

## Getting Started

1. Fork the repository on GitHub: [https://github.com/aditya-forge/BankCore-8086](https://github.com/aditya-forge/BankCore-8086)
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/BankCore-8086.git
   cd BankCore-8086
   ```
3. Set up DOSBox or EMU8086 on your development workstation.

---

## Assembly Coding Guidelines

When contributing code changes to `bank.asm`, please follow these guidelines:

### 1. Register Preservation
- Follow callee-save conventions for any newly introduced subroutine.
- Save modified registers with `PUSH` at the procedure entry and restore them with `POP` in exact reverse order before `RET`.
- Document which registers are clobbered or used to return values in procedure comments.

### 2. Instruction Formatting
- Write instruction mnemonics in uppercase (`MOV`, `ADD`, `CMP`, `INT`, `JMP`).
- Keep label names in uppercase with meaningful names (e.g., `VALIDATE_INPUT:`).
- Indent instructions 4 spaces from labels for visual clarity.
- Keep comments concise and informative, explaining *why* an architectural choice was made rather than repeating the opcode.

### 3. Arithmetic and Bounds Protection
- Use unsigned comparison instructions (`JA`, `JB`, `JAE`, `JBE`) for values representing monetary balances or counts.
- Always clear `DX` using `XOR DX, DX` before any 16-bit division (`DIV Reg16`) to prevent hardware divide overflow crashes (`Interrupt 0`).
- Ensure all string buffers use explicit capacity headers (byte 0) and zero-length guard checks (`JCXZ`) before copying.
- Ensure all displayed strings are strictly terminated with `$` for DOS Function `09H`.

---

## Pull Request Workflow

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your edits and assemble locally in DOSBox or EMU8086:
   ```dos
   masm bank.asm;
   link bank.obj;
   bank.exe
   ```
3. Verify that the system builds with zero errors and zero warnings.
4. Commit your changes with clear, descriptive commit messages describing the problem solved:
   ```bash
   git commit -m "fix: bounds check user deposit input to prevent 16-bit overflow"
   ```
5. Push to your fork and open a Pull Request against the `main` branch.
6. Provide a clear summary in your PR description detailing what was changed and how you verified it in DOSBox.
