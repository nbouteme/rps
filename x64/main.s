%include "event_loop_syms.inc"
%include "host_syms.inc"
%include "syscalls.inc"
%include "sig.inc"

segment .data
extern hue
extern hts

segment .bss
global el
align 16
el: resb event_loop.size

segment .text

extern init_host_tcp_server
extern init_host_udp_emitter
extern strcmp

align 16
createstr: db 'create', 0
joinstr: db 'join', 0

align 16
ustr: db 'Usage: ./rpsm create [2-9] | join', 10
ustrsz equ $-ustr
align 16
usage_and_die:
	mov rax, WRITE
	mov rdi, 2
	mov rsi, ustr
	mov rdx, ustrsz
	syscall
	mov rax, EXIT
	syscall

global _start
align 16
_start:
	pop rbp						; argc
	cmp rbp, 1
	jne .cont
	call usage_and_die
.cont:
	pop rax						; argv[0]
	pop rax						; argv[1]

	mov rdi, rax
	mov rsi, createstr
	call strcmp
	cmp rax, 0
	je .server

	mov rsi, joinstr
	call strcmp
	cmp rax, 0
	je .client
.client:
	call usage_and_die

.server:
	cmp rbp, 3
	je .valid
	call usage_and_die
.valid:
	mov rax, SIGPROCMASK
	mov rdi, SIG_BLOCK
	mov rsi, alarm_mask
	mov rdx, 0
	mov r10, 8
	syscall

	pop rdi
	mov dil, [rdi]
	sub dil, 0x30
.cmp:
	cmp dil, 9
	jg usage_and_die
	cmp dil, 2
	jl usage_and_die

	call init_host_tcp_server
	mov rdi, hue
	call init_host_udp_emitter
	mov rdi, el
	mov rsi, hts
	call add_source
	mov rdi, el
	mov rsi, hue
	call add_source
	mov rdi, el
	call run_event_loop
	mov rax, EXIT
	mov rdi, 0
	syscall
