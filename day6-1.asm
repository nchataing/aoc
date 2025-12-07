        global _start
        extern print_unsigned
        extern read_stdin
        extern read_unsigned

%include "lib/macros.asm"

%define RESULT r11
%define LINE_LEN r12
%define LINE_COUNT r13
%define NB_IDX r14
%define IN_PTR r15
%define POS_IN_LINE r10

        section .bss
NUMBERS resq 4096           ; space for numbers (4 lines of 1008 numbers)

        section .text
_start:
        add rsp, 8
        call read_stdin
        sub rsp, 8
        mov IN_PTR, rax        ; base address of input

        mov LINE_COUNT, 0
        mov LINE_LEN, 0
        mov NB_IDX, 0
        mov POS_IN_LINE, -1
        mov RESULT, 0

        add rsp, 8                  ; align stack for the whole loop

.a:     call skip_whitespace        ;
        movzx rax, byte [IN_PTR]    ; read next byte
        cmp rax, '+'                ; operation
        je .a1                      ; next phase
        cmp rax, '*'                ; operation
        je .a1                      ; next phase
        call read_number            ; read_number
        jmp .a                      ; loop
.a1:    mov rdx, 0                  ; clear rdx before div
        mov rax, NB_IDX             ; total numbers read
        div LINE_COUNT              ; rax = #lines
        mov LINE_LEN, rax           ; store line length
.b:     inc POS_IN_LINE             ; current position in line
        call skip_whitespace        ; skip to operation
        movzx rax, byte [IN_PTR]    ; read operation byte
        inc IN_PTR                  ; move pointer forward
        cmp rax, 0                  ; end of input?
        je .d
        mov rdi, POS_IN_LINE        ; rdi = current position in line
        cmp rax, '+'                ; addition?
        jne .c                      ; else multiplication
        call add                    ; perform addition
        add RESULT, rax             ; accumulate result
        jmp .b                      ; next operation
.c:     call mul                    ; perform multiplication
        add RESULT, rax             ; accumulate result
        jmp .b                      ; next operation
.d:     PRINT RESULT
        EXIT 0

; rdi <- perform addition on every number at position rdi of each line
add:
        mov rcx, 0                  ; line index
        mov rbx, 0                  ; sum
        shl rdi, 3                  ; rdi * 8 (size of qword)
        add rdi, NUMBERS            ; point to number of first line
.a:     mov rax, rcx                ;
        mul LINE_LEN                ; rax = rcx * LINE_LEN
        mov rax, [rdi + rax*8]      ; load number
        add rbx, rax                ; accumulate sum
        inc rcx
        cmp rcx, LINE_COUNT
        jl .a
        mov rax, rbx                ; return sum in rax
        ret

; rdi <- perform addition on every number at position rdi of each line
mul:
        mov rcx, 0                  ; line index
        mov rax, 1                  ; product
        shl rdi, 3                  ; rdi * 8 (size of qword)
        add rdi, NUMBERS            ; point to number of first line
.a:     push rax                    ; save acc
        mov rax, rcx                ;
        mul LINE_LEN                ; rax = rcx * LINE_LEN
        mov rbx, [rdi + rax*8]      ; load number
        pop rax                     ; restore acc
        mul rbx                     ; accumulate product
        inc rcx
        cmp rcx, LINE_COUNT
        jl .a
        ret


; skip whitespaces
skip_whitespace:
        movzx rax, byte [IN_PTR]    ; read next byte
        cmp rax, ' '                ; space?
        je .a                       ; skip spaces
        cmp rax, 10                 ; newline?
        jne .b                      ; nor ' ' nor '\n'
        inc LINE_COUNT              ; increment line count
.a:     inc IN_PTR                  ; move pointer forward
        jmp skip_whitespace         ; loop
.b:     ret                         ; return

; read number and store in NUMBERS array
read_number:
        mov rdi, IN_PTR
        mov rsi, ' '
        call read_unsigned
        mov [NUMBERS+NB_IDX*8], rax
        inc NB_IDX
        add IN_PTR, rdx
        ret
