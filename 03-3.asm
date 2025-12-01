        global _start
        extern print_unsigned

%define LINE_LENGTH 100         ; change constant depending on test input vs final input
%define NB_DIGITS 12

%macro PRINT 1
    mov rdi, %1
    call print_unsigned
%endmacro

%macro EXIT 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro

%macro RDTSCP 0
    rdtsc
    shl rdx, 32
    or rax, rdx
%endmacro

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

        RDTSCP
        mov r11, rax

.handle_bank:
        ; bank joltage in r14
        mov r14, 0
        ; init lower and upper bounds for line
        mov rdi, r13
        mov rsi, r13
        add rsi, LINE_LENGTH
        sub rsi, NB_DIGITS
        add rsi, 2

        mov rcx, NB_DIGITS
.next_digit_pair:
        cmp rcx, 0
        je .bank_finished
        push rcx
        call find_largest_digit_pair_in_range
        pop rcx
        ; update max joltage
        imul r14, r14, 100
        add r14, rax
        ; update range for next digit
        mov rdi, r8
        inc rdi ; lower bound = index of previous largest digit + 1
        add rsi, 2 ; upper bound++
        sub rcx, 2
        jmp .next_digit_pair

.bank_finished:
        add r15, r14        ; add bank joltage to result
        add r13, LINE_LENGTH
        inc r13             ; skip newline
        ; if character at r13 is 0, we reached end of input
        mov rax, 0
        mov al, [r12+r13]
        cmp rax, 0
        je .done
        jmp .handle_bank

.done:
        RDTSCP
        sub rax, r11        ; cycles elapsed
        PRINT rax
        PRINT r15
        EXIT 0

; @in rdi = range lower bound
; @in rsi = range upper bound (not included)
; @out rax = value of largest digit pair in range
; @out r8 = index of second digit of the pair
find_largest_digit_pair_in_range:
        mov r9, 0
        mov r10, 0

        mov rcx, rdi
.find_loop:
        cmp rcx, rsi
        jge .find_done
        ; read digit
        mov rbx, 0
        mov bl, [r12+rcx]
        sub rbx, '0'
        ; compute candidate value
        imul rax, r10, 10
        add rax, rbx
        ; compare against max
        cmp rax, r9
        cmovg r9, rax
        cmovg r8, rcx
        ; update largest digit
        cmp rbx, r10
        cmovg r10, rbx
        ; loop
        inc rcx
        jmp .find_loop
.find_done:
        mov rax, r9
        ret
