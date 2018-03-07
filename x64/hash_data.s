;; 1 - destination, 2-5 - registres à selectionner, 6 - select reg
%macro select 6
	cmp %6, 0
	cmove %1, %2
	cmp %6, 1
	cmove %1, %3
	cmp %6, 2
	cmove %1, %4
	cmp %6, 3
	cmove %1, %5
%endmacro

;; 1 - select reg, 2-5 - registres à selectionner, 6 - source
%macro save 6
	cmp %1, 0
	cmove %2, %6
	cmp %1, 1
	cmove %3, %6
	cmp %1, 2
	cmove %4, %6
	cmp %1, 3
	cmove %5, %6
%endmacro

global ahash_data
ahash_data:
.init:
	push r12
	push r13
	push r14
	push r15

	mov r12, 0x6b901122fd987193
	mov r13, 0xf61e2562c040b340
	mov r14, 0xd62f105d02441453
	mov r15, 0x21e1cde6c33707d6

	mov r10, 0
.dataloop:
	cmp r10, rdx
	je .end

.hash_init:
	mov r11, 1
.hashloop:
	cmp r11, 64
	jg .hashend
	; j = r11, i = r10
	; r8 = mask
	; r9 = ret.hash[mask]
	mov r8, r11
	and r8, 3
	select r8, r12, r13, r14, r15, r8
	mov r9, r8
	mov rcx, r11
	shr r9, cl
	and r9, 3					; r9 = mask
	select r8, r12, r13, r14, r15, r9 ;r8 = hash[mask]

	; peut probablement être optimisé pour faire 16 fois moins d'accès mémoire
	; haha
	; vu que rcx ne sert que pour cl, on peut lire 8 octets
	; d'un coup et mémoriser le nombre d'octets consommé dans
	; une partie de rcx, et refaire une lecture quand on tombe à 0
	mov rax, [rsi + r10]
	and rax, 0xFF
	not rax
	sal rax, cl
	add r8, rax

	mov rax, [rsi + r10]
	and rax, 0xFF
	add rax, 1
	imul rax, r11
	add r10, 1
	imul rax, r10
	sub r10, 1
	sub r8, rax

	save r9, r12, r13, r14, r15, r8

	mov rax, r8
	shr rax, cl
	and rax, r9
	select rcx, r12, r13, r14, r15, rax
	add r8, rcx
	save r9, r12, r13, r14, r15, r8

	add r11, 5
	jmp .hashloop
.hashend:
	xor r12, r13
	xor r13, r14
	xor r14, r15
	xor r15, r12

	add r10, 1
	jmp .dataloop
.end:
	mov [rdi +  0], r12
	mov [rdi +  8], r13
	mov [rdi + 16], r14
	mov [rdi + 24], r15
	mov rax, rdi
	pop r15
	pop r14
	pop r13
	pop r12
	ret
