CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:STACK_

DATA SEGMENT
    FLAG_ERROR dw 0
    ERROR_FINISH db 'The program ended with an error.', 0DH,0AH,'$'
    ERROR_MEM_7 db 'ERROR EXTRA MEMORY! Error 7: The control block of memory is destroyed.',0DH,0AH,'$'
    ERROR_MEM_8 db 'ERROR EXTRA MEMORY! Error 8: Not enough memory to execute function.',0DH,0AH,'$'
    ERROR_MEM_9 db 'ERROR EXTRA MEMORY! Error 9: Invalid memory block address.',0DH,0AH,'$'
    SUCCESS_STR db 'FREE MEMORY: SUCCESS',0DH,0AH,'$'
    PATH_OVERLAY 		db 50h	dup (0), '$'

    ERROR_SIZE_2 db 'File not found.',0DH,0AH,'$'
    ERROR_SIZE_3 db 'Path not found.',0DH,0AH,'$'

    ERROR_LOAD_1 db 'Non-existent function.',0DH,0AH,'$'
    ERROR_LOAD_2 db 'File not found.',0DH,0AH,'$'
    ERROR_LOAD_3 db 'Path not found.',0DH,0AH,'$'
    ERROR_LOAD_4 db 'Too many open files.',0DH,0AH,'$'
    ERROR_LOAD_5 db 'No access.',0DH,0AH,'$'
    ERROR_LOAD_8 db 'Not enough memory.',0DH,0AH,'$'
    ERROR_LOAD_10 db 'Wrong environment.',0DH,0AH,'$'
		KEEP_PSP 			dw 0
		DTA 				db 43 dup (0), '$'
    OVL_OFFSET dw  0
    PATH_OVERLAY_1		db 'OVERLAY1.OVL', 0
    PATH_OVERLAY_2 		db 'OVERLAY2.OVL', 0
    CURSOR dw 0
    OVERLAY_POINT	dw 0
    OVERLAY_START dd 0
DATA 	ENDS


DEL_EXTRA_MEMORY PROC NEAR
    push ax
    push dx
    push bx

    mov ax,STACK_
		mov bx,es
		sub ax,bx
		add	ax,100h
		mov bx,ax
		mov ah,4Ah
		int 21h

    jnc  SUCCESS_MEM
    mov FLAG_ERROR, 1

    cmp ax, 7
    jne error_8
    mov dx, offset ERROR_MEM_7
    error_8:
    cmp ax, 8
    jne error_9
    mov dx, offset ERROR_MEM_8
    error_9:
    cmp ax, 9
    jne SUCCESS_MEM
    mov dx, offset ERROR_MEM_9

    call WRITE_PROC
    xor		al,al
    mov		ah,4Ch
    int 	21h
    SUCCESS_MEM:
    pop bx
    pop dx
    pop ax
    ret
DEL_EXTRA_MEMORY ENDP


MAKE_PATH PROC NEAR
    push ax
    push cx
    push dx
    push si
    push di
    push es

    mov OVL_OFFSET, ax

    mov ES, KEEP_PSP
    mov ES, ES:[2ch]
    xor si, si

  FIND_START:
    mov ax, ES:[si]
    inc si
    cmp ax, 0
    jne FIND_START
    add si, 3   ; байт нулей
    mov di, 0

    mov di, offset PATH_OVERLAY

  WRITE:
    mov al, ES:[si]
    cmp al, 0
    je  NAME_PROG     ; конец строки

    cmp al, '\'
    jne PRINT_
    mov CURSOR, di
  PRINT_:
    mov [di], al
    inc di
    inc si
    jmp WRITE

  NAME_PROG:
    mov di, CURSOR               ; переход на позицию последнего слеша
    inc di
    mov si, OVL_OFFSET
    mov cx, 8
  looop:
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    cmp dl, 0
    jne looop

    mov dx, offset PATH_OVERLAY
    call WRITE_PROC

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    RET
MAKE_PATH ENDP

MEM_SIZE	 PROC NEAR
		push	bx
		push 	es
		push 	si

    mov 	ax, 1A00h
		mov 	dx, offset DTA
		int 	21h

    mov al, 0
    mov ah, 4Eh
    mov cx, 0
    mov dx, offset PATH_OVERLAY
    int 21h

    jnc  SUCCESS_SIZE
    mov FLAG_ERROR, 1

    cmp ax, 2
    jne error_size3
    mov dx, offset ERROR_SIZE_2

error_size3:
    mov dx, offset ERROR_SIZE_3
    call WRITE_PROC
    jmp F_

SUCCESS_SIZE:

    mov si, offset DTA
    add si, 1AH

    mov bx, [si]
    mov cl, 4
    shr bx, cl      ;  перевод в параграфы

    mov ax, [si+2]
    mov cl, 12
    shl ax, cl

    add bx, ax
    add bx, 2
    mov al, 0
    mov ah, 48h
    int 21h

    jnc SUCCESS_DTA
    mov FLAG_ERROR, 1
    jmp F_

    SUCCESS_DTA:
    mov OVERLAY_POINT, ax
F_:
		pop 	si
		pop 	es
		pop 	bx
		ret
MEM_SIZE  ENDP


LOAD_OVERLAY PROC NEAR
    push dx
    push ax
    push ES

    mov ax, DS
    mov ES, ax
		mov bx, offset OVERLAY_POINT

		mov 	dx, offset PATH_OVERLAY
		mov 	ax, 4B03h
		int 	21h

    jnc SUCCESS_LOAD
    mov FLAG_ERROR, 1

    push dx
    cmp ax, 1
    jne error_load_2_
    mov dx, offset ERROR_LOAD_1

  error_load_2_:
    cmp ax, 2
    jne error_load_3_
    mov dx, offset ERROR_LOAD_2
  error_load_3_:
    cmp ax, 3
    jne error_load_4_
    mov dx, offset ERROR_LOAD_3
  error_load_4_:
    cmp ax, 4
    jne error_load_5_
    mov dx, offset ERROR_LOAD_4
  error_load_5_:
    cmp ax, 5
    jne error_load_8_
    mov dx, offset ERROR_LOAD_5
  error_load_8_:
    cmp ax, 8
    jne error_load_10_
    mov dx, offset ERROR_LOAD_8
  error_load_10_:
    mov dx, offset ERROR_LOAD_10

    call WRITE_PROC
    pop dx

		jmp		END_LOAD
SUCCESS_LOAD:
    mov ax, OVERLAY_POINT
    mov ES, ax

    mov word ptr OVERLAY_START + 2, ax
    call OVERLAY_START
    mov ES, ax
    xor al, al
    mov AH, 49h
    int 21h

END_LOAD:
    pop ES
    pop ax
    pop dx
		ret
LOAD_OVERLAY ENDP

WRITE_PROC PROC NEAR
		push	ax
		mov 	ah, 09h
		int 	21h
		pop 	ax
		ret
WRITE_PROC ENDP

MAIN PROC FAR
		mov 	ax, seg DATA
		mov 	ds, ax
		mov 	KEEP_PSP, es

		call 	DEL_EXTRA_MEMORY
    cmp FLAG_ERROR, 1
    je end_ERROR
;-------------------------------------------------
		mov 	ax, offset PATH_OVERLAY_1
		call 	MAKE_PATH
		call 	MEM_SIZE
    cmp FLAG_ERROR, 1
    je end_ERROR

		call 	LOAD_OVERLAY
    cmp FLAG_ERROR, 1
    je end_ERROR

;-------------------------------------------------
		mov 	ax, offset PATH_OVERLAY_2
		call 	MAKE_PATH
		call 	MEM_SIZE
    cmp FLAG_ERROR, 1
    je end_ERROR

		call 	LOAD_OVERLAY
    cmp FLAG_ERROR, 1
    je end_ERROR

    jmp end_point
end_ERROR:
    mov dx, offset ERROR_FINISH
    call WRITE_PROC
end_point:
		xor 	al, al
		mov 	ah, 4Ch
		int 	21H
		ret
MAIN ENDP
CODE ENDS

STACK_ SEGMENT  STACK
        dw 100 dup(?)
STACK_ ENDS
END MAIN
