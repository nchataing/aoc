section .text

global shuffle

; rdi: pointer to the i64 array to shuffle
; rsi: size of the array

shuffle:
        test rsi, rsi
        jz .ret
        mov rcx, rsi
        dec rcx

.shuffle_loop:
        ; generate a random index between 0 and rcx
        ; for simplicity, we'll just use a linear congruential generator
        mov rax, rcx
        imul rax, 1103515245
        add rax, 12345
        and rax, 0x7FFFFFFF
        xor rdx, rdx
        mov rbx, rcx
        inc rbx
        div rbx
        mov rbx, rdx               ; rbx = random index between 0 and rcx
        ; swap rdi[rcx] and rdi[rbx]
        mov r8, [rdi + rcx*8]
        mov r9, [rdi + rbx*8]
        mov [rdi + rcx*8], r9
        mov [rdi + rbx*8], r8
        dec rcx
        jns .shuffle_loop

.ret:
        ret

