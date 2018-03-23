%include "rps.inc"

segment .bss
global rps
align 16
rps: resb rps_game.size

segment .text

global rps_add_player
align 16
rps_add_player:
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
end:
	ret

align 16
rps_play:
	mov al, [rps + rps_game.nplayers]
	cmp al, 0
	je .end
	lea rdi, [rps + rps_game.points]
	mov rsi, 256 * 4
	call clear
	call do_turn
	mov rax, 0
.count_points:
	cmp byte [rps + rps_game.nplayers], al
	jge .end_count_points
.find_loser:
	cmp byte [rps + rps_game.nplayers], al
	jge .end_count_points
	cmp dword [rps + rps_game.points + rax * 4], 0
	jl .found
	add rax, 1
	jmp .find_loser
.found:
	dec byte [rps + rps_game.nplayers]
	mov rbp, rax
	mov rdi, [rps + rps_game.fds + rax * 4]
	mov rax, CLOSE
	syscall
	mov rax, rbp
	lea rdi, [rps + rps_game.fds + rax * 4]
	lea rsi, [rps + rps_game.fds + 4 + rax * 4]
	mov rdx, 4
	mov bpl, byte [rps + rps_game.nplayers]
	sub bpl, al
	mul rdx, bpl
	push rax					;/me spills
	call memcpy
	pop rax
	lea rdi, [rps + rps_game.points + rax * 4]
	lea rsi, [rps + rps_game.points + 4 + rax * 4]
	mov rdx, 4
	push rax					;/me spills
	call memcpy
	pop rax
.end_find_loser:
	jmp .count_points

.end_count_points:
	jmp rps_play
.end:
	;Afficher message de fin;
	;Fermer les connections;
	;supprimer;
	mov rdi, el
	mov rsi, rps
	call remove_source
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