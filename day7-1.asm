        global _start
        extern print_unsigned
        extern read_stdin

%include "lib/macros.asm"

%define WIDTH r8
%define HEIGHT r9
%define IN_PTR r10
%define RESULT r15

%macro READ_CELL 2
    mov rax, %2         ; row (Y)
    mul WIDTH
    add rax, %1         ; column (X)
    movzx rbx, byte [IN_PTR + rax]
    mov rax, rbx
%endmacro

; col, row, value
%macro WRITE_CELL 3
    mov rax, %2         ; row (Y)
    mul WIDTH
    add rax, %1         ; column (X)
    mov byte [IN_PTR + rax], %3
%endmacro

        section .text
_start:
        add rsp, 8              ; align stack
        call read_stdin         ; read input
        mov IN_PTR, rax         ; base address of input
        call preprocess         ; remove newlines, fill WIDTH and HEIGHT
        sub rsp, 8              ; restore stack
        mov RESULT, 0           ; initialize RESULT
        dec HEIGHT              ; we only iterate to HEIGHT-1
        mov rcx, 0              ; rcx = row index
.a:     cmp rcx, HEIGHT         ; loop over rows
        jge .b                  ; done
        mov rdi, rcx            ; rdi = current row
        push rcx                ; save rcx
        call handle_row         ; handle row
        pop rcx                 ; restore rcx
        inc rcx                 ; next row
        jmp .a                  ; loop
.b:     PRINT RESULT
;       mov rax, WIDTH
;       mul HEIGHT
;       add rax, WIDTH
;       mov rdx, rax
;       mov rax, 1
;       mov rdi, 1
;       mov rsi, IN_PTR
;       mov rdx, rdx
;       syscall
        EXIT 0

; rdi = row index
handle_row:
        mov rcx, 0                  ; rcx = column index
.a:     cmp rcx, WIDTH              ; loop over columns
        jge .d                      ; done
        READ_CELL rcx, rdi          ; rax = cell value at (rcx, rdi)
        cmp rax, 'S'                ; is it a beam?
        je .b                       ; yes, handle beam
        inc rcx                     ; no, next column
        jmp .a                      ; loop
.b:     inc rdi                     ; move down
        READ_CELL rcx, rdi          ; rax = cell value below
        cmp rax, '^'                ; is it a splitter?
        jne .c                      ; no, skip
        inc RESULT                  ; yes, increment result
        dec rcx                     ; write left and right of splitter
        WRITE_CELL rcx, rdi, 'S'    ; write 'S' left
        add rcx, 2                  ; move to right
        WRITE_CELL rcx, rdi, 'S'    ; write 'S' right
        dec rdi                     ; restore row (column is already at +1)
        jmp .a                      ; continue
.c:     WRITE_CELL rcx, rdi, 'S'    ; write 'S' below
        dec rdi                     ; restore row
        inc rcx                     ; next column
        jmp .a                      ; continue
.d:     ret                         ; done

; remove newlines
; fill WIDTH and HEIGHT
preprocess:
        mov rcx, 0                      ; read from [IN_PTR + rcx], skipping newline
        mov rdx, 0                      ; write to [IN_PTR + rdx]
        mov WIDTH, 0                    ; store width
        mov HEIGHT, 0                   ; store height
.a:     movzx rax, byte [IN_PTR + rcx]  ; read next byte
        cmp rax, 0                      ; end of input?
        je .d                           ; yes, done
        cmp rax, 10                     ; newline?
        je .c                           ; yes, skip & increment height
.b:     mov byte [IN_PTR + rdx], al     ; write character
        inc rcx                         ; advance read pointer
        inc rdx                         ; advance write pointer
        jmp .a                          ; continue
.c:     cmp WIDTH, 0                    ; first line?
        cmove WIDTH, rcx                ; store width on first line
        inc HEIGHT                      ; increment height
        inc rcx                         ; advance read pointer
        jmp .a                          ; continue
.d:     ret                             ; done

