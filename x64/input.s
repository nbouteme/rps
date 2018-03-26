%include "termios.inc"
%include "utils.inc"
%include "syscalls.inc"

segment .bss
oldterm: resb termios.size

segment .text

global set_raw_tty
align 16
set_raw_tty:
	mov rax, IOCTL
	mov rdi, 0
	mov rsi, TCGETS
	mov rdx, oldterm
	syscall

	sub rsp, termios.size
	mov rdi, rsp
	mov rsi, oldterm
	mov rdx, termios.size
	call memcpy

	and dword [rsp + termios.lflag], ~(ECHO | ICANON)
	mov rax, IOCTL
	mov rdi, 0
	mov rsi, TCSETSF
	mov rdx, rsp
	syscall
	add rsp, termios.size
	ret

global unset_raw_tty
align 16
unset_raw_tty:
	mov rax, IOCTL
	mov rdi, 0
	mov rsi, TCSETSF
	mov rdx, oldterm
	syscall
	ret

dia: db "💎"
diasz equ $ - dia
pap: db "📜"
papsz equ $ - pap
sci: db 0xe2, 0x9c, 0x82, 0xef, 0xb8, 0x8f
scisz equ $ - sci

choices: dq dia, pap, sci
csizes: db diasz, papsz, scisz

space: db "  "
eraseline: db 0x1b, "[2K", 13
hidecursor: db 0x1b, "[?25l"
reverse: db 0x1b, "[7m"
normal: db 0x1b, "[0m"
showcursor: db 0x1b, "[?25h"

global print_choices
print_choices:
	mov r9b, dil
	mov rax, WRITE
	mov rdi, 1
	mov rsi, eraseline
	mov rdx, 5
	syscall
	mov r8b, 0
	mov r10, 0
.loop:
	cmp r8b, 3
	jge .end_loop
	cmp r8b, r9b
	jne .dontrev
	mov rax, WRITE
	mov rsi, reverse
	mov rdx, 4
	syscall
.dontrev:
	mov r10b, r8b
	mov r11, csizes
	mov dl, [r11 + r10]
	shl r10b, 3
	mov rax, WRITE
	mov r11, choices
	mov rsi, [r11 + r10]
	syscall
	mov rax, WRITE
	mov rsi, space
	mov rdx, 1
	syscall

	cmp r8b, r9b
	jne .dontnorm
	mov rax, WRITE
	mov rdx, 4
	mov rsi, normal
	syscall
.dontnorm:
	add r8b, 1
	jmp .loop
.end_loop:
	mov rax, WRITE
	mov rsi, hidecursor
	mov rdx, 6
	syscall
	ret

global choose
choose:
	call set_raw_tty
	sub rsp, 2
	mov byte [rsp], 0			; k
	mov byte [rsp + 1], 1		; idx
.prompt:
	mov rdi, 0
	mov dil, byte [rsp + 1]
	call print_choices
	mov rax, READ
	mov rdi, 0
	mov rsi, rsp
	mov rdx, 1
	syscall
	cmp byte [rsp], 0x1b
	jne .end
	mov rax, READ
	syscall
	cmp byte [rsp], 0x5b
	jne .end
	mov rax, READ
	syscall
	cmp byte [rsp], 'D'
	jne .tryright
	sub byte [rsp + 1], 1
	jmp .clamp
.tryright:
	cmp byte [rsp], 'C'
	jne .clamp
	add byte [rsp + 1], 1
.clamp:
	cmp byte [rsp + 1], 3
	jne .testneg
	mov byte [rsp + 1], 0
	jmp .end
.testneg:
	cmp byte [rsp + 1], 0
	jge .end
	mov byte [rsp + 1], 2
.end:
	cmp byte [rsp], 0x20
	jne .prompt

	mov rax, WRITE
	mov rdi, 1
	mov rsi, showcursor
	mov rdx, 6
	syscall
	call unset_raw_tty
	mov rax, 0
	mov al, byte [rsp + 1]
	add rsp, 2
	ret
