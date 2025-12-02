; IMPORTANT: the input was preprocessed to have range of numbers that have the
; same length in base 10

        global _start
        extern print_unsigned

        section .text
_start:

        ; r12 = base address of input
        ; r13 = current index in input
        ; r15 = result
        ; for each input line :
        ; - r8 will store interval min value
        ; - r9 will store interval max value
        ; - r10 will store the size of numbers in the interval (base 10)

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

        mov r15, 0
        mov r13, 0

.read_first:
        mov r8, 0          ; clear rbx to store number
        mov r10, 0
.loop_first_digit:
        mov rax, 0
        mov al, [r12+r13]
        inc r13             ; move to next character
        cmp al, 0           ; end of input
        je .done
        cmp al, '-'         ; check for space (end of number)
        je .read_second
        sub al, '0'         ; convert char to digit
        imul r8, r8, 10
        add r8, rax        ; accumulate number
        inc r10              ; count digits
        jmp .loop_first_digit

        ; read second number
.read_second:
        mov r9, 0          ; clear rbx to store number
.loop_second_digit:
        mov rax, 0
        mov al, [r12+r13]
        inc r13             ; move to next character
        cmp al, ','         ; check for space (end of number)
        je .loop_interval
        sub al, '0'         ; convert char to digit
        imul r9, r9, 10
        add r9, rax        ; accumulate number
        jmp .loop_second_digit

        ; loop over interval, use r8 as incrementing counter
.loop_interval:
        cmp r8, r9
        jg .read_first      ; continue with next input interval

        ; check if r8 is a hit
        mov rdi, r8
        mov rsi, r10
        call check_hit      ; r15 will be incremented in the call if hit
        inc r8
        jmp .loop_interval

.done:
        ; print final result
        mov rdi, r15
        call print_unsigned
        ; exit
        mov rax, 60
        mov rdi, 0
        syscall

; @in rdi <- number to check
; @in rsi <- length of number in base 10
check_hit:
    ; iterate on exponent from 1 to length / 2
    mov r11, rsi
    mov rbx, rsi
    shr rbx, 1          ; rbx = length / 2
    mov rcx, 0          ; counter
    mov rsi, 1          ; 10 ^ counter
.loop:
    inc rcx
    imul rsi, rsi, 10
    cmp rcx, rbx
    jg .end
    ; test divisibility of original number length by current counter
    mov rax, r11
    mov rdx, 0
    div rcx
    cmp rdx, 0
    jne .loop
    ; call subroutine
    push rbx
    push rcx
    call test_exponent
    pop rcx
    pop rbx
    cmp rax, 1
    je .hit
    jmp .loop
.hit:
    add r15, rdi
.end:
    ret

; @in rdi <- number to test
; @in rsi <- 10 ^ some exponent
test_exponent:
    mov rax, rdi
    mov rdx, 0
    ; do first division outside the loop to store the target sub-string
    div rsi
    mov r14, rdx    ; r14 = target sub-string, subsequent reminders must match this
.next:
    cmp rax, 0
    je .hit
    mov rdx, 0
    div rsi
    cmp rdx, r14
    jne .no_hit
    jmp .next

.hit:
    mov rax, 1
    ret
.no_hit:
    mov rax, 0
    ret
