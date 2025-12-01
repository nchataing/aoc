        global _start
        extern print_unsigned
        extern read_stdin

%include "lib/macros.asm"

        section .bss
GRID resq 200*200       ; space for grid

%define WIDTH r8
%define HEIGHT r9
%define IN_PTR r10
%define RESULT r15

%macro READ_CELL 2
        mov rax, %2         ; row (Y)
        mul WIDTH
        add rax, %1         ; column (X)
        mov rax, qword [GRID + rax*8]
%endmacro

; col, row, value
%macro WRITE_CELL 3
        mov rax, %2         ; row (Y)
        mul WIDTH
        add rax, %1         ; column (X)
        mov qword [GRID + rax*8], %3
%endmacro

        section .text
_start:
        sub rsp, 8              ; align stack
        call read_stdin         ; read input
        mov IN_PTR, rax         ; base address of input
        call preprocess         ; remove newlines, fill WIDTH and HEIGHT

        mov rdi, rax            ; initial beam position
        mov rsi, 1              ; row 1
        call handle_cell        ; recursive beam handling
        add rsp, 8              ; restore stack
        PRINT RESULT
        PRINT rax
        EXIT 0

; rdi = col index
; rsi = row index
handle_cell:
        cmp rsi, HEIGHT             ; past last row?
        jl .a                       ; inbound, process
        mov rax, 1                  ; single beam
        ret                         ; done
.a:     READ_CELL rdi, rsi          ; read cell
        cmp rax, -1                 ; splitter?
        jne .b                      ; no, test empty cell
        inc RESULT                  ; count beam split
        dec rdi                     ; left cell
        sub rsp, 8                  ; align stack
        call handle_cell            ; recursive call
        add rsp, 8                  ; restore stack
        push rax                    ; save left result
        add rdi, 2                  ; right cell
        call handle_cell            ; recursive call
        pop rbx                     ; restore left result
        add rbx, rax                ; combine results
        dec rdi                     ; restore column
        WRITE_CELL rdi, rsi, rbx    ; write intermediate result
        mov rax, rbx                ; return value
        ret                         ; done
.b:     cmp rax, 0                  ; empty cell?
        jne .c                      ; no = already computed, rax contains the value
        inc rsi                     ; next row
        sub rsp, 8                  ; align stack
        call handle_cell            ; recursive call
        add rsp, 8                  ; restore stack
        dec rsi                     ; restore row
        mov rbx, rax                ; save result
        WRITE_CELL rdi, rsi, rbx    ; write intermediate result
        mov rax, rbx                ; return value
.c      ret                         ; done

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
        mov rbx, 0                      ; prepare for conversion
        cmp rax, '.'                    ; empty cell
        cmove rax, rbx                  ; convert
        je .b                           ; write cell & continue
        mov rbx, -1                     ; splitter is converted to -1
        cmp rax, '^'                    ; splitter
        cmove rax, rbx                  ; convert
        je .b                           ; write cell & continue
        cmp rax, 'S'                    ; initial beam
        push rcx                        ; save initial beam position
.b:     mov [GRID + rdx*8], rax         ; write cell
        inc rcx                         ; advance read pointer
        inc rdx                         ; advance write pointer
        jmp .a                          ; continue
.c:     cmp WIDTH, 0                    ; first line?
        cmove WIDTH, rcx                ; store width on first line
        inc HEIGHT                      ; increment height
        inc rcx                         ; advance read pointer
        jmp .a                          ; continue
.d:     pop rax                         ; initial beam position in rax
        ret                             ; done

