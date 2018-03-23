%include "event_loop_syms.inc"
%include "host_syms.inc"
%include "syscalls.inc"
%include "sig.inc"
%include "rps_syms.inc"
%include "client_syms.inc"

; Toute cette couche orientée objet est inutile
; puisque rien ne peut/doit être instancié plus d'une fois
; et pour éviter de manipuler la pile, tout est global
; donc accessible depuis n'importe où, donc certains membres
; de structures n'ont pas de raison d'éxister et certains
; paramètres n'ont pas de raison d'être passé
; haha

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
extern atoi

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
	mov rax, SIGPROCMASK
	mov rdi, SIG_BLOCK
	mov rsi, alarm_mask
	mov rdx, 0
	mov r10, 8
	syscall

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
	call init_game
	call init_tcp_server
	call init_udp_listener
	mov rdi, el
	mov rsi, rps
	call add_source
	mov rdi, el
	mov rsi, cts
	call add_source
	mov rdi, el
	mov rsi, cul
	call add_source
	jmp .end_prog
.server:
	cmp rbp, 3
	je .valid
	call usage_and_die
.valid:
	pop rdi						; argv[2]
	call atoi
	mov rdi, rax
	call init_host_tcp_server
	mov rdi, hue
	call init_host_udp_emitter
	mov rdi, el
	mov rsi, hts
	call add_source
	mov rdi, el
	mov rsi, hue
	call add_source
.end_prog:
	mov rdi, el
	call run_event_loop
	mov rax, EXIT
	mov rdi, 0
	syscall
	; /me dabs
