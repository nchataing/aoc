%define LEN 10

        global _start
        extern print_unsigned
        extern sort
        extern shuffle

        section .data
array:  times LEN dq 0

        section .text
_start:
        ; initialize array with some values
        xor rcx, rcx
.init_loop:
        mov [array + rcx*8], rcx
        inc rcx
        cmp rcx, LEN
        jne .init_loop

        mov rdi, array
        mov rsi, LEN
        call shuffle
        lea rdx, [rel cmp]
        call sort

        xor rax, rax
.print_loop:
        mov rdi, qword [array + rax*8]
        push rax
        call print_unsigned
        pop rax
        inc rax
        cmp rax, LEN
        jne .print_loop

        ; exit 0
        mov rax, 60
        xor rdi, rdi
        syscall

cmp:
    mov rax, rdi
    sub rax, rsi
    ret
