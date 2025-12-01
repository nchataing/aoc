        global _start
        extern print_unsigned

        section .text
_start:
        ; allocate 1MB and read input from stdin
        mov rax, 12         ; brk
        xor rdi, rdi
        syscall
        mov r12, rax        ; base address

        mov rdi, rax
        add rdi, 1024*1024  ; 1MB
        mov rax, 12
        syscall

        mov rax, 0          ; read
        mov rdi, 0          ; stdin
        mov rsi, r12        ; buffer
        mov rdx, 1024*1024  ; max size to read
        syscall
        mov byte [r12+rax], 0 ; null terminate input

        xor r15, r15    ; store result in r15 (number of times dial points to 0)
        mov r14, 50     ; store current dial number in r14 (starts at 50)
        xor r13, r13    ; index for input string
        ; for each number
        ; - r8 will store the direction (-1 for L, 1 for R)
        ; - r9 will store the number to turn

.read_instruction:
        ; instruction format: [L|R][number] [L|R][number] ...
        mov al, [r12+r13]       ; read current character
        inc r13                 ; move to next character
        cmp al, 0               ; check for \0 (end of input)
        je .done                 ; if newline, we're done
        cmp al, 'L'             ; check if turn left or right, store result in rdx
        je .turn_left
        cmp al, 'R'
        je .turn_right

        ; invalid input, exit 1
        mov rax, 60
        mov rdi, 1
        syscall

.turn_left:
        mov rdx, -1
        jmp .read_number
.turn_right:
        mov rdx, 1

.read_number:
        xor rbx, rbx            ; clear rbx to store number
.loop_digit:
        xor rax, rax
        mov al, [r12+r13]
        inc r13                 ; move to next character
        cmp al, 10              ; check for line break (end of number)
        je .apply_turn
        sub al, '0'             ; convert char to digit
        imul rbx, rbx, 10
        add rbx, rax            ; accumulate number
        jmp .loop_digit

.apply_turn:
        imul rdx, rbx           ; rdx = direction * number
        add r14, rdx            ; update current dial number

        ; check if r14 mod 100 is 0
        mov rax, r14
        cqo
        mov rcx, 100
        idiv rcx                 ; rax = r14 / 100, rdx = r14 % 100
        cmp rdx, 0
        jne .continue_loop
        inc r15                 ; increment count if dial points to 0

.continue_loop:
        jmp .read_instruction

.done:
        ; call printf to output result in r15
        mov rdi, r15
        call print_unsigned

        ; exit 0
        mov rax, 60
        xor rdi, rdi
        syscall
