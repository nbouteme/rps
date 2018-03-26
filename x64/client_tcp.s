%include "client_priv.inc"
%include "host_private.inc"
%include "event_loop_syms.inc"
%include "syscalls.inc"
%include "rps_syms.inc"
%include "utils.inc"

extern el

segment .data
global cts
align 16
cts:
istruc client_tcp_server
at client_tcp_server.base, istruc source
						   at source.pfd, istruc pollfd
										  at pollfd.events, dw POLLIN
										  iend
						   at source.receive, dq accept_player
						   iend
at client_tcp_server.priv, dq cts
iend

segment .bss
global ctp
ctp: resb client_tcp_private.size

global listen_port
listen_port: resw 1

segment .text
global accept_player
global init_tcp_server

align 16
ctsfailstr: db 'Host connection: Something unexpected happened\n', 0
ctsfailsz equ $ - ctsfailstr

aplayer: db 'A player has connected', 10, 0
raising: db 'Raising alarm (tcp)', 10, 0

align 16
accept_player:
	mov rdi, aplayer
	call puts
	xor rax, rax
	mov ax, [cts + client_tcp_server.base + source.pfd + pollfd.revents]
	and ax, POLLHUP | POLLERR
	cmp ax, 0
	je .good
	mov rax, WRITE				; I get knocked down
	mov rdi, 2
	mov rsi, ctsfailstr
	mov rdx, ctsfailsz
	syscall
.die:							; but I get up again
	mov rax, EXIT
	mov rdi, 2
	syscall
.good:
	mov rax, ACCEPT
	mov edi, [cts + client_tcp_server.base + source.pfd + pollfd.fd]
	mov rsi, 0
	mov rdx, 0
	syscall
	mov rdi, rax
	call rps_add_player
	mov al, [rps + rps_game.ready]
	cmp al, 0
	je .end
.loop:
	mov al, [rps + rps_game.maxplayers]
	mov ah, [rps + rps_game.nplayers]
	add ah, 1
	cmp al, ah
	je .start_game
	mov rax, ACCEPT
	mov edi, [ctp + client_tcp_private.sock]
	mov rsi, 0
	mov rdi, 0
	syscall
	mov rsi, rax
	mov rdi, rps
	call rps_add_player
	jmp .loop
.start_game:
	mov rdi, raising
	call puts
	mov rax, GETPID
	syscall
	mov rdi, rax
	mov rax, KILL
	mov rsi, SIGALRM
	syscall
	mov rdi, el
	mov rsi, cts
	call remove_source
	mov rax, CLOSE
	mov edi, [ctp + client_tcp_private.sock]
	syscall
.end:
	ret

extern tcpaddr
align 16
init_tcp_server:
	mov rax, SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0
	mov word [tcpaddr + addr_inet4.port], dx
	syscall
	mov rdi, rax
	mov rax, BIND
	mov rsi, tcpaddr
	mov rdx, addr_inet4.size
	syscall
	mov rax, LISTEN
	mov rsi, 8
	syscall
	sub rsp, addr_inet4.size + 2
	mov rax, GETSOCKNAME
	lea rsi, [rsp + 2]
	mov word [rsp], addr_inet4.size
	lea rdx, [rsp]
	syscall
	mov ax, word [rsp + 2 + addr_inet4.port]
	xchg al, ah
	mov word [listen_port], ax
	add rsp, addr_inet4.size + 2

	mov dword [ctp + client_tcp_private.sock], edi
	mov dword [cts + client_tcp_server.base + source.pfd + pollfd.fd], edi
	ret
