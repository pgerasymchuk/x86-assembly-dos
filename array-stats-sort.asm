STSEG SEGMENT PARA STACK "STACK"
DB 64 DUP ("STACK")
STSEG ENDS




DSEG SEGMENT PARA PUBLIC "DATA"
input           DB 7, ?, 7 DUP ('?')    ; used by INPUTNUMBER
number          DW 0                    ; returned by INPUTNUMBER
toprint         DW 0                    ; passed to PRINTNUMBER
array           DW 100 DUP(0)
arrsize         DW 0
arrsum          DW 0
i               DW 0                    ; index for bubble sort
j               DW 0                    ; index for bubble sort
minsize         DW 1
maxsize         DW 100
mininput        DW -32767               ; used by INPUTNUMBER
maxinput        DW 32767                ; used by INPUTNUMBER
minnum          DW -32767
maxnum          DW 32767
sizemes         DB 13, 10, 10, 'Enter the number of elements of the array (from 1 to 100): $' ; '\n' = 10
elementmes      DB 10, 'Enter element (in range [-32767, 32767]): $'
errmes          DB 10, 'Invalid input! Enter the number again: $'
summes          DB 10, 'Sum of the elements: $'
overflowmes     DB 10, 'Overflow happened!$'
minmes          DB 13, 10, 'Min element: $'
maxmes          DB 13, 10, 'Max element: $'
sortedmes       DB 13, 10, 'Sorted array:$'
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
    
    CALL INPUTARRAY
    CALL FINDSUM
    CALL FINDMIN
    CALL FINDMAX
    CALL BUBBLESORT
    CALL PRINTARRAY
    
    JMP startmain

RET
MAIN ENDP


INPUTARRAY PROC

    MOV AX, minsize
    MOV mininput, AX
    MOV AX, maxsize
    MOV maxinput, AX        ; set limits for number of elements for INPUTNUMBER
    
    LEA DX, sizemes            
    CALL INPUTNUMBER        ; enter the number of elements of the array
    
    MOV AX, number
    SHL AX, 1
    MOV arrsize, AX         ; store size of array in bytes in 'arrsize' 
    
    MOV AX, minnum
    MOV mininput, AX
    MOV AX, maxnum
    MOV maxinput, AX        ; set limit for elements for INPUTNUMBER 
    
    XOR DI, DI
    
enterelement:
    
    LEA DX, elementmes 
    CALL INPUTNUMBER
    MOV AX, number
    MOV array[DI], AX
    ADD DI, 2
    CMP DI, arrsize
    JL enterelement
   
RET
INPUTARRAY ENDP


PRINTARRAY PROC

    LEA DX, sortedmes
    MOV AH, 9
    INT 21h
    
    XOR SI, SI

printnextelement:

    MOV AL, 10      ; '\n' = 10
    INT 29h
    
    MOV AL, 13      ; '\r' = 13
    INT 29h         ; print new line
    
    MOV AX, array[SI]
    MOV toprint, AX
    CALL PRINTNUMBER
    ADD SI, 2
    
    CMP SI, arrsize
    JL printnextelement

RET
PRINTARRAY ENDP


FINDSUM PROC

    XOR SI, SI
    XOR BX, BX              ; BX:arrsum is a 32-bit accumulator
    MOV arrsum, 0

sumnextelement:
    
    MOV AX, array[SI]
    CWD                     ; DX:AX = sign-extended element
    ADD arrsum, AX
    ADC BX, DX
    ADD SI, 2
    CMP SI, arrsize
    JL sumnextelement
    
    MOV AX, arrsum
    CWD
    CMP DX, BX              ; the sum fits into a word only if BX is the sign extension of arrsum
    JNE sumoverflow
    
    LEA DX, summes
    MOV AH, 9
    INT 21h
    
    MOV AX, arrsum 
    MOV toprint, AX
    CALL PRINTNUMBER        ; print sum
    
    JMP endfindsum
    
sumoverflow:
    
    LEA DX, overflowmes
    MOV AH, 9
    INT 21h
    
endfindsum:
RET
FINDSUM ENDP



FINDMIN PROC

    XOR SI, SI
    MOV BX, array[SI]       ; current min element

findminnext:

    ADD SI, 2
    CMP SI, arrsize
    JNL endfindmin 
    
    CMP array[SI], BX       ; compare current with current min
    JNL findminnext         ; current is not less than current min
    
    MOV BX, array[SI]       ; otherwise, update current min
    JMP findminnext

endfindmin:
    
    LEA DX, minmes
    MOV AH, 9
    INT 21h
    
    MOV toprint, BX 
    CALL PRINTNUMBER
    
RET 
FINDMIN ENDP



FINDMAX PROC

    XOR SI, SI
    MOV BX, array[SI]       ; current max element

findmaxnext:

    ADD SI, 2
    CMP SI, arrsize
    JNL endfindmax 
    
    CMP array[SI], BX       ; compare current with current max
    JNG findmaxnext         ; current is not greater than current max
    
    MOV BX, array[SI]       ; otherwise, update current max
    JMP findmaxnext

endfindmax:
    
    LEA DX, maxmes
    MOV AH, 9
    INT 21h
    
    MOV toprint, BX 
    CALL PRINTNUMBER
    

RET
FINDMAX ENDP




BUBBLESORT PROC

    MOV i, 0

internalloop:

    MOV AX, arrsize
    SUB AX, 2
    MOV j, AX
    JMP loopj
    
compareelements:
    
    MOV BX, i
    MOV AX, array[BX]
    MOV BX, j
    CMP AX, array[BX]
    JLE less                ; array[i] <= array[j], do not exchange elements
    
    MOV DX, array[BX]       ; DX = array[j]
    MOV array[BX], AX       ; array[j] = array[i]
    MOV BX, i
    MOV array[BX], DX       ; array[i] = DX
    
less:
    
    SUB j, 2
    
loopj:
   
    MOV AX, j
    CMP AX, i
    JG compareelements
    
    ADD i, 2                ; otherwise, i == j, increment i
    MOV AX, arrsize
    CMP i, AX
    JL internalloop
    
RET
BUBBLESORT ENDP


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