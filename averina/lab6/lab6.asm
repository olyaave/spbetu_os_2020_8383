DATA SEGMENT

  FLAG_ERROR dw 0
  ERROR_MEM_7 db 'ERROR EXTRA MEMORY! Error 7: The control block of memory is destroyed.',0DH,0AH,'$'
  ERROR_MEM_8 db 'ERROR EXTRA MEMORY! Error 8: Not enough memory to execute function.',0DH,0AH,'$'
  ERROR_MEM_9 db 'ERROR EXTRA MEMORY! Error 9: Invalid memory block address.',0DH,0AH,'$'
  SUCCESS_STR db 'FREE MEMORY: SUCCESS',0DH,0AH,'$'
  ERROR_LOAD_1 db 'The function number is invalid. ',0DH,0AH,'$'
  ERROR_LOAD_2 db 'File not found. ',0DH,0AH,'$'
  ERROR_LOAD_5 db 'Disk error. ',0DH,0AH,'$'
  ERROR_LOAD_8 db 'Not enough memory. ',0DH,0AH,'$'
  ERROR_LOAD_10 db 'Invalid environment string. ',0DH,0AH,'$'
  ERROR_LOAD_11 db 'The file format is incorrect. ',0DH,0AH,'$'
  SUCCESS_END db 0DH,0AH,'END PROGRAM: SUCCESS',0DH,0AH,'$'
  ERROR__END_1 db 0DH,0AH,'END PROGRAM: Completion by Ctrl-break',0DH,0AH,'$'
  ERROR__END_2 db 'END PROGRAM: Completion by device error',0DH,0AH,'$'
  ERROR__END_3 db 'END PROGRAM: Completion by function 31h',0DH,0AH,'$'

  PROG_NAME db 'OS_2.COM',0
  KEEP_SP dw 0
  KEEP_SS dw 0
  FILE_PATH db 20h dup(0)
  CURSOR dw 0

  PARAM_BLOCK dw 0 ;сегментный адрес среды
					dd 0 ;сегмент и смещение командной строки
					dd 0 ;сегмент и смещение первого FCB
					dd 0 ;сегмент и смещение второго FCB

DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, SS:STACK_

DEL_EXTRA_MEMORY PROC NEAR
		mov ax,STACK_
		mov bx,es
		sub ax,bx
		add	ax,10h
		mov bx,ax
		mov ah,4Ah
		int 21h
    push dx

    pop dx
		jnc  SUCCESS_MEM

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
    ret

SUCCESS_MEM:
    mov dx, offset SUCCESS_STR
    call WRITE_PROC
		ret
DEL_EXTRA_MEMORY ENDP

ERROR_HANDLING_LOAD PROC NEAR

    cmp ax, 1
    jne error_2
    mov dx, offset ERROR_LOAD_1
    jmp _END
    error_2:
    cmp ax, 2
    jne error_5
    mov dx, offset ERROR_LOAD_2
    jmp _END
    error_5:
    cmp ax, 5
    jne error__8
    mov dx, offset ERROR_LOAD_5
    jmp _END
    error__8:
    cmp ax, 8
    jne error_10
    mov dx, offset ERROR_LOAD_8
    jmp _END
    error_10:
    cmp ax, 10
    jne error_11
    mov dx, offset ERROR_LOAD_10
    jmp _END
    error_11:
    cmp ax, 11
    mov dx, offset ERROR_LOAD_11
    jmp _END
_END:
      call WRITE_PROC
      ret
ERROR_HANDLING_LOAD ENDP

LOAD_PROG PROC NEAR

    mov ax, es:[2Ch]
    mov PARAM_BLOCK, ax
    mov PARAM_BLOCK+2, es
    mov	PARAM_BLOCK+4, 80h

    mov ES, ES:[2ch]
    xor si, si

  FIND_START:
    mov ax, ES:[si]
    inc si
    cmp ax, 0
    jne FIND_START
    add si, 3   ; байт нулей
    mov di, 0

    mov di, offset FILE_PATH

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
    mov si, offset PROG_NAME
    mov cx, 8
  looop:
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    cmp dl, 0
    jne looop

; загрузка программы
		mov 	dx, offset FILE_PATH

    mov ax, DATA
    mov es, ax
		mov bx, offset PARAM_BLOCK

		mov KEEP_SP, SP
		mov KEEP_SS, SS

		mov ax,4b00h
		int 21h

    push 	ax
    mov ax,DATA
    mov ds,ax
    pop ax
    mov SS, KEEP_SS
    mov SP, KEEP_SP

		jnc SUCCESS_LOAD_

	error:
		call 	ERROR_HANDLING_LOAD
		ret

SUCCESS_LOAD_:

		mov ax,4d00h
		int 21h

    cmp ah, 0
    je  SUCCESS_END_
    mov dx, offset ERROR__END_1
    cmp ah, 1
    je 	PRINT_ERR_END

    cmp ah, 2
    mov dx,offset ERROR__END_2
    je 	PRINT_ERR_END
    cmp ah, 3
    mov dx, offset ERROR__END_3
PRINT_ERR_END:
    call 	WRITE_PROC
    ret

SUCCESS_END_:

    cmp al, 03
    jne GOOD_PRINT
    mov dx, offset ERROR__END_1
    call	WRITE_PROC
    ret

GOOD_PRINT:
    mov 	dx, offset  SUCCESS_END
    call	WRITE_PROC

		ret
LOAD_PROG ENDP

WRITE_PROC PROC NEAR
		push 	ax
		mov 	AH, 09h
		int 	21h
		pop 	ax
		ret
WRITE_PROC ENDP

MAIN PROC far
		mov 	ax,data
		mov 	ds,ax

    CALL DEL_EXTRA_MEMORY
		call 	LOAD_PROG

		mov 	ax, 4C00h
		int 	21h

END_LINE:
MAIN ENDP
CODE ENDS

STACK_ SEGMENT STACK
	dw 100 dup (?)
STACK_ ENDS
END MAIN
