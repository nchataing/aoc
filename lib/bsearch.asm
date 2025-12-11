section .text

global bsearch

; rdi: value to search
; rsi: array ptr
; rdx: array length
; rcx: compare function pointer

; return value if found, -1 if not found
bsearch:
        push r8
        push r9
        push r10
        push r11
        test rdx, rdx
        jz .not_found

        mov r11, rsi    ; array base ptr
        mov r8, 0       ; left index
        mov r9, rdx     ; right index
        dec r9
.loop:  cmp r8, r9      ; while left <= right
        jg .not_found   ;
        mov r10, r8     ;
        add r10, r9     ;
        shr r10, 1      ; mid = (left + right) / 2
        mov rsi, qword [r11 + r10*8]
        call rcx
        cmp rax, 0
        cmove rax, rsi
        je .found
        jl .left
        mov r8, r10     ; value > mid
        inc r8
        jmp .loop
.left:  mov r9, r10     ; value < mid
        dec r9
        jmp .loop
.not_found:
        mov rax, -1
.found:
        pop r11
        pop r10
        pop r9
        pop r8
        ret
