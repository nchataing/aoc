section .bss
buffer resb 32

section .text

global print_unsigned

; rdi is the number to print, followed by a line break
print_unsigned:
    push rdx
    push r8
    push r9
    push r10
    push r11

    ; Check if the number is zero
    cmp rdi, 0
    jne .convert_number

    ; If zero, write '0' and newline
    mov byte [buffer], '0'
    mov byte [buffer + 1], 10  ; newline

    ; write syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 2
    syscall
    jmp .ret

.convert_number:
    mov byte [buffer + 31], 10   ; newline character at the end of the buffer
    mov rsi, buffer + 30        ; pointer to the end of the buffer
    mov rax, rdi                ; work on rax
    mov rbx, 10                 ; divide by 10
.convert_loop:
    xor rdx, rdx
    div rbx                     ; rax = rax / 10, rdx = rax % 10
    add rdx, '0'                ; convert remainder to ASCII
    mov byte [rsi], dl
    dec rsi
    test rax, rax
    jnz .convert_loop

    ; write syscall
    inc rsi
    mov rax, 1
    mov rdi, 1
    ; rsi is already set
    mov rdx, buffer + 32
    sub rdx, rsi
    syscall

.ret:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    ret
