%include "rps.inc"
%include "syscalls.inc"
%include "event_loop_syms.inc"
%include "sig.inc"
%include "utils.inc"
%include "input.inc"

%define ROCK     0
%define PAPER    1
%define SCISSORS 2

segment .bss
global rps
align 16
rps: resb rps_game.size

hashes: resb 255 * 33
solutions: resb 255 * 33
ochoices: resd 255
segment .text

youstr: db 'You ', 0
wonstr: db 'won', 0
loststr: db 'lost', 0
withstr: db ' with ', 0
pointsstr: db ' points!', 10, 0
newline: db 10, 0
otherchose: db 'Other supposedly chose ', 0

global rps_add_player
align 16
rps_add_player:
	mov rsi, 0
	mov sil, [rps + rps_game.nplayers]
	shl rsi, 2
	lea rax, [rps + rps_game.fds + rsi]
	mov dword [rax], edi
	shr rsi, 2
	add rsi, 1
	mov [rps + rps_game.nplayers], sil
	ret

lose:     db "Lose", 0
rock:     db "Rock", 0
paper:    db "Paper", 0
scissors: db "Scissors", 0
choices:  dq rock, paper, scissors
align 16
ctos:
	mov rax, lose
	cmp dil, 0
	jl .end
	cmp dil, 2
	jg .end
	shl dil, 3
	mov rax, [choices + rdi]
.end:
	ret

align 16
beats:
	push r11
	mov rax, 0
	mov r11, 1
	cmp rdi, ROCK
	je .rock
	cmp rdi, PAPER
	je .paper
	cmp rdi, SCISSORS
	je .scissors
	jmp .end
.rock:
	cmp rsi, SCISSORS
	cmove rax, r11
	jmp .end
.paper:
	cmp rsi, ROCK
	cmove rax, r11
	jmp .end
.scissors:
	cmp rsi, PAPER
	cmove rax, r11
.end:
	pop r11
	ret

align 16
clear:
	mov rax, 0
.loop:
	cmp rax, rsi
	je .end
	mov byte [rdi + rax], 0
	inc rax
	jmp .loop
.end:
	ret

ichose: db "I chose ", 10

struc turn_frame
.hash: resb 32
.secret: resb 32
.packet: resb 33
.solution: resb 33
.choice: resb 1
.size:
endstruc

align 16
do_turn:
	mov rdi, theres
	call puts
	mov rdi, 0
	mov dil, [rps + rps_game.nplayers]
	call putunbr
	mov rdi, opl
	call puts
	lea rdi, [rps + rps_game.points]
	mov rsi, 256
	call clear
	sub rsp, turn_frame.size
	call choose
	mov byte [rsp + turn_frame.secret], al
	mov byte [rsp + turn_frame.choice], al
	mov rax, WRITE
	mov rdi, 1
	mov rsi, ichose
	mov rdx, 8
	syscall
	mov dil, [rsp + turn_frame.choice]
	call ctos
	mov rdi, rax
	call puts
	mov rax, WRITE
	mov rdi, 1
	mov rsi, ichose + 8
	mov rdx, 1
	syscall
	mov rax, GETRANDOM
	lea rdi, [rsp + turn_frame.secret + 1]
	mov rsi, 31
	mov rdx, 0
	syscall
	lea rdi, [rsp + turn_frame.hash]
	lea rsi, [rsp + turn_frame.secret]
	mov rdx, 32
extern ahash_data
	call ahash_data
	mov byte [rsp + turn_frame.packet], 'K'
	lea rdi, [rsp + turn_frame.packet + 1]
	lea rsi, [rsp + turn_frame.hash]
	mov rdx, 32
	call memcpy
	mov r10, 0
	lea rsi, [rsp + turn_frame.packet]
	mov rdx, 33
	mov rdi, 0
.send_hashes:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_send_hashes
	mov rax, WRITE
	mov edi, [rps + rps_game.fds + r10 * 4]
	syscall
	add r10, 1
	jmp .send_hashes
.end_send_hashes:
	mov r10, 0
	mov r12, hashes
.read_hashes:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_read_hashes
	mov rax, READ
	mov rsi, r12
	mov edi, [rps + rps_game.fds + r10 * 4]
	syscall
	add r10, 1
	add r12, 33
	jmp .read_hashes
.end_read_hashes:
	mov byte [rsp + turn_frame.solution], 'V'
	mov r10b, byte [rsp + turn_frame.secret]
	mov byte [rsp + turn_frame.solution + 1], r10b

	lea rdi, [rsp + turn_frame.solution + 2]
	lea rsi,  [rsp + turn_frame.secret + 1]
	mov rdx, 31
	call memcpy
	mov r10, 0
	mov rdx, 33
	lea rsi, [rsp + turn_frame.solution]
	mov rdi, 0
.send_solution:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_send_solution
	mov rax, WRITE
	mov edi, [rps + rps_game.fds + r10 * 4]
	syscall
	add r10, 1
	jmp .send_solution
.end_send_solution:
	mov r10, 0
	mov r12, solutions
.read_solutions:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_read_solutions
	mov rax, READ
	mov edi, [rps + rps_game.fds + r10 * 4]
	mov rsi, r12
	syscall
	add r10, 1
	add r12, 33
	jmp .read_solutions
.end_read_solutions:
	mov r10, 0
	mov r12, solutions
	mov r13, ochoices
	mov r14, hashes
.validate_choices:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_validate_choices
	mov byte [r13], -1
	cmp byte [r12], 'V'
	jne .contvc
	sub rsp, 32
	mov rdi, rsp
	lea rsi, [r12 + 1]
	mov rdx, 32
	push r10
	call ahash_data
	pop r10
	mov rdi, otherchose
	call puts
	mov rdi, 0
	mov dil, [r12 + 1]
	call ctos
	mov rdi, rax
	call puts
	mov rdi, newline
	call puts
	mov rdi, rsp
	lea rsi, [r14 + 1]
	mov rdx, 32
	call memcmp
	add rsp, 32
	cmp rax, 0
	jne .contvc
	mov al, [r12 + 1]
	mov byte [r13], al
.contvc:
	add r10, 1
	add r12, 33
	add r13, 1
	add r14, 33
	jmp .validate_choices
.end_validate_choices:
	mov r10, 0
	mov r12, ochoices
.count_other_points:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_count_other_points
	mov byte [rps + rps_game.points + r10], -1
	mov al, byte [r12]
	cmp al, -1
	je .count_next
	mov r13, 0
	mov r14, 0
	mov r15, 0
	mov rdi, 0
	mov rsi, 0
.count_points:
	cmp r15b, byte [rps + rps_game.nplayers]
	jge .end_count_points
	mov dil, [ochoices + r10]
	mov sil, [ochoices + r15]
	call beats
	add r13, rax
	xchg dil, sil
	call beats
	add r14, rax
	add r15, 1
	jmp .count_points
.end_count_points:
	mov dil, [ochoices + r10]
	mov sil, [rsp + turn_frame.choice]
	call beats
	add r13, rax
	xchg dil, sil
	call beats
	add r14, rax
	sub r13, r14
	mov byte [rps + rps_game.points + r10], r13b
.count_next:
	add r10, 1
	jmp .count_other_points
.end_count_other_points:
	mov r10, 0
	mov r13, 0
	mov r14, 0
.count_mpoints:
	cmp r10b, byte [rps + rps_game.nplayers]
	jge .end_count_mpoints
	mov dil, [rsp + turn_frame.choice]
	mov sil, [ochoices + r10]
	call beats
	add r13, rax
	xchg dil, sil
	call beats
	add r14, rax
	add r10, 1
	jmp .count_mpoints
.end_count_mpoints:
	sub r13, r14
	mov [rps + rps_game.mypoints], r13b
	add rsp, turn_frame.size
	ret

theres: db "There's ", 0
opl: db " other players left!", 10, 0
someone: db "Someone lost with negative points", 10, 0

align 16
remove_player:
	push rdi
	mov rax, rdi
	sub byte [rps + rps_game.nplayers], 1

	push rax
	mov rdi, 0
	mov edi, [rps + rps_game.fds + rax * 4]
	mov rax, CLOSE
	syscall
	pop rax

	lea rdi, [rps + rps_game.fds + rax * 4]
	lea rsi, [rdi + 4]

	push rax
	mov rdx, 0
	mov dl, [rps + rps_game.nplayers]
	sub dl, al
	imul rdx, 4
	call memcpy
	pop rax

	lea rdi, [rps + rps_game.points + rax]
	lea rsi, [rdi + 1]
	mov rdx, 0
	mov dl, [rps + rps_game.nplayers]
	sub dl, al
	call memcpy
	pop rdi
	ret

align 16
rps_finish:
	mov rdi, youstr
	call puts
	mov rdi, loststr
	mov r11, wonstr
	mov al, [rps + rps_game.nplayers]
	cmp al, 0
	cmove rdi, r11
	call puts
	mov rdi, withstr
	call puts
	mov rdi, 0
	mov dil, [rps + rps_game.mypoints]
	call putunbr
	mov rdi, 1
	mov rdi, pointsstr
	call puts
	mov rax, 0
.close_connections:
	cmp al, [rps + rps_game.nplayers]
	jge .end_close_connections
	lea rdi, [rps + rps_game.fds + rax * 4]
	add rax, 1
	jmp .close_connections
.end_close_connections:
	mov byte [rps + rps_game.nplayers], 0
	mov rdi, el
	mov rsi, rps
	call remove_source
	ret

;extern remove_player
global rps_finish
global do_turn

align 16
rps_play:
	mov al, [rps + rps_game.nplayers]
	cmp al, 0
	je .end
	call do_turn
	mov rax, 0
	; {
.count_points:
	cmp al, byte [rps + rps_game.nplayers]
	jge .end_count_points
.find_loser:
	cmp al, byte [rps + rps_game.nplayers]
	jge .end_count_points
	cmp byte [rps + rps_game.points + rax], 0
	jl .found
	add rax, 1
	jmp .find_loser
.found:
	push rax
	mov rdi, someone
	call puts
	pop rax
	push rax
	mov rdi, rax
	call remove_player
	pop rax
.end_find_loser:
	jmp .count_points
	; }
.end_count_points:
	mov r12b, [rps + rps_game.mypoints]
	cmp r12b, 0
	jl .end
	jmp rps_play
.end:
	call rps_finish
	ret

align 16
rps_begin:
	lea rsi, [rsp - 128]
	mov rax, READ
	mov edi, [rps + rps_game.base + source.pfd + pollfd.fd]
	mov rdx, 128
	syscall
	call rps_play
	ret

global init_game
align 16
init_game:
	mov rax, SIGNALFD
	mov rsi, alarm_mask
	mov rdi, -1
	mov rdx, 8
	syscall
	mov dword [rps + rps_game.base + source.pfd + pollfd.fd], eax
	mov word [rps + rps_game.base + source.pfd + pollfd.events], POLLIN
	mov qword [rps + rps_game.base + source.receive], rps_begin
	ret
