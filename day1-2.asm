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
        mov byte [r12 + rax], 0 ; null terminate input

        xor r15, r15    ; store result in r15 (number of times dial points to 0)
        mov r14, 50     ; store current dial number in r14 (starts at 50)
        xor r13, r13    ; index for input string
        ; for each number
        ; - r8 will store the direction (-1 for L, 1 for R)
        ; - r9 will store the number to turn

.read_instruction:
        ; instruction format: [L|R][number] [L|R][number] ...
        mov al, [r12+r13]     ; read current character
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
        mov r8, -1
        jmp .read_number
.turn_right:
        mov r8, 1

.read_number:
        xor r9, r9              ; store number in r9
.loop_digit:
        xor rax, rax
        mov al, [r12+r13]
        inc r13                 ; move to next character
        cmp al, 10              ; check for line break
        je .compute_clicks
        sub al, '0'             ; convert char to digit
        imul r9, r9, 10
        add r9, rax            ; accumulate number
        jmp .loop_digit

.compute_clicks:
        ; to get number of clicks (not including the final click, computed when applying the turn)
        ; if R compute (current_dial + number) / 100
        ; if L compute (number + (current_dial == 0 ? 0 : 100 - current_dial) / 100
        cmp r8, 1
        je .compute_clicks_right
.compute_clicks_left:
        mov rax, r9
        cmp r14, 0
        je .compute_clicks_final
        add rax, 100
        sub rax, r14
        jmp .compute_clicks_final
.compute_clicks_right:
        mov rax, r14            ; rax = current_dial
        add rax, r9
.compute_clicks_final:
        cqo
        mov rcx, 100
        div rcx                ; rax = #clicks; rdx = +- new dial number
        add r15, rax
        mov r14, rdx
        imul r14, r8
        cmp r14, 0
        jge .read_instruction
        add r14, 100
        jmp .read_instruction

.done:
        mov rdi, r15
        call print_unsigned

        ; exit 0
        mov rax, 60
        xor rdi, rdi
        syscall
