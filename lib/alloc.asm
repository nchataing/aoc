        global alloc

        section .text

; rdi: size
alloc:
        mov r8, rdi                     ; size to allocate
        mov rax, 12                     ; brk syscall
        xor rdi, rdi                    ; request current brk
        syscall                         ;
        mov rbx, rax                    ; this will be our return value
        mov rdi, rax                    ; current brk
        add rdi, r8                     ; request new brk
        mov rax, 12                     ; brk syscall
        syscall
        mov rax, rbx                    ; return allocated pointer
        ret
