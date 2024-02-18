STSEG SEGMENT PARA STACK "STACK"
DB 64 DUP ( "STACK" )
STSEG ENDS

DSEG SEGMENT PARA PUBLIC "DATA"
dump DB 5, ?, 5 DUP('?')
num DW -32
result DW 0
startmes DB 'Enter a number from -999 to 999: $'
errmes DB 10,'Invalid input!$'
resmes DB 10,'Answer: $'
DSEG ENDS

CSEG SEGMENT PARA PUBLIC "CODE"

MAIN PROC FAR
ASSUME CS: CSEG, DS: DSEG, SS: STSEG
PUSH DS
MOV AX, 0 
PUSH AX
MOV AX, DSEG
MOV DS, AX

MOV AX, 03h
INT 10h

CALL inputnumber
CALL printnumber
RET
MAIN ENDP


inputnumber PROC

LEA DX, startmes
MOV AH, 9
INT 21h

LEA DX, dump
MOV AH, 10
INT 21h

XOR CX, CX
MOV CL, dump+1

XOR AX, AX  ;storage for converted number

CMP dump+2, '-'
JZ m11                  ;if negative, jump to m11
MOV SI, OFFSET dump+2   
JMP m12                 ;else jump to m12
m11:
MOV SI, OFFSET dump+3
DEC CX

m12:
XOR DX, DX
MOV DL, 10
MUL DX        ; AX = AX * 10

XOR DX, DX
MOV DL, [SI]
SUB DL, '0'

CMP DL, 0
JL m14      ; if character < '0'
CMP DL, 9
JG m14      ; if character > '9'

ADD AX, DX 
INC SI
LOOP m12

CMP AX, 999
JA m14      ; if number > 999

CMP dump+2, '-'
JNZ m13         ;if positive, jump to m13 
NEG AX
m13:
ADD AX, num
MOV result, AX

LEA DX, resmes
MOV AH, 9
INT 21h
MOV BL, 0  ;no error
JMP m15

m14:
LEA DX, errmes
MOV AH, 9
INT 21h
MOV BL, 1 ;error trigger

m15:
RET
inputnumber ENDP


printnumber PROC

CMP BL, 1
JZ m4      ;invalid input 

XOR BX, BX
MOV BX, result
OR BX, BX
JNS m1
MOV AL, '-'
INT 29h
NEG BX

m1:
MOV AX, BX
XOR CX, CX
MOV BX, 10

m2:
XOR DX, DX
DIV BX
ADD DL, '0'
PUSH DX
INC CX
TEST AX, AX
JNZ m2

m3:
POP AX
INT 29h
LOOP m3

m4:
RET
printnumber ENDP

CSEG ENDS
END MAIN