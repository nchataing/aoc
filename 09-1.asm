        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin

%include "lib/macros.asm"

        section .bss
COORDS resq 500 * 2 * 8                 ; max 500 lines of (x, y)

%define IN_PTR r12
%define RESULT r14
%define LEN r15

        section .text
_start:
        ALIGN call read_stdin           ; read input
        mov IN_PTR, rax                 ; base address of input
        mov rcx, 0
.a:     movzx rax, byte [IN_PTR]        ; fetch byte
        cmp rax, 0                      ; null terminator = end of input
        je .b                           ; done
        mov rdi, IN_PTR                 ; buffer
        mov rsi, ','                    ; delimiter
        push rcx                        ; save index
        call read_unsigned              ; read x
        pop rcx                         ; restore index
        mov [COORDS + rcx], rax         ; store x
        add IN_PTR, rdx                 ; advance input pointer
        inc IN_PTR                      ; skip delimiter
        add rcx, 8                      ; next coordinate
        mov rdi, IN_PTR                 ; buffer
        mov rsi, 10                     ; delimiter
        push rcx                        ; save index
        call read_unsigned              ; read y
        pop rcx                         ; restore index
        mov [COORDS + rcx], rax         ; store y
        add IN_PTR, rdx                 ; advance input pointer
        inc IN_PTR                      ; skip delimiter
        add rcx, 8                      ; next coordinate
        jmp .a
.b:     shr rcx, 4                      ; rcx = #elts * 8 * 2
        mov LEN, rcx                    ; store length in r15
        mov RESULT, 0                   ; store result in r14
        mov rcx, 0                      ; coord i * LEN + j
.c:     cmp rcx, LEN                    ; loop over all pairs
        jge .f                          ; done
        mov rdx, rcx                    ;
        inc rdx                         ; only loop over rcx + 1 onward
.d:     cmp rdx, LEN                    ; loop over all pairs
        jge .e
        mov rdi, rcx
        mov rsi, rdx
        ALIGN call area
        cmp RESULT, rax
        cmovl RESULT, rax
        inc rdx
        jmp .d
.e:     inc rcx
        jmp .c
.f:     PRINT RESULT
        EXIT 0

area:
        push rcx
        push rdx
        shl rdi, 4                  ;
        mov r8, COORDS              ;
        add r8, rdi                 ; r8 points to (x1, y1)
        shl rsi, 4                  ;
        mov r9, COORDS              ;
        add r9, rsi                 ; r9 points to (x2, y2)
        mov rax, [r8]               ; x1
        sub rax, [r9]               ; -x2
        cmp rax, 0
        jge .a
        imul rax, -1
.a:     inc rax
        add r8, 8
        add r9, 8
        mov rbx, [r8]               ; y1
        sub rbx, [r9]               ; -y2
        cmp rbx, 0
        jge .b
        imul rbx, rbx, -1
.b:     inc rbx
        mul rbx
        pop rdx
        pop rcx
        ret





