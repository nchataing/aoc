        global _start
        extern print_unsigned

        section .text
_start:

        ; r15 = result
        ; for each input line :
        ; - r14 = largest joltage so far
        ; - r13 = largest digit so far
        mov r15, 0

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


        ; use rcx to track current index in input
        mov rcx, 0

.handle_bank:
        ; read bank max joltage
        mov r14, 0
        mov r13, 0
.read_digit:
        mov rax, 0
        mov al, [r12+rcx]
        inc rcx             ; move to next character
        cmp al, 0           ; end of input
        je .done
        cmp al, 10          ; check for newline (end of number)
        je .bank_finished
        sub al, '0'         ; convert char to digit
        mov rdi, rax
        call handle_digit
        jmp .read_digit

        mov r13, rax        ; update largest digit so far
.bank_finished:
        add r15, r14        ; add largest joltage to result
        jmp .handle_bank

.done:
        mov rdi, r15
        call print_unsigned
        mov rax, 60         ; exit
        mov rdi, 0
        syscall

; rdi = digit to handle
; r13 = largest digit so far
; r14 = largest joltage so far

; r14 <- max(r14, r13 * 10 + rdi)
; r13 <- max(r13, rdi)
handle_digit:
        imul rax, r13, 10
        add rax, rdi
        cmp rax, r14
        cmovg r14, rax

        cmp rdi, r13
        cmovg r13, rdi

        ret
