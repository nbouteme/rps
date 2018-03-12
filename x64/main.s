%include "event_loop.inc"
%include "host.inc"
%include "syscalls.inc"

segment .text
extern accept_tcp
extern udp_receive

segment .data
extern host_tcp_pdata
extern host_udp_pdata

tcp_server_str: db 'Host TCP Server', 0
udp_emitter_str: db 'Host UDP Emitter', 0

hts:
istruc host_tcp_server
at host_tcp_server.base, istruc source
							 at source.name,    dq tcp_server_str
							 at source.pfd,     dq 0,
							 at source.receive, dq accept_tcp
						 iend
at host_tcp_server.priv, dq host_tcp_pdata
iend

hue:
istruc host_udp_emitter
at host_udp_emitter.base, istruc source
							 at source.name,    dq udp_emitter_str
							 at source.pfd,     dq 0,
							 at source.receive, dq udp_receive
						  iend
at host_tcp_server.priv, dq host_udp_pdata
iend

segment .bss
el: resb event_loop.size

segment .text

global _start
_start:
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
