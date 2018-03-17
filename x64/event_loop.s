%include "event_loop.inc"
%include "host.inc"
%include "syscalls.inc"

extern memcpy

global init_event_loop
align 16
init_event_loop:
	ret

global add_source
align 16
add_source:
	mov rax, rdi
	add rax, event_loop.sources
	mov r8, [rdi + event_loop.nsources]
	sal r8, 3
	add rax, r8
	mov [rax], rsi
	add rax, event_loop.fds
	add rsi, source.pfd
	mov rsi, [rsi]
	mov [rax], rsi
	mov rax, [rdi + event_loop.nsources]
	add rax, 1
	mov [rdi + event_loop.nsources], rax
	ret

global remove_source
align 16
remove_source:
	mov r12, 0
.loop:
	cmp r12, [rdi + event_loop.nsources]
	je .end

	shl r12, 3
	cmp [rdi + event_loop.sources + r12], rsi
	jne .fail

	mov r8, rdi
	add rdi, event_loop.sources
	add rdi, r12

	mov rsi, rdi
	add rsi, 8

	mov edx, dword [rdi + event_loop.nsources]
	shl rdx, 3
	sub rdx, r12
	sub rdx, 8

	call memcpy

	add rdi, event_loop.fds
	add rsi, event_loop.fds

	call memcpy

	mov r9, [r8 + event_loop.current]
	mov rax, r9
	sub rax, 1
	cmp r12, r9
	cmovl r9, rax
	mov [r8 + event_loop.current], r9d
	sub rdi, event_loop.fds
	sub rsi, event_loop.fds
	sub rdi, r12
	sub rsi, r12
	dec dword [rdi + event_loop.nsources]
	ret
.fail:
	shr r12, 3
	add r12, 1
	jmp .loop
.end:
	ret

global run_event_loop
align 16
run_event_loop:
	mov dword [rdi + event_loop.running], 1
.loop:
	cmp dword [rdi + event_loop.nsources], 0
	je .end

	mov rax, POLL
	mov rsi, [rdi + event_loop.nsources]
	add rdi, event_loop.fds
	mov rdx, -1
	syscall
.syscallend:
	sub rdi, event_loop.fds

	mov rcx, rdi
	add rcx, event_loop.current
	mov dword [rcx], 0

.source_iter_loop:
	cmp rax, 0
	je .esil

.next_source:
	mov r8, rdi
	mov r8d, [r8 + event_loop.nsources]
	cmp dword [ecx], r8d
	jge .esil

	mov r8d, [rcx]
	shl r8d, 3
	add r8, rdi
	add r8, event_loop.fds
	cmp word [r8 + pollfd.revents], 0
	je .not_found

.found:
	mov r9, [rcx]
	shl r9d, 3
	mov r9, [rdi + event_loop.sources + r9]
	mov r8, [r8]
	mov qword [r9 + source.pfd], r8

	push rdi
	push rcx
	push rax

	mov rdi, r9
	mov r8, [rdi + source.receive]
.madecall:
	call r8

	pop rax
	pop rcx
	pop rdi

	sub rax, 1
.not_found:
	add qword [rcx], 1
	jmp .next_source
.esil:
	jmp .loop
.end:
	mov dword [rdi + event_loop.running], 0
	ret
