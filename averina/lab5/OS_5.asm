
CODE      SEGMENT
      ASSUME DS:DATA, CS:CODE, SS:STACK_

; функция прерывания
ROUT PROC FAR

jmp START_INTER

    CODE_ITER DW   1323h
    KEEP_SP dw 0
    KEEP_SS dw 0
    KEEP_AX dw 0
    KEEP_IP DW 0
    KEEP_CS DW 0
    PSP dw 0
    SYMBOL db 0
    REQ_KEY_A db 1Eh
    REQ_KEY_S db 1Fh
    REQ_KEY_D db 20h
    INTER_STACK dw 64 dup(0)   ; стек прерывания

START_INTER:

    mov KEEP_SS, SS
    mov KEEP_SP, SP
    mov KEEP_AX, ax

    mov ax, SEG INTER_STACK
    mov SS, ax
    mov ax, offset INTER_STACK
	  add ax, 128
    push bx
    push BP
    push dx
    push di   ; сохранение изменяемых регистров
    push DS
    push si

    push ax
    mov ah, 2
    int 16h                 ; проверка нажат ли shift
    test al, 00000011b
    jnz do

std_inter:
    pop ax
    pushf
    call dword ptr CS:KEEP_IP
    jmp _end_

do:
    in al, 60h    ; получениескан-кода
A_O:
    cmp al, REQ_KEY_A
    jne S_M
    mov SYMBOL, 'O'
    jmp next

S_M:
    cmp al, REQ_KEY_S
    jne D_N
    mov SYMBOL, 'M'
    jmp next
D_N:
    cmp al, REQ_KEY_D
    jne std_inter
    mov SYMBOL, 'N'

next:
    pop ax
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg ah, al
    out 61h, al
    mov al, 20H
    out 20h, al

    ; печать
    mov ah, 05h
    mov cl, SYMBOL
    mov ch, 00h
    int 16h
    or al, al       ;  0, если запись была успешной
    ; jnz skip

_end_:
    pop si
    pop ds
    pop di
    pop dx
    pop bp
    POP bx

    mov al, 20h
    OUT 20h, al

    mov ax, KEEP_SS
    mov SS, ax
    mov SP, KEEP_SP
    mov AX, KEEP_AX

  	IRET
    RET
ROUT ENDP
LAST_BYTE:  ;  метка конца памяти, необходимой для резидентного прерывания

;  установка прерывания
SET_ROUT PROC near
    push ax
    push bx
    push cx
    push dx
    push DS
    push ES

    mov AH, 35h
		mov AL, 09h
		int 21h
    mov KEEP_IP, bx    ; сохраняем оригинальный вектор прерывания
		mov KEEP_CS, es

    push ds
    mov dx, offset ROUT
    mov ax, SEG ROUT
    mov ds, ax
    mov ah, 25h
    mov al, 09H
    int 21H
    pop ds

    push dx
    mov dx, offset STR_DONE
    call WRITE_PROC
    pop dx

    mov dx, offset LAST_BYTE
    mov cl, 4
    shr dx, cl
    inc dx
    add dx, CODE   ; Вычисление размера нужной памяти для обработчика
    sub dx, PSP
    xor al, al
    mov ah, 31H   ; освобождение неиспользуемой памяти
    int 21h

    pop ES
		pop DS
		pop dx
		pop cx
		pop bx
		pop ax

    mov al, 0
    mov ah,4ch
    int 21h
    ret
SET_ROUT ENDP

WRITE_PROC PROC near
    push ax
   	mov AH,09h
   	int 21h
   	pop ax
   	ret
WRITE_PROC ENDP

; функция проверки установленного прерывания
IS_LOADED PROC near
      push ax
      push dx
      push si

      mov ah, 35h
      mov al, 09H
      int 21h      ; получение

      ; mov bx, offset ROUT
      mov si, offset CODE_ITER
      sub si, offset ROUT
      mov ax, es:[bx+si]
      cmp ax, 1323h   ; проверка, установлено ли уже прерывание или нет
      jne dontload    ; переход к установке прерывания

      mov dx, offset STR_LOADED ; сообщение, что прерывание уже установлено
      call WRITE_PROC

      cmp UN_FLAG, 1h
      jne end__

      call DELETE_ROUT    ; флаг UN_FLAG = true,
      jmp end__      ; вызываем выгрузку прерывания
dontload:
      push dx
      mov dx, offset STR_NOT_LOADED ; сообщение, что прерывание не установлено
      call WRITE_PROC
      pop dx

      cmp UN_FLAG, 1h
      je end__

      call SET_ROUT
end__:
      pop si
      pop dx
      pop ax
      ret
IS_LOADED ENDP
;
; Функция для проверки флага /un
UN_FLAG_DETECT PROC near
    push ax
    push dx
    xor ax, ax

    mov al, es:[82h] ; проверка хвоста командной строки
    cmp al, '/'
    jne end_

    mov al, es:[83h]
    cmp al, 'u'
    jne end_

    mov al, es:[84h]
    cmp al, 'n'
    jne end_

    mov al, es:[85h]  ; проверка, что флаг содержит только /un
    cmp al, 0h
    je end_

    mov UN_FLAG, 1h  ; ставим флаг, что введено /un
    mov dx, offset STR_FLAG
    call WRITE_PROC
end_:
    pop dx
    pop ax
    ret
UN_FLAG_DETECT ENDP

; Функция выгрузки обработчика
DELETE_ROUT PROC
    push ax
    push bx
    push dx
    push si
    push DS
    push ES

    mov ah, 35h
    mov al, 09h
    int 21h

    push dx
    mov dx, offset STR_UNLOAD ; сообщение, что прерывание не установлено
    call WRITE_PROC
    pop dx

    mov si, offset KEEP_IP
		sub si, offset ROUT
		mov dx, ES:[bx+si]
		mov ax, ES:[bx+si+2]					 ; восстановление прерывания
		mov DS, ax

		mov ah, 25H
		mov al, 09h
		int 21H										;  Выгрузка прерывания
		mov ax, ES:[bx+si+4]
		mov ES, AX

		push ES
		mov ax, ES:[2Ch]
		mov ES, ax				; прерывания для освобождения памяти под окружение программы
		mov ah, 49h
		int 21h
		pop ES

		mov ah, 49h
		int 21h

    pop ES
    pop DS
    pop si
    pop dx
    pop bx
    pop ax

    ; mov al, 0
    ; mov ah,4ch
    ; int 21h
    ret

DELETE_ROUT ENDP

MAIN PROC

    mov PSP, es
    mov ax, DATA
	  mov ds,ax

    call UN_FLAG_DETECT
    call IS_LOADED

    mov al, 0
    mov ah,4ch
    int 21h
MAIN ENDP

CODE      ENDS

STACK_    SEGMENT  STACK
   DW 128 DUP(?)
STACK_    ENDS

DATA      SEGMENT
   UN_FLAG dw 0
   STR_UNLOAD db 'The interruption unloaded.',0AH, 0DH,'$'
   STR_NOT_LOADED db 'Interapt was not loaded before.', 0AH, 0DH,'$'
   STR_FLAG db 'Flag input.', 0AH, 0DH,'$'
   STR_DONE db 'The interrupt is set.', 0AH, 0DH,'$'
   STR_LOADED db 'Interapt loaded before', 0AH, 0DH,'$'

DATA      ENDS

END MAIN
