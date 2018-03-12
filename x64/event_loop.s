%define NOEXPORT
%include "event_loop.inc"
%undef NOEXPORT

%include "host.inc"
%include "syscalls.inc"

extern memcpy

global init_event_loop
init_event_loop:
	ret

global add_source
add_source:
	mov [rdi + event_loop.sources + event_loop.nsources], rsi
	mov [rdi + event_loop.fds + event_loop.nsources], rsi
	mov rax, [rdi + event_loop.nsources]
	add rax, 1
	mov [rdi + event_loop.nsources], rax
	ret

global remove_source
remove_source:
	mov r12, 0
.loop:
	cmp r12, [rdi + event_loop.nsources]
	je .end

	cmp [rdi + event_loop.sources + r12], rsi
	jne .fail

	; plus besoin de rsi à partir de là

	mov r8, rdi
	mov rdi, rsi

	add rsi, 8

	mov edx, dword [rdi + event_loop.nsources]
	mov rdx, r12
	sub rdx, 1
	sal rdx, 3

	call memcpy

	mov rdi, event_loop.fds
	add rdi, r12
	sal rdi, 3

	mov rsi, rdi
	sal rsi, 3

	add rsi, r8
	add rdi, r8

	mov edx, dword [rdi + event_loop.nsources]
	sub rdx, r12
	sub rdx, 1
	sal rdx, 3

	call memcpy

	mov r9, [r8 + event_loop.current]
	mov rax, r9
	sub rax, 1
	cmp r12, r9
	cmovl r9, rax
	mov [r8 + event_loop.current], r9d

	dec dword [rdi + event_loop.nsources]
	ret
.fail:
	add rcx, 1
	jmp .loop
.end:
	ret

global run_event_loop
run_event_loop:
	mov dword [rdi + event_loop.running], 1
.loop:
	cmp dword [rdi + event_loop.nsources], 0
	je .end

	push rdi

	mov rax, POLL
	add rdi, event_loop.fds
	mov rsi, [rdi + event_loop.nsources]
	mov rdx, -1
	syscall

	pop rdi

	mov rcx, rdi
	add rcx, event_loop.current
	mov dword [rcx], 0

.source_iter_loop:
	cmp rax, 0
	je .esil
	mov r8, rdi
	mov r8, [r8 + event_loop.nsources]
	cmp qword [rcx], r8
	jge .esil

	mov r8, [rdi + event_loop.fds]
	add r8, [rcx]
	cmp word [r8 + pollfd.revents], 0
	je .not_found

	mov r9, [rdi + event_loop.sources]
	add r9, [rcx]
	mov r8, [r8]
	mov qword [r9 + source.pfd], r8

	push rdi
	push rcx
	push rax

	mov rdi, [r9]
	mov r8, [rdi + source.receive]
	call r8

	pop rax
	pop rcx
	pop rdi

	sub rax, 1
.not_found:
	add qword [rcx], 1
.esil:
.end:
	mov dword [rdi + event_loop.running], 0
	ret
