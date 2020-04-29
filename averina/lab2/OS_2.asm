TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
	
; Данные
MEM_ADRESS db 'Inaccessible memory address:     h',13,10,'$'
ENV_ADRESS db 'Environment address:     h',13,10,'$'
TAIL db 'Command line tail:        ',13,10,'$'
NULL_TAIL db 'In Command tail no sybmols',13,10,'$'
CONTENT db 'Content:',13,10, '$'
END_STRING db 13, 10, '$'


;Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
	NEXT: 
		add AL,30h
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
		mov AH,09h
		int 21h
		ret
WRITE_PROC ENDP

PROC_MEMORY PROC near   ; вывод сегментного адреса недоступной памяти 
	  
	   mov ax,ds:[02h]
	   
	   mov di, offset MEM_ADRESS
	   add di, 32
	   
	   call WRD_TO_HEX
	   mov 	dx, offset MEM_ADRESS
	   call WRITE_PROC
	   ret
PROC_MEMORY ENDP
	
	
PROC_ENVIROMENT  PROC near   ; вывод сегментного адреса среды, передаваемой программе 
		mov ax,ds:[2Ch]
		
		mov di, offset ENV_ADRESS
		add di, 24
		
		call WRD_TO_HEX
		mov dx, offset ENV_ADRESS
		call WRITE_PROC
		ret
PROC_ENVIROMENT ENDP


PROC_TAIL PROC near   
  
	   xor cx, cx
		mov cl, ds:[80h]
		mov si, offset TAIL
		add si, 19
	   cmp cl, 0h
	   je EMPTY_TAIL   ; считываем число символов в хвосте ком. строки,
		xor di, di		; если не пустой, выводим
		xor ax, ax
	
	READ_TAIL:        
		mov al, ds:[81h+di]
		inc di
		mov [si], al
		inc si
		loop READ_TAIL
		mov dx, offset TAIL
		jmp END_TAIL
	
	EMPTY_TAIL:
		mov dx, offset NULL_TAIL
		
	END_TAIL: 
		call WRITE_PROC 
		ret
PROC_TAIL ENDP


PROC_CONTENT PROC near

	   mov dx, offset CONTENT
	   call WRITE_PROC
	   
	   xor di,di
	   mov ds, ds:[2Ch]       ;; вывод сегментного  
	   
	READ_STRING:
		cmp byte ptr [di], 00h
		jz END_STR
		
		mov dl, [di]
		mov ah, 02h
		int 21h
		jmp DETECT_END
		
	END_STR:
	    cmp byte ptr [di+1],00h
	    jz DETECT_END
	    push ds
	    mov cx, cs
		mov ds, cx
		mov dx, offset END_STRING
		call WRITE_PROC
		pop ds
		
	DETECT_END:
		inc di
		cmp word ptr [di], 0001h
		jz READ_PATH
		
		jmp READ_STRING
		
	READ_PATH:
		add di, 2
			
	LOOP_PATH:
		cmp byte ptr [di], 00h
		jz  DONE
		mov dl, [di]
		mov ah, 02h
		int 21h
		inc di
		jmp LOOP_PATH
		
	DONE:
		ret
PROC_CONTENT ENDP

BEGIN:

call PROC_MEMORY
call PROC_ENVIROMENT
call PROC_TAIL
call PROC_CONTENT

xor AL,AL
mov AH,4Ch
int 21H
TESTPC ENDS
END START ;
