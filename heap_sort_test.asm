        global _start
        extern print_unsigned
        extern sort
        extern shuffle

        section .data
array:  times 1000 dq 0

        section .text
_start:
        ; initialize array with some values
        xor rcx, rcx
.init_loop:
        mov [array + rcx*8], rcx
        inc rcx
        cmp rcx, 1000
        jne .init_loop

        mov rdi, array
        mov rsi, 1000
        call shuffle
        call sort

        xor rax, rax
.print_loop:
        mov rdi, qword [array + rax*8]
        push rax
        call print_unsigned
        pop rax
        inc rax
        cmp rax, 1000
        jne .print_loop

        ; exit 0
        mov rax, 60
        xor rdi, rdi
        syscall

