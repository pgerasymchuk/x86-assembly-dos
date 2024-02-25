STSEG SEGMENT PARA STACK "STACK"
DB 64 DUP ("STACK")
STSEG ENDS




DSEG SEGMENT PARA PUBLIC "DATA"
input 			DB 7, ?, 7 DUP ('?')
number 			DW 0
x 				DW 0
y 				DW 0
sumxy 			DW 0
prodxy 			DW 0
z 				DW 0
remainder		DW 0
toprint			DW 0
maxnum			DW 32767
enterxmes 		DB 10, 'Enter x (in range [-32767, 32767]): $'	; '\n' = 10
enterymes 		DB 10, 'Enter y (in range [-32767, 32767]): $'
errmes 			DB 10, 'Invalid input! Enter the number again: $'
overflowmes 	DB 10, 'Impossible to perform calculation. Overflow happened.$'
resmes       	DB 10, 'Z = $'
DSEG ENDS 




CSEG SEGMENT PARA PUBLIC "CODE"


MAIN PROC FAR

ASSUME CS: CSEG, DS: DSEG, SS: STSEG
PUSH DS
MOV AX, 0
PUSH AX
MOV AX, DSEG
MOV DS, AX

MOV AX, 03h   			; clear console
INT 10h


startmain:

	MOV remainder, 0

	LEA DX, enterxmes	
	CALL INPUTNUMBER   	; for entering x
	MOV AX, number
	MOV x, AX

	LEA DX, enterymes 	
	CALL INPUTNUMBER	; for entering y
	MOV AX, number
	MOV y, AX

	CMP y, 0
	JL ynegative		; jump if y < 0
	JE yzero			; jump if y == 0

	CMP x, 0			; y > 0, need to check x
	JLE othercase		; jump if x <= 0

	MOV AX, x			; otherwise, z = (x+y)/xy 
	ADD AX, y
	JC overflow			; x+y is out of [0, 65536] range
	MOV sumxy, AX		; sumxy = x + y

	MOV AX, x 
	MOV DX, y 
	MUL DX				; DX:AX = AX * DX

	CMP DX, 0
	JNE overflow
	CMP AX, maxnum
	JA overflow			; x*y > 32767
	MOV prodxy, AX		; prodxy = x * y

	XOR DX, DX
	MOV AX, sumxy
	MOV BX, prodxy
	DIV BX
	MOV z, AX
	MOV remainder, DX	; (x+y)/xy = z + remainder/xy
	
	JMP printresult

othercase:				; 4th case

	MOV z, 1
	JMP printresult

overflow:

	LEA DX, overflowmes		; print overflow message
	MOV AH, 9
	INT 21h

	JMP endmain

ynegative:				; 2nd case

	CMP x, 0
	JGE othercase		; jump if y < 0 and x >= 0

	XOR DX, DX
	XOR AX, AX
	MOV DX, y
	MOV AX, 25
	IMUL DX  			; DX:AX = AX * DX

	CMP DX, -1 
	JNE overflow		; AX*DX = 25*y < -65536

	CMP AX, 32768
	JB overflow			; DX:AX = 25*y < -32768

	MOV z, AX			
	JMP printresult
		
yzero:					; 3rd case

	CMP x, 10
	JLE othercase		; jump if x <= 10 and y == 0

	XOR DX, DX
	XOR AX, AX
	MOV DX, x
	MOV AX, 6
	IMUL DX				; DX:AX = AX * DX

	CMP DX, 0
	JNE overflow		; AX*DX = 6*x > 65535
	CMP AX, maxnum
	JA overflow			; AX*DX = 6*x > 32767

	MOV z, AX 			; otherwise, z = 6*x, finish 
	JMP printresult

printresult:

	LEA DX, resmes
	MOV AH, 9
	INT 21h

	MOV AX, z 
	MOV toprint, AX
	CALL PRINTNUMBER		; print z

	CMP remainder, 0
	JE endmain				; finish if remainder == 0

	MOV AL, ' '				; print space between z and remainder
	INT 29h

	MOV AX, remainder
	MOV toprint, AX
	CALL PRINTNUMBER		; print remainder

	MOV AL, '/'				; print '/' symbol
	INT 29h

	MOV AX, prodxy
	MOV toprint, AX
	CALL PRINTNUMBER		; print divisor (xy)


endmain:

	MOV AL, 13				; '\r' = 13
	INT 29h					

	MOV AL, 10				; '\n' = 10
	INT 29h					; print new line

	JMP startmain

RET
MAIN ENDP


INPUTNUMBER PROC			; stores entered number in 'number'

	MOV AH, 9				; print message defined in MAIN
	INT 21h

startinputnumber:

	LEA DX, input			; enter value
	MOV AH, 10
	INT 21h

	XOR CX, CX
	MOV CL, input+1  		; determine length of input

	XOR AX, AX				; storage for converted number

	CMP input+2, '-'
	JZ negativenumber 		; entered number is negative

	MOV SI, OFFSET input+2 	; digits start at input+2 position
	JMP positivenumber
	
negativenumber:

	MOV SI, OFFSET input+3 	; digits start at input+3 position
	DEC CX					; number of digits is less by 1 

positivenumber:

	XOR BX, BX
	MOV BX, 10
	MUL BX					; AX = AX * 10

	CMP DX, 0
	JNE invalidinput		; DX:AX = AX*10 is out of [-32768, 32767] range

	XOR DX, DX
	MOV DL, [SI]
	SUB DL, '0'   			; DL now contains value of digit

	CMP DL, 0
	JL invalidinput			; if character < '0'
	CMP DL, 9
	JG invalidinput			; if character > '9'

	ADD AX, DX				; add digit to converted number

	JC invalidinput			; inform about overflow

	CMP AX, maxnum			; check if AX > 32767
	JA invalidinput

	INC SI
	LOOP positivenumber

	CMP input+2, '-'
	JNZ endinputnumber		; finish if number is positive  

	NEG AX					; multiply by (-1) if negative
	JMP endinputnumber		


invalidinput:

	LEA DX, errmes			; print error message
	MOV AH, 9
	INT 21h
	JMP startinputnumber 	; enter number again


endinputnumber:

MOV number, AX

RET
INPUTNUMBER ENDP


PRINTNUMBER PROC			; prints number stored in 'toprint'

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