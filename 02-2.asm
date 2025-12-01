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
        ; check if rcx is a hit

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
    mov r14, rdi
    ; check if length is even
    mov rax, rsi
    and rax, 1
    test rax, rax
    jne .end

    ; cut rdi in half digits
    mov rax, rsi
    shr rax, 1
    mov rdi, rax    ; rdi = half length
    call pow10      ; rax = 10 ^ (length/2)
    mov rbx, rax    ; rbx = 10
    mov rax, r14    ; restore number to rax
    mov rdx, 0
    div rbx         ; rax = first half, rdx = second half
    cmp rax, rdx
    jne .end
    add r15, r14    ; rax == rdx, it's a hit, increment result
.end:
    ret

; @in rdi <- exponent
; @out rax -> 10 ^ exponent
pow10:
        mov rax, 1
        mov rbx, 10
.pow10_loop:
        cmp rdi, 0
        je .pow10_done
        imul rax, rbx
        dec rdi
        jmp .pow10_loop
.pow10_done:
        ret
