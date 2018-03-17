segment .data

%include "event_loop_syms.inc"
%include "host_private.inc"
%include "syscalls.inc"
%include "sig.inc"

extern el

global host_tcp_pdata
align 16
host_tcp_pdata:
istruc host_tcp_private
at host_tcp_private.el,        dq el
at host_tcp_private.sock,      dd -1
at host_tcp_private.allocated, db 0
at host_tcp_private.left, db 3
iend

global host_udp_pdata
align 16
host_udp_pdata:
istruc host_udp_private
at host_udp_private.el,   dq el
at host_udp_private.serv, dq host_tcp_pdata
at host_udp_private.sock, dd -1
iend

align 16
tcp_server_str: db 'Host TCP Server', 0

global hts
align 16
hts:
istruc host_tcp_server
at host_tcp_server.base, istruc source
						 at source.name, dq tcp_server_str
						 at source.pfd, istruc pollfd
										at pollfd.events, dw POLLIN
										iend
						 at source.receive, dq accept_tcp
						 iend
at host_tcp_server.priv, dq host_tcp_pdata
iend

udp_emitter_str: db 'Host UDP Emitter', 0

global hue
align 16
hue:
istruc host_udp_emitter
at host_udp_emitter.base, istruc source
						  at source.name, dq udp_emitter_str
						  at source.pfd, istruc pollfd
										 at pollfd.events, dw POLLIN
										 iend
						  at source.receive, dq udp_receive
						  iend
at host_tcp_server.priv, dq host_udp_pdata
iend

align 16
one: dw 1
four: dw $-one

align 16
sizeofin4: dd addr_inet4.size

align 16
udpaddr:
istruc addr_inet4
at addr_inet4.family, dw AF_INET
at addr_inet4.port, dw UDP_PORT
at addr_inet4.addr, dd -1
iend

align 16
tcpaddr:
istruc addr_inet4
at addr_inet4.family, dw AF_INET
at addr_inet4.port, dw TCP_PORT
at addr_inet4.addr, dd 0
iend

align 16
mesdata: db 'DIS', 0

segment .bss
buf: resb 6

segment .text

global init_host_udp_emitter
align 16
init_host_udp_emitter:
	mov rax, SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_DGRAM
	mov rdx, 0
	syscall
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
	mov [host_udp_pdata + host_udp_private.sock], rdi
	mov rax, SIGNALFD
	mov rsi, alarm_mask
	mov rdi, -1
	mov rdx, 8
	syscall
	mov dword [hue + host_udp_emitter.base + source.pfd + pollfd.fd], eax
	mov rax, ALARM
	mov rdi, 1
	syscall
	ret

align 16
udpfailstr: db 'UDP Emitter: Something unexpected happened\n', 0
udpfailsz equ $ - udpfailstr
align 16
tcpfailstr: db 'UDP Emitter: Something unexpected happened\n', 0
tcpfailsz equ $ - tcpfailstr

global udp_receive
align 16
udp_receive:
	xor rax, rax
	mov ax, [hue + host_udp_emitter.base + source.pfd + pollfd.revents]
	and rax, POLLHUP | POLLERR
	cmp rax, 0
	je .good
	mov rax, WRITE
	mov rdi, 2
	mov rsi, udpfailstr
	mov rdx, udpfailsz
	syscall
	mov rax, EXIT
	syscall
.good:
	; dummy read
	sub rsp, 128
	mov rax, READ
	xor rdi, rdi
	mov edi, [hue + host_udp_emitter.base + source.pfd + pollfd.fd]
	mov rsi, rsp
	mov rdx, 128
	syscall
	add rsp, 128
	; check end
	mov rax, host_tcp_pdata
	mov bpl, byte [rax + host_tcp_private.left]
	cmp bpl, 0
	je .end
	mov rsi, mesdata
	mov al, [rax + host_tcp_private.left]
	mov [rsi + 3], al
	mov rax, SENDTO
	mov rdi, 0
	mov edi, [host_udp_pdata + host_udp_private.sock]
	mov rdx, 4
	mov r10, 0
	mov r8, udpaddr
	mov r9, addr_inet4.size
	syscall
	mov rax, ALARM
	mov rdi, 1
	syscall
	ret
.end:
	mov rax, CLOSE
	mov edi, [host_udp_pdata + host_udp_private.sock]
	syscall
	mov rdi, el
	mov rsi, hue
	call remove_source
	ret


global init_host_tcp_server
align 16
init_host_tcp_server:
	mov r9, rdi
	mov rax, SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0
	syscall
	mov rdi, rax
	mov rbp, rax
	mov rax, SETSOCKOPT
	mov rsi, SOL_SOCKET
	mov rdx, SO_REUSEADDR
	mov r10, one
	mov r8, four
	syscall
	mov rax, SETSOCKOPT
	mov rdx, SO_REUSEPORT
	syscall
	mov rax, BIND
	mov rbp, rdi
	mov rsi, tcpaddr
	mov rdx, addr_inet4.size
	syscall
	mov rax, LISTEN
	mov rdi, rbp
	mov rsi, 8
	syscall
	mov dword [host_tcp_pdata + host_tcp_private.sock], edi
	mov dword [hts + host_tcp_server.base + source.pfd + pollfd.fd], edi
	mov byte [host_tcp_pdata + host_tcp_private.left], r9b
	ret

global accept_tcp
align 16
accept_tcp:
	xor rax, rax
	mov ax, [hts + host_tcp_server.base + source.pfd + pollfd.revents]
	and rax, POLLHUP | POLLERR
	cmp rax, 0
	je .good
	mov rax, WRITE
	mov rdi, 2
	mov rsi, tcpfailstr
	mov rdx, tcpfailsz
	syscall
	mov rax, EXIT
	syscall
.good:
	xor rdi, rdi
	mov edi, [hts + host_tcp_server.base + source.pfd + pollfd.fd]
	mov rax, ACCEPT
	mov rsi, rsp
	sub rsi, addr_inet4.size + 2
	mov rdx, sizeofin4
	syscall
	mov rbp, rax
	mov rdi, rax
	mov rax, READ
	add rsi, addr_inet4.size
	mov rdx, 2
	syscall
	mov rsi, buf
	mov byte [rsi], 'C'
	mov r9b, [host_tcp_pdata + host_tcp_private.allocated]
	mov byte [rsi + 1], r9b
	mov rax, WRITE
	mov rdx, 2
	syscall
	mov rdx, 6
	mov r8, 0
.loop:
	cmp r8b, r9b
	je .end_loop
	mov r10, r8
	imul r10, tcp_client.size
	add r10, host_tcp_pdata + host_tcp_private.places
	mov ecx, dword [r10 + tcp_client.addr]
	mov dword [rsi], ecx
	mov cx, word [r10 + tcp_client.lport]
	mov word [rsi + 4], cx
	mov rax, WRITE
	syscall
	add r8, 1
	jmp .loop
.end_loop:
	mov r10, r8
	imul r10, tcp_client.size
	add r10, host_tcp_pdata + host_tcp_private.places
	mov dword [r10 + tcp_client.sock], ebp
	mov ecx, [rsp - addr_inet4.size - 2 + addr_inet4.addr]
	mov dword [r10 + tcp_client.addr], ecx
	mov cx, [rsp - 2]
	mov word [r10 + tcp_client.lport], cx
	add r9, 1
	mov byte [host_tcp_pdata + host_tcp_private.allocated], r9b
	mov r8b, byte [host_tcp_pdata + host_tcp_private.left]
	sub r8, 1
	mov byte [host_tcp_pdata + host_tcp_private.left], r8b
	cmp r8, 0
	je .finish
	ret
.finish:
	mov rdi, 0
	mov dil, byte [host_tcp_pdata + host_tcp_private.allocated]
	shl rdi, 16
	mov di, 'OK'
	mov dword [buf], edi
	mov rax, 0
	mov rbp, 0
	shr rdi, 16
	mov bpl, dil
	mov rsi, buf
	mov rdx, 3
.signal_end:
	cmp al, bpl
	je .free_res

	mov r8, rax
	imul r8, tcp_client.size
	lea rdi, [host_tcp_pdata + host_tcp_private.places + r8]
	mov edi, [edi + tcp_client.sock]

	push rax
	mov rax, WRITE
	syscall
	mov rax, CLOSE
	syscall
	pop rax
	add ax, 1
	jmp .signal_end
.free_res:
	xor rdi, rdi
	mov rax, SHUTDOWN
	mov edi, [host_tcp_pdata + host_tcp_private.sock]
	mov rsi, 2
	syscall
	mov rax, CLOSE
	syscall
	mov rdi, el
	mov rsi, hts
	call remove_source
	ret
