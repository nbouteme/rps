%include "client_priv.inc"
%include "host_private.inc"
%include "event_loop_syms.inc"
%include "syscalls.inc"
%include "rps_syms.inc"

section .data
extern one
extern four
extern sizeofin4
extern el
extern ctp
extern cts

align 16
udpaddr:
istruc addr_inet4
at addr_inet4.family, dw AF_INET
at addr_inet4.port, dw UDP_PORT
at addr_inet4.addr, dd 0
iend

section .bss

cup: resb client_udp_private.size

section .data

global chc
align 16
chc:
istruc client_host_connection
at client_host_connection.base, istruc source
								at source.pfd, istruc pollfd
											   at pollfd.events, dw POLLIN
											   iend
								at source.receive, dq host_incoming_data
								iend
at client_host_connection.rps, dw 0
at client_host_connection.parent, dq cts
at client_host_connection.host, dw -1
iend

global cul						; involontaire
align 16
cul:
istruc client_udp_listener
at client_udp_listener.base, istruc source
							 at source.pfd, istruc pollfd
											at pollfd.events, dw POLLIN
											iend
							 at source.receive, dq udp_receive_brd
							 iend
at client_udp_listener.priv, dq cup
iend
section .text

align 16
htcfailstr: db 'Host connection: Something unexpected happened\n', 0
htcfailsz equ $ - htcfailstr

align 16
global host_incoming_data
host_incoming_data:
	xor rax, rax
	mov ax, [chc + client_host_connection.base + source.pfd + pollfd.revents]
	and ax, POLLHUP | POLLERR
	cmp ax, 0
	je .good
	mov rax, WRITE				; I get knocked down
	mov rdi, 2
	mov rsi, htcfailstr
	mov rdx, htcfailsz
	syscall
.die:							; but I get up again
	mov rax, EXIT
	mov rdi, 2
	syscall
.good:
	mov rdi, 0
	mov edi, [chc + client_host_connection.base + source.pfd + pollfd.fd]
	lea rsi, [rsp + 3]
	mov rdx, 3
	mov rax, READ
	syscall
	mov ax, [rsi]
	cmp ax, 0x4F4B
	jne .die
	mov byte [rps + rps_game.ready], 1
	mov al, [rsi + 2]
	mov byte [rps + rps_game.maxplayers], al
	sub al, 1
	mov ah, [rps + rps_game.nplayers]
	cmp al, ah
	jne .remove_tcp_listener
	mov rax, GETPID
	syscall
	mov rdi, rax
	mov rax, KILL
	mov rsi, SIGALRM
	syscall
	mov rdi, el
	mov rsi, cts
.remove_tcp_listener:
	mov rsi, chc
	mov rdi, el
	call remove_source
	ret

align 16
udpfailstr: db 'UDP Listener: Something unexpected happened\n', 0
udpfailsz equ $ - udpfailstr

extern listen_port

global udp_receive_brd
align 16
udp_receive_brd:
	xor rax, rax
	mov ax, [cup + client_udp_listener.base + source.pfd + pollfd.revents]
	and ax, POLLHUP | POLLERR
	cmp ax, 0
	je .good
	mov rax, WRITE				; I get knocked down
	mov rdi, 2
	mov rsi, udpfailstr
	mov rdx, udpfailsz
	syscall
.die:							; but I get up again
	mov rax, EXIT
	mov rdi, 2
	syscall
.good:
	lea rax, [rsp - addr_inet4.size * 2 - 4]
	mov edi,  [cup + client_udp_listener.base + source.pfd + pollfd.fd]
	lea rsi, [rax]
	mov rdx, 4
	mov r10, 0
	lea r8, [rax + 4]
	mov r9, sizeofin4
	mov rax, RECVFROM
	syscall
	mov dword eax, [rsp - addr_inet4.size * 2 - 4]
	and eax, 0xFFFFFF00
	cmp eax, 0x44495300
	jne .die
	lea rax, [rsp - addr_inet4.size * 2]
	mov word [rax + addr_inet4.port], TCP_PORT
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0
	syscall
	mov rdi, rax
	lea rsi, [rsp - addr_inet4.size * 2]
	mov rdx, sizeofin4
	mov rax, CONNECT
	syscall
	mov rax, WRITE
	mov rsi, listen_port
	mov rdx, 2
	syscall
	mov ax, [rsi + addr_inet4.port]
	xchg al, ah
	mov word [rsi + addr_inet4.port], ax
	mov rax, WRITE
	add rsi, addr_inet4.port
	mov rdx, 2
	syscall
	mov rax, READ
	syscall
	mov al, [rsi + addr_inet4.port]
	cmp al, 'C'
	jne .die
	mov rax, 0
	mov al, [rsi + addr_inet4.port + 1]
	mov r10, 0
.recvtpl:
	cmp r10, rax
	je .endrecv

	sub rsp, addr_inet4.size + 6
	mov rax, READ
	mov rsi, rsp
	mov rdx, 6
	syscall
	mov rax, SOCKET
	push rdi					;/me spills
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0
	syscall
	mov rdi, rax
	mov dword eax, [rsp]
	mov dword [rsp - 6 + addr_inet4.addr], eax
	mov word ax, [rsp - 4]
	xchg ah, al
	mov word [rsp - 6 + addr_inet4.port], ax
	lea rsi, [rsp - 6]
	mov rdx, sizeofin4
	mov rax, CONNECT
	syscall
	call rps_add_player
	pop rdi
	add rsp, addr_inet4.size + 6
	add r10, 1
	jmp .recvtpl
.endrecv:
	mov byte [ctp + client_tcp_private.en], 1
	mov dword [chc + client_host_connection.host], edi
	mov rdi, el
	mov rsi, chc
	call add_source
	mov rdi, el
	mov rsi, cul
	call remove_source
	ret

global init_udp_listener
align 16
init_udp_listener:
	mov rax, SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_DGRAM
	mov rdx, 0
	syscall
	mov rbp, rax
	mov rdi, rax
	mov rax, SETSOCKOPT
	mov rsi, SOL_SOCKET
	mov rdx, SO_BROADCAST
	mov r10, one
	mov r8, four
	syscall
	mov rax, SETSOCKOPT
	mov rdx, SO_REUSEADDR
	syscall
	mov rax, SETSOCKOPT
	mov rdx, SO_REUSEPORT
	syscall
	mov rsi, udpaddr
	mov rdx, addr_inet4.size
	mov rax, BIND
	syscall
	mov qword [cup + client_udp_private.el], el
	mov qword [cup + client_udp_private.serv], cts
	ret
