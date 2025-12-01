        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern sort
        extern bsearch

%include "lib/macros.asm"

%define NB_SHAPES 6

        section .bss
SHAPES resq NB_SHAPES           ; store shape area
LINE_AREA resq 1
LINE_SHAPE_LOWER_BOUND resq 1

        section .text
_start:
        ALIGN call read_stdin           ; read input
        mov r15, rax                    ; input
        ALIGN call parse_shapes
        xor r8, r8
.loop:  cmp byte [r15], 0
        je .done
        push r8
        call process_line
        pop r8
        add r8, rax
        jmp .loop
.done:  PRINT r8
        EXIT 0


parse_shapes:
        xor rcx, rcx
.a0:    cmp rcx, NB_SHAPES
        jge .a1
        ALIGN call skip_line
        push rcx
        call parse_shape
        pop rcx
        mov [SHAPES+rcx*8], rax
        inc rcx
        jmp .a0
.a1:    ret


; shape has format
; ###\n
; #..\n
; ..#\n
; read 12 characters & count number of '#'
parse_shape:
        xor rax, rax
        xor rcx, rcx
.a0:    cmp rcx, 12
        jge .a1
        cmp byte [r15], '#'
        jne .cont
        inc rax
.cont:  inc rcx
        inc r15
        jmp .a0
.a1:    inc r15                 ;
        ret


skip_line:
        cmp byte [r15], 10
        je .done
        inc r15
        jmp skip_line
.done:  inc r15
        ret

process_line:
        mov rdi, r15
        ALIGN call read_unsigned
        mov r8, rax
        add r15, rdx
        inc r15
        mov rdi, r15
        ALIGN call read_unsigned
        mov r9, rax
        add r15, rdx
        add r15, 2                          ; skip over ': '
        mov rdx, 0
        mov rax, r8
        mul r9
        mov [LINE_AREA], rax                ; r9 = total available area
        mov rcx, 9
        div rcx
        mov [LINE_SHAPE_LOWER_BOUND], rax

        xor rcx, rcx
        xor r8, r8          ; number of shapes
        xor r9, r9          ; total shapes area
.a0:    cmp rcx, NB_SHAPES
        jge .a1
        push rcx
        mov rdi, r15
        call read_unsigned
        pop rcx
        add r8, rax
        add r15, rdx
        inc r15
        mov rdx, 0
        mov rbx, [SHAPES+rcx*8]
        mul rbx
        add r9, rax
        inc rcx
        jmp .a0
.a1:

        ; first case: total shapes area > line area (can't fit)
        cmp r9, [LINE_AREA]
        jle .b
        mov rax, 0
        ret
.b:     ; second case: #shapes < line shape lower bound (definitely can fit)
        cmp r8, [LINE_SHAPE_LOWER_BOUND]
        jg .c
        mov rax, 1
        ret
.c:     ; otherwise, need to try combinations
        PRINT 9999
        EXIT 1
        ret
