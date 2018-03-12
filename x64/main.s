%include "event_loop.inc"
%include "host.inc"
%include "syscalls.inc"

segment .bss
el: resb event_loop.size
hts: resb host_tcp_server.size
hue: resb host_udp_emitter.size

segment .text

global _start
_start:
	mov rdi, el
	call init_event_loop
	mov rdi, hts
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
