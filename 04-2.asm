        global main
        extern print_unsigned

%macro PRINT 1
    push rdi
    push rsi
    mov rdi, %1
    call print_unsigned
    pop rsi
    pop rdi
%endmacro

%macro EXIT 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro

%macro READ_BYTE 2
    mov rax, 0          ; read
    mov al, [%1 + %2]
%endmacro

%macro READ_CELL 2
    mov rax, %2         ; row (Y)
    mul WIDTH
    add rax, %1         ; column (X)
    mov rbx, 0
    mov bl, [r12 + rax]
    mov rax, rbx
%endmacro

%define WIDTH r8
%define HEIGHT r9
%define X r10
%define Y r11
%define INTERMEDIATE r14
%define RESULT r15

        section .text
main:
        mov RESULT, 0

        ; READ INPUT
        mov rax, 12         ; brk
        xor rdi, rdi
        syscall
        mov r12, rax        ; base address

        mov rdi, rax
        add rdi, 1024*1024  ; 1MB
        mov rax, 12
        syscall

        mov rax, 0          ; read
        mov rdi, 0          ; stdin
        mov rsi, r12        ; buffer
        mov rdx, 1024*1024  ; max size to read
        syscall
        mov byte [r12+rax], 0 ; null terminate input

        ; PREPROCESSING: remove newlines
        mov rcx, 0  ; read from [r12 + rcx], skipping newline
        mov rdx, 0  ; write to [r12 + rdx]

        mov WIDTH, 0   ; store width
        mov HEIGHT, 0   ; store height
.next_char:
        READ_BYTE r12, rcx
        cmp al, 0
        je .begin
        cmp al, 10
        je .skip_char
.write_char:
        mov byte [r12 + rdx], al
        inc rcx
        inc rdx
        jmp .next_char
.skip_char:
        cmp WIDTH, 0
        cmove WIDTH, rcx       ; store width on first line
        inc HEIGHT
        inc rcx
        jmp .next_char

.begin:
        mov INTERMEDIATE, 0
        mov X, 0          ; loop over width
.loop_x:
        cmp X, WIDTH
        jge .finished
        mov Y, 0          ; loop over height
.loop_y:
        cmp Y, HEIGHT
        jge .inc_x

        call check_cell

        inc Y
        jmp .loop_y

.inc_x:
        inc X
        jmp .loop_x

.finished:
        add RESULT, INTERMEDIATE
        cmp INTERMEDIATE, 0
        jne .begin       ; repeat until no changes
        PRINT RESULT
        EXIT 0


check_cell:
        ; check if cell at (X, Y) is neighbored by at least 4 '@' cells
        mov rdx, 0      ; counter

        READ_CELL X, Y
        cmp rax, '@'
        je .go
        ret             ; if current cell is not '@', skip

%macro CHECK 0
        ; rdi, rsi are already set
        push rdx
        call read_single_cell
        pop rdx
        add rdx, rax
        cmp rdx, 4
        jge .too_many
%endmacro

.go:
        mov rdi, X
        mov rsi, Y

        ; X-1, Y-1
        dec rdi
        dec rsi
        CHECK

        ; X, Y-1
        inc rdi
        CHECK

        ; X+1, Y-1
        inc rdi
        CHECK

        ; X+1, Y
        inc rsi
        CHECK

        ; X+1, Y+1
        inc rsi
        CHECK

        ; X, Y+1
        dec rdi
        CHECK

        ; X-1, Y+1
        dec rdi
        CHECK

        ; X-1, Y
        dec rsi
        CHECK

        inc INTERMEDIATE
        mov rax, Y
        mul WIDTH
        add rax, X
        mov byte [r12 + rax], '.'       ; empty cell

.too_many:
        ret

; rdi = x position
; rsi = y position
; return rax = 1 if cell is '@', 0 otherwise
read_single_cell:
        ; check boundaries
        cmp rdi, 0
        jl .ret_0
        cmp rdi, WIDTH
        jge .ret_0
        cmp rsi, 0
        jl .ret_0
        cmp rsi, HEIGHT
        jge .ret_0
        ; read cell
        READ_CELL rdi, rsi
        cmp rax, '@'
        jne .ret_0
        ; found a cell
        mov rax, 1
        ret
.ret_0:
        mov rax, 0
        ret
