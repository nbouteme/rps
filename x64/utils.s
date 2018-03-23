%include "syscalls.inc"

global memcpy
align 16
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
align 16
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

global atoi
align 16
atoi:
	mov rax, 0
	mov r11, 0
	mov rcx, 0
.loop:
	mov cl, byte [rdi + r11]
	cmp cl, '9'
	jg .end
	cmp cl, '0'
	jl .end
	imul rax, 10
	sub cl, '0'
	add rax, rcx
	add r11, 1
	jmp .loop
.end:
	ret

global revstr
align 16
revstr:
	mov rax, 0
.loop1:
	mov cl, [rdi + rax]
	cmp cl, 0
	je .gotsz
	add rax, 1
	jmp .loop1
.gotsz:
	mov rsi, 0
	sub rax, 1
.loop2:
	cmp rsi, rax
	jge .end
	mov cl, [rdi + rsi]
	mov ch, [rdi + rax]
	xchg cl, ch
	mov [rdi + rsi], cl
	mov [rdi + rax], ch
	add rsi, 1
	sub rax, 1
.end:
	mov rax, rdi
	ret

global utoa
align 16
utoa:
	mov rcx, 0
	mov r11, rdi
.loop:
	mov rdi, r11
	mov rax, r11
	mov r8, 10
	mov rdx, 0
	idiv r8
	add rdx, '0'
	mov byte [rsi + rcx], dl
	mov r11, rax
	add rcx, 1
	cmp r11, 0
	jne .loop
	mov byte [rsi + rcx], 0
	mov rdi, rsi
	call revstr
	ret

global putunbr
align 16
putunbr:
	lea rsi, [rsp - 16]
	sub rsp, 16
	call utoa
	add rsp, 16
	mov rsi, rax
	mov rdx, 0
	mov rcx, 0
.loop:
	mov cl, [rsi + rdx]
	cmp cl, 0
	je .endsz
	add rdx, 1
	jmp .loop
.endsz:
	mov rax, 1
	mov rdi, 1
	syscall
	ret
