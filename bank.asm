.MODEL SMALL
.STACK 100H

.DATA
TITLE_MSG DB 13,10,'====================================',13,10
          DB '     BANKCORE-8086 BANK SYSTEM',13,10
          DB '====================================',13,10,'$'

WELCOME DB 13,10,'1. Create Account',13,10
        DB '2. Login',13,10
        DB '3. Exit',13,10
        DB 'Enter Choice: $'

EXIT_MSG DB 13,10,'Thank You For Banking With Us!',13,10,'$'

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    MOV AH,4CH
    INT 21H
MAIN ENDP
END MAIN
