
CODE      SEGMENT
      ASSUME DS:DATA, CS:CODE, SS:STACK_

; функция прерывания
ROUT PROC FAR

    jmp START_INTER
    INTER_STACK dw 64 dup(0)   ; стек прерывания

    KEEP_SP dw 0
    KEEP_SS dw 0
    KEEP_AX dw 0
    KEEP_CS dw 0
    KEEP_IP dw 0
    PSP dw 0
    CODE_ITER DW   1000h
    COUNT_INTER dw 0
    STR_OUTPUT db 'Counter:         $'

START_INTER:

    mov KEEP_SS, SS
    mov KEEP_SP, SP
    mov KEEP_AX, ax


    mov ax, SEG INTER_STACK
    mov SS, ax
    mov ax, offset INTER_STACK
	  add ax, 128

    mov ax, KEEP_AX
    push bx
    push BP
    push dx
    push di   ; сохранение изменяемых регистров
    push DS

    call GETCURS   ;  получение начальной позиции курсора
    push dx

    mov ax, CS
    mov DS, ax  ; инициализация сегмента данных
    mov ES, ax

    mov ax, COUNT_INTER  ;  увеличиваем счетчик
    inc ax
    mov COUNT_INTER, ax

    mov si, offset STR_OUTPUT + 13  ; запись номера вызова прерывания
    call WRD_TO_DEC
    mov di, si
    mov BP, offset STR_OUTPUT    ; помещаем в BP строку для вывода
    call outputBP

    pop dx  ; получение начальной позиции курсора

    call SETCURS  ; устанавливаем курсор в начальную позицию

    pop ds
    pop di
    pop dx
    pop bp
    POP bx

    MOV AL, 20H
    OUT 20H, AL   ; разрешение на обработку прерываний
                  ; с более низким приоритетом
    mov ax, KEEP_SS
    mov SS, ax
    mov SP, KEEP_SP
    mov AX, KEEP_AX
    IRET

ROUT ENDP

; Функция получения курсора
GETCURS PROC
    push ax
    push bx
    push cx
    mov ah, 03h
    mov bh, 0
    int 10h
    pop cx
    pop bx
    pop ax
    ret

GETCURS ENDP

; Функция установки курсора
SETCURS PROC

    push ax
    push bx
    push dx
    push cx

    mov ah, 02h
    mov bh, 0
    int 10h

    pop cx
    pop dx
    pop bx
    pop ax
    ret

SETCURS ENDP

; функция вывода строки по адресу ES:BP на экран
outputBP PROC

    push ax
    push bx
    push dx
    push cx

    mov ah, 13h
    mov al, 1
    mov bl, 02h  ; зеленый цвет текста
    mov bh, 0
    mov cx, 13  ; число экземпляров символов для записи
    mov dh, 10  ; строка
    mov dl, 50  ; колонка
    int 10h

    pop cx
    pop dx
    pop bx
    pop ax
    ret
outputBP ENDP

WRD_TO_DEC PROC

			push dx
			push bx
			push cx
			push ax
;
			mov bx,10h
			mul bx
			mov bx,0ah
      xor cx, cx
division:
			div bx ; деление числа на 10
			or dl, 30h
			mov [si], dl  ; запись полученной цифры в строку
			dec si
		  inc cx
			xor dx, dx
			cmp ax, 0h
			jnz division

			pop ax
			pop cx
			pop bx
			pop dx
			ret
WRD_TO_DEC ENDP
LAST_BYTE:  ;  метка конца памяти, необходимой для резидентного прерывания

;  установка прерывания
SET_ROUT PROC near
    push ax
    push bx
    push cx
    push dx
    push DS
    push ES

    mov ah, 35h
    mov al, 1CH
    int 21h
    mov KEEP_IP, bx    ; сохраняем оригинальный вектор прерывания
    mov KEEP_CS, es

    push ds
    mov dx, offset ROUT
    mov ax, SEG ROUT
    mov ds, ax
    mov ah, 25h
    mov al, 1CH
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
      mov al, 1CH
      int 21h      ; получение

      mov bx, offset ROUT
      mov si, offset CODE_ITER
      mov ax, es:[bx+si]
      cmp ax, 1000h   ; проверка, установлено ли уже прерывание или нет
      jne dontload    ; переход к установке прерывания

      mov dx, offset STR_LOADED ; сообщение, что прерывание уже установлено
      call WRITE_PROC

      cmp UN_FLAG, 1h
      jne end__

      call DELETE_ROUT    ; флаг UN_FLAG = true,
      jmp end__      ; вызываем выгрузку прерывания
dontload:
      mov dx, offset STR_NOT_LOADED ; сообщение, что прерывание не установлено
      call WRITE_PROC

      cmp UN_FLAG, 1h
      je end__

      call SET_ROUT
end__:
      pop si
      pop dx
      pop ax
      ret
IS_LOADED ENDP

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
    push DS
    push ES
    ; CLI
    mov ah, 35h
    mov al, 1Ch
    int 21h

    mov dx, ES:[KEEP_IP]      ; восстановление прерывания
    mov ax, ES:[KEEP_CS]

    push DS
    mov DS, AX
    mov AH, 25h
    mov AL, 1Ch      ;  Выгрузка прерывания
    int 21h
    pop DS

    mov ax, PSP
    mov ES, ax
    push ES

    mov ax, ES:[2Ch]
    mov ES, ax
    mov ah, 49h    ; прерывания для освобождения памяти под окружение программы
    int 21h

    mov dx, offset STR_UNLOAD ; сообщение, что прерывание не установлено
    call WRITE_PROC

    pop ES
    mov ah, 49h   ;  освобождение памяти, занимаемой программой
    int 21h
    ; STI
    pop ES
    pop DS
    pop dx
    pop bx
    pop ax

    mov al, 0
    mov ah,4ch
    int 21h
    ret
DELETE_ROUT ENDP

MAIN PROC NEAR
    mov PSP, es
    mov ax,DATA
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
   STR_UNLOAD db 'The interruption of unloaded.',0AH, 0DH,'$'
   STR_NOT_LOADED db 'Interapt was not loaded before.', 0AH, 0DH,'$'
   STR_FLAG db 'Flag input.', 0AH, 0DH,'$'
   STR_DONE db 'The interrupt is set.', 0AH, 0DH,'$'
   STR_LOADED db 'Interapt was loaded before', 0AH, 0DH,'$'

DATA      ENDS

END MAIN
