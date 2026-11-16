# Security Policy: BankCore-8086

This document outlines the security considerations, threat model, and vulnerability reporting procedure for BankCore-8086.

Because BankCore-8086 is written in 16-bit x86 Real-Mode Assembly for MS-DOS and DOSBox environments, it operates under unique architectural constraints distinct from modern operating systems.

---

## Supported Versions

| Version | Supported | Status |
| :--- | :---: | :--- |
| `1.0.x` (main) | Yes | Active maintenance and security bug fixes |
| `< 1.0.0` | No | Deprecated legacy prototypes |

---

## Reporting a Vulnerability

If you discover a security vulnerability, integer overflow vulnerability, or memory corruption bug within BankCore-8086, please report it responsibly:

1. **Do not open a public GitHub issue.**
2. Send an email to the project maintainer:
   - Contact: **adityavardhan09092@gmail.com**
   - Subject: `[SECURITY] BankCore-8086 Vulnerability Report`
3. Include the following details in your report:
   - Description of the vulnerability and its potential impact.
   - Exact input sequence or keystroke pattern required to reproduce the behavior in DOSBox / EMU8086.
   - Affected registers and memory addresses observed during debugging.
   - Suggested fix or assembly patch, if available.
4. Expected Response Timeline:
   - Initial acknowledgement: within 48 hours.
   - Assessment and status update: within 5 business days.
   - Public patch release: coordinated after verification.

---

## Architectural Threat Model and Mitigations

In Intel 8086 real-mode execution, the processor lacks hardware-enforced memory protection (no paging, no descriptor tables, and no privilege rings). All software runs with full access to the entire 1 MB physical address space.

Within this execution model, BankCore-8086 implements defensive software-level security measures:

### 1. Buffer Overflow Prevention (DOS Function 0AH)
- **Risk**: An attacker typing input exceeding buffer allocations could overwrite neighboring variables in the Data Segment (such as `BALANCE` or `PIN_DATA`).
- **Mitigation**:
  - All input buffers define strict maximum character limits in byte 0 (`NAME_BUF DB 30`, `MOBILE_BUF DB 11`, `PIN_BUF DB 5`).
  - The DOS kernel automatically rejects additional keystrokes once the maximum capacity is reached.
  - Zero-length input checks (`JCXZ`) guard against copying uninitialized memory if Enter is pressed without typing.

### 2. Memory Leakage and String Delimitation
- **Risk**: DOS Function `09H` prints memory until it finds an ASCII dollar sign (`$`). If strings copied into memory lack a terminator, adjacent memory (including PIN credentials) will leak to the console.
- **Mitigation**:
  - The copy routines (`COPY_NAME`, `COPY_MOBILE`) explicitly write a `$` terminator at the destination offset immediately upon loop completion:
    ```assembly
    NAME_DONE:
        MOV BYTE PTR [SI], '$'
    ```

### 3. Credential and PIN Verification
- **Risk**: PIN tampering or partial prefix matching allowing authentication bypass.
- **Mitigation**:
  - The PIN validation logic checks that the entered string length is exactly 4 characters (`CMP BYTE PTR PIN_BUF+1, 4`).
  - Each character is bounds-checked against ASCII digits (`'0'` to `'9'`).
  - The login routine checks all 4 bytes sequentially using `CMP AL, [DI]`, branching to `LOGIN_ERROR` upon any single mismatch.

### 4. Arithmetic Underflow and Integer Wrap-Around
- **Risk**:
  - If a user withdraws more money than their available balance, a naive `SUB` can wrap around $0$ to $65,535$, creating unauthorized funds.
  - If a deposit exceeds the maximum 16-bit capacity ($65,535$), arithmetic addition wraps around to a lower balance.
- **Mitigation**:
  - Unsigned magnitude comparisons (`CMP AX, BALANCE` followed by `JA INSUFFICIENT_BALANCE`) are enforced prior to any debit operation.
  - The codebase uses unsigned conditional branching exclusively (`JA`, `JB`, `JAE`, `JBE`) to eliminate sign-bit misinterpretation.

### 5. Keyboard Injection and Residue Sanitization
- **Risk**: Residual newline (`0DH`) or linefeed (`0AH`) bytes remaining in the keyboard queue can be unintentionally consumed by subsequent menus, leading to unexpected state transitions.
- **Mitigation**:
  - Single-character menu reads employ an immediate secondary consumption read to flush the keyboard buffer before branching.
