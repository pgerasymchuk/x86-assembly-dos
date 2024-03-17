; matrix-search.asm refactored using macros from macros.inc

INCLUDE macros.inc


STSEG SEGMENT PARA STACK "STACK"
DB 64 DUP ("STACK")
STSEG ENDS


DSEG SEGMENT PARA PUBLIC "DATA"
input           DB 7, ?, 7 DUP ('?')    ; used by INPUTNUMBER
number          DW 0                    ; returned by INPUTNUMBER
wasfound        DB 0                    ; used in FINDCOORDS
tosearch        DW 0                    ; used in FINDCOORDS
matrix          DW 400 DUP(0)
rows            DW 0                   
columns         DW 0   
i               DW 0                    ; used in INPUTMATRIX, PRINTMATRIX, FINDCOORDS
j               DW 0                    ; used in INPUTMATRIX, PRINTMATRIX, FINDCOORDS
minsize         DW 1
maxsize         DW 20
mininput        DW -32767               ; used by INPUTNUMBER
maxinput        DW 32767                ; used by INPUTNUMBER
minnum          DW -32767
maxnum          DW 32767
newline         DB 13, 10, '$'
rowsmes         DB 13, 10, 10, 'Enter the number of rows (from 1 to 20): $' 
columnsmes      DB 10, 'Enter the number of columns (from 1 to 20): $'
elementmes1     DB 10, 'Enter element with row = $'
elementmes2     DB ', column = $'
elementmes3     DB ' (in range [-32767, 32767]): $'
matrixmes       DB 13, 10, 'Matrix:$'
askmes          DB 13, 10, 'What do you want to do? [1-print,2-search, other digit-enter another matrix]: $'
searchmes       DB 13, 10, 'Enter the value to search for (in range [-32767, 32767]): $'
coordsmes       DB 13, 10, 'Coordinates of all corresponding elements:$'
notfoundmes     DB 13, 10, 'The element was not found!$'
errmes          DB 13, 10, 'Invalid input! Enter the number again: $'
DSEG ENDS 





CSEG SEGMENT PARA PUBLIC "CODE"

MAIN PROC FAR

    ASSUME CS: CSEG, DS: DSEG, SS: STSEG
    PUSH DS
    MOV AX, 0
    PUSH AX
    MOV AX, DSEG
    MOV DS, AX

    MOV AX, 03h             ; clear console
    INT 10h

startmain: 
    
    INPUTMATRIX
    PRINTMATRIX
    
ask:
    
    LEA DX, askmes
    INPUTNUMBER
    MOV AX, number 
    
    CMP AX, 1
    JE callprintmatrix
    
    CMP AX, 2
    JE callfindcoords
    
    JMP startmain           ; otherwise, enter another matrix

callprintmatrix:
    
    PRINTMATRIX
    JMP ask
    
callfindcoords:
    
    FINDCOORDS
    JMP ask

RET
MAIN ENDP


CSEG ENDS
END MAIN


