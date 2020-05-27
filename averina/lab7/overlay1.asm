CODE SEGMENT
ASSUME CS:CODE, DS:NOTHING, SS:NOTHING, ES:NOTHING

MAIN PROC FAR
  push ds
  push di
	push ax
	push dx

	mov ax, CS
	mov DS, ax

	mov di, offset STR_ADDRESS
	add di, 25
	call WRD_TO_HEX
	mov dx, offset STR_ADDRESS
	call WRITE_PROC

	pop dx
	pop ax
  pop di
  pop ds
	RETF
MAIN ENDP

STR_ADDRESS db 'Overlay #1 adress:                ',0DH,0AH,'$'

WRITE_PROC PROC NEAR
		push	ax
		mov 	ah, 09h
		int 	21h
		pop 	ax
		ret
WRITE_PROC ENDP

TETR_TO_HEX PROC NEAR
		and 	AL,0Fh
		cmp 	AL,09
		jbe 	NEXT
		add 	AL,07
NEXT: 	add 	AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR		;байт в AL переводится в два символа шестн. числа в AX
		push 	CX
		mov 	AH,AL
		call 	TETR_TO_HEX
		xchg 	AL,AH
		mov 	CL,4
		shr 	AL,CL
		call 	TETR_TO_HEX 	;в AL старшая цифра
		pop 	CX 				;в AH младшая
		ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR ;перевод в 16 с/с 16-ти разрядного числа, в AX - число, DI - адрес последнего символа
		push	BX
		mov		BH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		dec		DI
		mov		AL,BH
		xor		AH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		pop		BX
		ret
WRD_TO_HEX		ENDP
CODE ENDS
END
