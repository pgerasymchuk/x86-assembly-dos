STSEG SEGMENT PARA STACK "STACK"
DB 64 DUP ("STACK")
STSEG ENDS


DSEG SEGMENT PARA PUBLIC "DATA"
input           DB 7, ?, 7 DUP ('?')    ; used by INPUTNUMBER
number          DW 0                    ; returned by INPUTNUMBER
toprint         DW 0                    ; passed to PRINTNUMBER
tosearch        DW 0                    ; passed to FINDCOORDS
wasfound        DB 0                    ; used in FINDCOORDS
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
    
    CALL INPUTMATRIX
    CALL PRINTMATRIX
    
ask:
    
    LEA DX, askmes
    CALL INPUTNUMBER
    MOV AX, number 
    
    CMP AX, 1
    JE callprintmatrix
    
    CMP AX, 2
    JE callfindcoords
    
    JMP startmain           ; otherwise, enter another matrix

callprintmatrix:
    
    CALL PRINTMATRIX
    JMP ask
    
callfindcoords:
    
    CALL FINDCOORDS
    JMP ask

RET
MAIN ENDP


INPUTMATRIX PROC

    MOV AX, minsize
    MOV mininput, AX
    MOV AX, maxsize
    MOV maxinput, AX        ; set limits for number of columns and rows for INPUTNUMBER
    
    LEA DX, rowsmes            
    CALL INPUTNUMBER        ; enter the number of rows of the matrix
    MOV AX, number
    MOV rows, AX
    
    LEA DX, columnsmes            
    CALL INPUTNUMBER        ; enter the number of columns of the matrix
    MOV AX, number
    MOV columns, AX
    
    MOV AX, minnum
    MOV mininput, AX
    MOV AX, maxnum
    MOV maxinput, AX        ; set limit for elements for INPUTNUMBER
    
    XOR BX, BX
    XOR DI, DI
    
enterelement:
    
    MOV i, BX
    MOV j, DI
    
    LEA DX, elementmes1
    MOV AH, 9
    INT 21h                 ; 'Enter element with row = '
    
    MOV AX, i
    INC AX
    MOV toprint, AX
    CALL PRINTNUMBER
    
    LEA DX, elementmes2
    MOV AH, 9
    INT 21h                 ; ', column = $'   
    
    MOV AX, j
    INC AX
    MOV toprint, AX
    CALL PRINTNUMBER
    
    LEA DX, elementmes3     ; ' (in range [-32767, 32767]): $'            
    
    CALL INPUTNUMBER
    
    MOV BX, i
    MOV DI, j
    
    PUSH BX
    SHL BX, 1               ; BX = BX * 2
    SHL DI, 1               ; DI = DI * 2
    MOV AX, columns
    MUL BX                  
    MOV BX, AX              ; BX = BX * columns
    
    MOV AX, number
    MOV matrix[BX][DI], AX
    
    
    SHR DI, 1               ; DI = DI / 2
    POP BX
    
    INC DI
    
    CMP DI, columns
    JL enterelement
    
    INC BX
    CMP BX, rows            ; if DI == columns, check BX
    JNL endinputmatrix      ; if DI == columns and BX == rows, finish entering 
                      
    XOR DI, DI              ; if DI == columns, but BX < rows, enter next row
    JMP enterelement
    
endinputmatrix:

RET
INPUTMATRIX ENDP




PRINTMATRIX PROC

    LEA DX, matrixmes
    MOV AH, 9
    INT 21h
    
    LEA DX, newline
    MOV AH, 9
    INT 21h                 ; print new line

    XOR BX, BX
    XOR DI, DI

printelement:
    
    PUSH BX
    SHL BX, 1               ; BX = BX * 2
    SHL DI, 1               ; DI = DI * 2
    MOV AX, columns
    MUL BX
    MOV BX, AX              ; BX = BX * columns
    
    MOV AX, matrix[BX][DI]
    
    SHR DI, 1               ; DI = DI / 2
    POP BX
    
    PUSH BX
    MOV toprint, AX
    CALL PRINTNUMBER
    POP BX
    
    MOV AH, 2
    MOV DL, 9
    INT 21h                 ; printing tab character
    
    INC DI
    
    CMP DI, columns
    JL printelement
    
    INC BX
    CMP BX, rows            ; if DI == columns, check BX
    JNL endprintmatrix      ; if DI == columns and BX == rows, finish printing 
                      
    XOR DI, DI              ; if DI == columns, but BX < rows, print next row
   
    LEA DX, newline
    MOV AH, 9
    INT 21h                 ; print new line
    
    JMP printelement

endprintmatrix:
    
RET
PRINTMATRIX ENDP


FINDCOORDS PROC

    LEA DX, searchmes
    CALL INPUTNUMBER
    MOV AX, number
    MOV tosearch, AX

    XOR BX, BX
    XOR DI, DI
    MOV wasfound, 0

nextelement:
    
    PUSH BX
    SHL BX, 1               ; BX = BX * 2
    SHL DI, 1               ; DI = DI * 2
    MOV AX, columns
    MUL BX
    MOV BX, AX              ; BX = BX * columns
    
    MOV AX, matrix[BX][DI]
    
    SHR DI, 1               ; DI = DI / 2
    POP BX
    
    CMP AX, tosearch
    JNE notequal
    
    MOV AL, wasfound        ; element was found
    CMP AL, 1
    JE printfoundcoords     ; element was found before, no need to print message again
    
    LEA DX, coordsmes       ; otherwise, print coordsmes
    MOV AH, 9
    INT 21h        
    
printfoundcoords:
    
    MOV wasfound, 1
    
    LEA DX, newline
    MOV AH, 9
    INT 21h                 ; print new line
    
    PUSH BX
    PUSH DI
    
    MOV AX, BX
    INC AX
    MOV toprint, AX         ; toprint = BX + 1
    CALL PRINTNUMBER        ; print row coord
    
    MOV AL, ' '
    INT 29h                 ; print space character
    
    MOV AX, DI
    INC AX
    MOV toprint, AX         ; toprint = DI + 1
    CALL PRINTNUMBER        ; print column coord
   
    POP DI
    POP BX

notequal:

    INC DI
    
    CMP DI, columns
    JL nextelement
    
    INC BX
    CMP BX, rows            ; if DI == columns, check BX
    JNL notfound            ; if DI == columns and BX == rows, finish searching 
                      
    XOR DI, DI              ; if DI == columns, but BX < rows, go to the next row
    
    JMP nextelement

notfound:
    
    MOV AL, wasfound
    CMP AL, 0
    JNE endfindcoords
    
    LEA DX, notfoundmes
    MOV AH, 9
    INT 21h                 ; print not found message
    
endfindcoords:

RET
FINDCOORDS ENDP



INPUTNUMBER PROC            ; stores entered number in 'number'

    MOV AH, 9               ; print message defined in MAIN
    INT 21h

startinputnumber:

    LEA DX, input           ; enter value
    MOV AH, 10
    INT 21h

    XOR CX, CX
    MOV CL, input+1         ; determine length of input

    XOR AX, AX              ; storage for converted number

    CMP input+2, '-'
    JZ negativenumber       ; entered number is negative

    MOV SI, OFFSET input+2  ; digits start at input+2 position
    JMP positivenumber
    
negativenumber:

    MOV SI, OFFSET input+3  ; digits start at input+3 position
    DEC CX                  ; number of digits is less by 1 

positivenumber:

    XOR BX, BX
    MOV BX, 10
    MUL BX                  ; AX = AX * 10

    CMP DX, 0
    JNE invalidinput        ; DX:AX = AX*10 is out of [-32768, 32767] range

    XOR DX, DX
    MOV DL, [SI]
    SUB DL, '0'             ; DL now contains value of digit

    CMP DL, 0
    JL invalidinput         ; if character < '0'
    CMP DL, 9
    JG invalidinput         ; if character > '9'

    ADD AX, DX              ; add digit to converted number

    JC invalidinput         ; inform about overflow

    CMP AX, maxinput        
    JA invalidinput

    INC SI
    LOOP positivenumber

    CMP input+2, '-'
    JNZ endinputnumber      ; finish if number is positive  

    NEG AX                  ; multiply by (-1) if negative
    JMP endinputnumber      


invalidinput:

    LEA DX, errmes          ; print error message
    MOV AH, 9
    INT 21h
    JMP startinputnumber    ; enter number again


endinputnumber:
    
    CMP AX, mininput
    JL invalidinput
    MOV number, AX

RET
INPUTNUMBER ENDP


PRINTNUMBER PROC            ; prints number stored in 'toprint'

    XOR BX, BX
    MOV BX, toprint
    OR BX, BX
    JNS positiveoutput

    MOV AL, '-'
    INT 29h
    NEG BX

positiveoutput:

    MOV AX, BX
    XOR CX, CX
    MOV BX, 10

dividebyten:
    XOR DX, DX
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ dividebyten

printdigit:
    POP AX
    INT 29h
    LOOP printdigit

RET
PRINTNUMBER ENDP


CSEG ENDS
END MAIN




