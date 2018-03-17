global memcpy
memcpy:
	mov rax, 0
.loop:
	cmp rax, rdx
	je .end
	mov r10, [rsi + rax]
	mov [rdi + rax], r10
	add rax, 1
	jmp .loop
.end:
	ret

global strcmp
strcmp:
	mov rax, 0
	mov r10, 0
	mov r11, 0
.loop:
	mov r10b, [rsi + rax]
	mov r11b, [rdi + rax]
	cmp r10b, 0
	je .end
	cmp r11b, 0
	je .end
	cmp r10b, r11b
	jne .end
	add rax, 1
	jmp .loop
.end:
	mov rax, r10
	sub rax, r11
	ret
