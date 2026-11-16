
.MODEL SMALL
.STACK 100H

.DATA

; =============== MESSAGES ===============

TITLE_MSG DB 13,10,'====================================',13,10
          DB '     BANKCORE-8086 BANK SYSTEM',13,10
          DB '====================================',13,10,'$'

WELCOME DB 13,10,'1. Create Account',13,10
        DB '2. Login',13,10
        DB '3. Exit',13,10
        DB 'Enter Choice: $'

NAME_MSG DB 13,10,'Enter Full Name: $'
AGE_MSG DB 13,10,'Enter Age: $'
MOBILE_MSG DB 13,10,'Enter Mobile Number: $'
PIN_MSG DB 13,10,'Create 4 Digit PIN: $'
DEPOSIT_MSG DB 13,10,'Enter Initial Deposit: $'

CREATED DB 13,10,'Account Created Successfully!',13,10,'$'
ACC_MSG DB 'Your Account Number: $'

LOGIN_ACC DB 13,10,'Enter Account Number: $'
LOGIN_PIN DB 13,10,'Enter PIN: $'

LOGIN_OK DB 13,10,'Login Successful!',13,10,'$'
LOGIN_FAIL DB 13,10,'Invalid Account Number or PIN!',13,10,'$'
NO_ACCOUNT DB 13,10,'Please Create Account First!',13,10,'$'

MENU DB 13,10,'========== BANK DASHBOARD ==========',13,10
     DB '1. Check Balance',13,10
     DB '2. Deposit Money',13,10
     DB '3. Withdraw Money',13,10
     DB '4. Change PIN',13,10
     DB '5. Account Details',13,10
     DB '6. Logout',13,10
     DB 'Enter Choice: $'

BAL_MSG DB 13,10,'Available Balance: Rs. $'
DEP_SUCCESS DB 13,10,'Amount Deposited Successfully!',13,10,'$'
WITH_SUCCESS DB 13,10,'Withdrawal Successful!',13,10,'$'

LOW_BAL DB 13,10,'Insufficient Balance!',13,10,'$'

WITHDRAW_PROMPT DB 13,10,'Enter Withdrawal Amount: $'

NEW_PIN_MSG DB 13,10,'Enter New 4 Digit PIN: $'
PIN_CHANGED DB 13,10,'PIN Changed Successfully!',13,10,'$'

DETAIL_MSG DB 13,10,'======= ACCOUNT DETAILS =======',13,10,'$'
NAME_DISPLAY DB 13,10,'Name: $'
AGE_DISPLAY DB 13,10,'Age: $'
MOBILE_DISPLAY DB 13,10,'Mobile: $'
ACCOUNT_DISPLAY DB 13,10,'Account Number: $'

INVALID DB 13,10,'Invalid Choice!',13,10,'$'
INVALID_PIN DB 13,10,'PIN must contain exactly 4 digits!',13,10,'$'

LOGOUT_MSG DB 13,10,'Logged Out Successfully!',13,10,'$'
EXIT_MSG DB 13,10,'Thank You For Banking With Us!',13,10,'$'

; =============== ACCOUNT DATA ===============

NAME_BUF DB 30,0,31 DUP(0)

; FIXED MOBILE BUFFER
MOBILE_BUF DB 11,0,12 DUP(0)

; FIXED PIN BUFFERS
PIN_BUF DB 5,0,6 DUP(0)
NEW_PIN_BUF DB 5,0,6 DUP(0)

NAME_DATA DB 32 DUP('$')
MOBILE_DATA DB 12 DUP('$')
PIN_DATA DB '0000'

AGE DW 0
ACCOUNT_NO DW 1001
BALANCE DW 0

ACCOUNT_CREATED DB 0

CHOICE DB ?

; =============== CODE SECTION ===============

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    LEA DX,TITLE_MSG
    MOV AH,09H
    INT 21H

    LEA DX,EXIT_MSG
    MOV AH,09H
    INT 21H

    MOV AH,4CH
    INT 21H
MAIN ENDP
END MAIN
