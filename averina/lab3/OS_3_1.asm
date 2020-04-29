TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
;Данные
FREE_MEM db  'FREE MEMORY:       B ',0DH,0AH,'$'
EXTENDED_MEM db  'EXTENDED MEMORY SIZE:       KB     ',0DH,0AH,'$'

CHAIN_BLOCKS db  'A CHAIN OF BLOCKS OF MEMORY MANAGEMENT: $'
STR_MCB db 0DH,0AH,'MCB:    ',0DH,0AH,'$'

TYPE_MCB_L db  'TYPE MCB: LAST ',0DH,0AH,'$'
TYPE_MCB_NL db  'TYPE MCB: NOT LAST ',0DH,0AH,'$'

; TYPE_MCB_L db  'TYPE MCB: LAST',0DH,0AH,'$'
ADRESS_PSP db '   PSP adress:     h        ',0DH,0AH,'$'
ADRESS db '      Adress:         h $'
SIZE_MEM db '      Size:                $'
SDSC db 'SD/SC:     $'

;Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
and AL,0Fh
cmp AL,09
jbe NEXT
add AL,07
NEXT: add AL,30h
ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
push CX
mov AH,AL
call TETR_TO_HEX
xchg AL,AH
mov CL,4
shr AL,CL
call TETR_TO_HEX ;в AL старшая цифра
pop CX ;в AH младшая
ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;
push BX
mov BH,AH
call BYTE_TO_HEX
mov [DI],AH
dec DI
mov [DI],AL
dec DI
mov AL,BH
call BYTE_TO_HEX
mov [DI],AH
dec DI
mov [DI],AL
pop BX
ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
	loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
	end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-------------------------------
WRITE_PROC PROC near
  push ax
	mov AH,09h
	int 21h
	pop ax
	ret
WRITE_PROC ENDP

WRD_TO_DEC PROC near

			push dx
			push bx
			push cx
			push ax
;
			mov bx,10h
			mul bx
			mov bx,0ah
			xor cx,cx

division:
			div bx ; деление числа на 10

			or dl, 30h
			mov [si], dl  ; запись полученной цифры в строку
			dec si
		  inc cx
			xor dx, dx
			cmp ax, 0h ; если
			jnz division

			pop ax
			pop cx
			pop bx
			pop dx

			ret
WRD_TO_DEC ENDP

F_MEM_FUNC PROC near

			mov ah, 4ah
			mov bx, 0ffffh
			int 21h

			mov ax, bx

			mov si, offset 	FREE_MEM
			add si, 18

			call WRD_TO_DEC

			mov dx, offset FREE_MEM
			call WRITE_PROC

			ret
F_MEM_FUNC ENDP

EXT_MEM_FUNC PROC near

			mov al, 30h ; запись адреса ячейки CMOS
			out 70h, al
			in al, 71h	 ; чтение младшего байта
			mov bl, al  ; размера расширенной памяти

			mov al, 31h ; запись адреса ячейки CMOS
			out 70h, al
			in al, 71h  ; чтение старшего байта размера расширенной памяти
			mov bh, al

			mov ax, bx

			mov si, offset 	EXTENDED_MEM
			add si, 27

			call WRD_TO_DEC

			mov dx, offset EXTENDED_MEM
			call WRITE_PROC

			ret
EXT_MEM_FUNC ENDP


MCB PROC near

		push ax
		push bx
		push cx
		push dx
		push si

		mov ah, 52h
		int 21H

		mov dx, offset CHAIN_BLOCKS  ; вывод номера блока
		call WRITE_PROC

		mov ax, es:[bx - 2]
		mov es, ax

		xor cx, cx
		inc cx

loop_mcb:

		mov si, offset STR_MCB
		add si, 5
		mov ax,cx
		push cx
		call BYTE_TO_DEC
		mov dx, offset STR_MCB  ; вывод номера блока
		call WRITE_PROC

		mov ax, es  ; адрес MCD
	  mov di, offset ADRESS
	  add di, 21
	  call WRD_TO_HEX
	  mov dx, offset ADRESS
	  call WRITE_PROC

		xor ah, ah
		mov al, es:[0]  ; сохраняем тип MCB
		push ax

		mov ax, es:[1] ; получение адреса PSP
		mov di, offset ADRESS_PSP  ;
		add di, 21
		call WRD_TO_HEX
		mov dx, offset ADRESS_PSP
		call WRITE_PROC   ; вывод адреса PS

		mov ax, es:[3]
		mov si, offset SIZE_MEM
		add si, 22
		call WRD_TO_DEC
		mov dx, offset SIZE_MEM
		call WRITE_PROC   ; вывод адреса PS

		mov dx, offset SDSC  ; вывод номера блока
		call WRITE_PROC

		mov cx, 8  ; счетчик цикла
		xor di, di


print_char:
		mov dl, es:[8 + di]
		mov ah, 02h  ; печать символа
		int 21H
		inc di   ; переход к следующему
		loop print_char

		mov ax, es:[3] ; находим размер участка

		mov bx, es  ; сохраняем адрес начала блока
		add bx, ax  ; вычисляем адрес конца блока
		inc bx      ; адрес следующего блока
		mov es,bx		; переходим к следующему блоку

		pop ax      ; тип блока MCB

		pop cx
		inc cx			; увеличиваем счетчик

		cmp al, 5Ah
		je end_
		cmp al, 4Dh
		jne end_
		jmp loop_mcb



end_:
		pop si
    pop dx
    pop cx
    pop bx
    pop ax

		ret
MCB ENDP


BEGIN:

call F_MEM_FUNC
call EXT_MEM_FUNC
call MCB

xor AL,AL
mov AH,4Ch
int 21H
TESTPC ENDS
END START ;
