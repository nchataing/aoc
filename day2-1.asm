        global _start
        extern print_unsigned

        section .text
_start:
        ; r12 = base address of input
        ; r13 = current index in input
        ; r15 = result
        ; for each input line :
        ; - r8 will store the min value (199198)
        ; - r9 will store the min length (6)
        ; - r10 will store the max value (200200)
        ; - r11 will store the max length (6)

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
        mov r9, 0
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
        inc r9              ; count digits
        jmp .loop_first_digit

        ; read second number
.read_second:
        mov r10, 0          ; clear rbx to store number
        mov r11, 0
.loop_second_digit:
        mov rax, 0
        mov al, [r12+r13]
        inc r13             ; move to next character
        cmp al, ','         ; check for space (end of number)
        je .handle_interval
        sub al, '0'         ; convert char to digit
        imul r10, r10, 10
        add r10, rax        ; accumulate number
        inc r11             ; count digits
        jmp .loop_second_digit

        ; iterate on length from min_len to max_len
.handle_interval:
        mov rcx, r9
.main_loop:
        cmp rcx, r11
        jg .read_first ; continue with next input interval

        ; only consider even lengths
        mov rax, rcx
        and rax, 1
        test rax, rax
        je .continue
        inc rcx
        jmp .main_loop
.continue:
        push rcx
        mov rdi, rcx
        call count_hits
        pop rcx
        ; rax contains the number of hits for this length
        add r15, rax
        inc rcx
        jmp .main_loop

.done:
        ; print final result
        mov rdi, r15
        call print_unsigned
        ; exit
        mov rax, 60
        mov rdi, 0
        syscall


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

; @in rdi <- exponent
; increment counter for every hit between 10 ^ exponent - 1 and 10 ^ exponent
; x is a hit if r8 <= x * 10 ^ (len / 2) + x <= r10
; use r12, r13 & r14
count_hits:
        ; INIT
        push r12
        push r13
        push r14

        ; r12 <- 10 ^ (len / 2 - 1)
        mov rdi, rcx
        shr rdi, 1
        dec rdi
        call pow10
        mov r12, rax
        ; r13 <- 10 ^ (len / 2)
        mov r13, r12
        imul r13, 10

        mov r14, 0      ; hit counter
        ; start counter at max(10 ^ (len / 2 - 1), r8)
        mov rcx, r12    ; counter start from 10 ^ (len / 2 - 1)
        mov rdx, 0
        mov rax, r12
        div r13
        cmp rcx, rax
        jge .count_loop
        mov rcx, rax
.count_loop:
        mov rax, rcx
        imul rax, r13
        add rax, rcx
        cmp rax, r8
        jl .next
        cmp rax, r10
        jg .ret             ; exit if max is exceeded
        add r14, rax        ; add hit number to counter
.next:
        inc rcx
        cmp rcx, r13
        jge .ret
        jmp .count_loop

.ret:
        mov rax, r14    ; move hit counter to rax for return
        pop r14
        pop r13
        pop r12
        ret

