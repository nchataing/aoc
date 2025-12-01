        global _start
        extern print_unsigned
        extern read_stdin
        extern read_unsigned

%include "lib/macros.asm"

%define RESULT r11
%define LINE_COUNT 5        ; 4 lines on the test input
%define NB_IDX r14
%define POS_IN_LINE r10

        section .bss
NUMBERS resq 4096           ; space for numbers (4 lines of 1008 numbers)
LINE_LEN resq 1

        section .text
_start:
        ALIGN call read_stdin
        sub rsp, 8
        mov r15, rax        ; base address of input
        mov qword [LINE_LEN], 0
        mov r14, r15                ; find first newline
.a1:    cmp byte [r14], 10               ; check for newline
        je .a2
        inc r14
        jmp .a1
.a2:    sub r14, r15                ; LINE_LEN = r14 - r15
        inc r14
        mov [LINE_LEN], r14
        imul rax, r14, (LINE_COUNT - 1)
        add rax, r15
        mov r14, rax                ; r15 = start of input, r14 = operation line
        xor rcx, rcx
.b1:    cmp byte [r14+rcx], 0
        je .b2
        mov rdi, r14
        add rdi, rcx
        push rcx
        call process_group
        pop rcx
        add rcx, rdx                ; rdx = width of processed group block
        add r13, rax                ; accumulate result
        jmp .b1
.b2:    PRINT r13
        EXIT 0

; rdi = pointer to the start of the group (last line)
process_group:
        mov al, byte [rdi]
        mov rsi, 0                  ; acc if +
        mov r8, 1                   ; acc if *
        cmp al, '*'
        cmove rsi, r8
        movzx rdx, al

        mov rcx, 0
.a0:    cmp byte [rdi+rcx+1], '*'
        je .b
        cmp byte [rdi+rcx+1], '+'
        je .b
        cmp byte [rdi+rcx+1], 0
        je .b
.a1     push rcx
        push rdi
        push rdx
        add rdi, rcx                ; number column
        sub rdi, r14
        call process_number
        mov rsi, rax
        pop rdx
        pop rdi
        pop rcx
        inc rcx
        jmp .a0

.b:     mov rax, rsi
        mov rdx, rcx
        inc rdx
        ret

; rdi = column at which to read the number
; rsi = accumulator
; rdx = operation
process_number:
        mov rcx, 1
        mov rax, 0
        add rdi, r15                ; rdi points to first row at column rdi
.a0:    cmp rcx, LINE_COUNT
        jge .a2
        movzx rbx, byte [rdi]          ; read char
        cmp rbx, ' '
        je .a1
        sub rbx, '0'
        imul rax, rax, 10
        add rax, rbx
.a1:    inc rcx
        mov rbx, [LINE_LEN]
        add rdi, rbx
        jmp .a0
.a2:    cmp rdx, '*'
        jne .b
        mul rsi
        ret
.b      add rax, rsi
        ret
