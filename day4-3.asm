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

; (X, Y) -> rax
%macro READ_CELL 2
    mov rax, %2         ; row (Y)
    mul WIDTH
    add rax, %1         ; column (X)
    movzx rax, byte [r12 + rax]
%endmacro

; (X, Y, VAL)
%macro WRITE_CELL 3
    push rax
    mov rax, %2         ; row (Y)
    mul WIDTH
    add rax, %1         ; column (X)
    mov byte [r12 + rax], %3
    pop rax
%endmacro

%define WIDTH r8
%define HEIGHT r9
%define X r10
%define Y r11
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
        je .pp
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

.pp:
        mov RESULT, 0
        call preprocess
        call process
        PRINT RESULT
        EXIT 0

; PREPROCESS_PART

preprocess:
        mov Y, 0          ; loop over width
.loop_x:
        cmp Y, WIDTH
        jge .finished
        mov X, 0          ; loop over height
.loop_y:
        cmp X, HEIGHT
        jge .inc_x

        call preprocess_cell

        inc X
        jmp .loop_y

.inc_x:
        inc Y
        jmp .loop_x

.finished:
        ret


preprocess_cell:
        ; check if cell at (X, Y) is neighbored by at least 4 '@' cells
        mov rdx, 0      ; counter

        READ_CELL X, Y
        cmp rax, '.'
        jne .go
        WRITE_CELL X, Y, 0
        ret             ; if current cell is '.', skip

%macro CHECK 0
        ; rdi, rsi are already set
        push rdx
        call read_single_cell
        pop rdx
        add rdx, rax
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

        ; finalize result
        cmp rdx, 4
        jge .write_nb
        WRITE_CELL X, Y, 0
        inc RESULT
        ret

.write_nb:
        mov rbx, rdx
        WRITE_CELL X, Y, bl
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
        ; '.' or 0 means empty
        cmp rax, '.'
        je .ret_0
        cmp rax, 0
        je .ret_0
        ; non empty
        mov rax, 1
        ret
.ret_0:
        mov rax, 0
        ret

; PROCESS
process:
        mov rdi, 0          ; loop over width
.loop_x:
        cmp rdi, WIDTH
        jge .finished

        mov rsi, 0          ; loop over height
.loop_y:
        cmp rsi, HEIGHT
        jge .inc_x

        call process_cell

        inc rsi
        jmp .loop_y

.inc_x:
        inc rdi
        jmp .loop_x

.finished:
        ret

; assume (x,y) in (rdi,rsi)
; visit neighbors and apply %1
%macro VISIT_NEIGHBORS 1
        ; X-1, Y-1
        dec rdi
        dec rsi
        %1

        ; X, Y-1
        inc rdi
        %1

        ; X+1, Y-1
        inc rdi
        %1

        ; X+1, Y
        inc rsi
        %1

        ; X+1, Y+1
        inc rsi
        %1

        ; X, Y+1
        dec rdi
        %1

        ; X-1, Y+1
        dec rdi
        %1

        ; X-1, Y
        dec rsi
        %1

        ; come back at X, Y at the end
        inc rdi
%endmacro

process_cell:
        READ_CELL rdi, rsi
        cmp rax, 0
        jne .go
        ret             ; if current cell is '0', skip

%macro PROCESS_COUNT 0
        ; rdi, rsi are already set
        push rdx
        call read_single_cell
        pop rdx
        add rdx, rax
%endmacro

.go:
        mov rdx, 0      ; counter
        VISIT_NEIGHBORS PROCESS_COUNT

        ; write new number of neighbors, if cell can be emptied; then trigger neighbors
        cmp rdx, 4
        jge .write_nb
        WRITE_CELL rdi, rsi, 0
        inc RESULT
        ; VISIT_NEIGHBORS comes back to (rdi, rsi)
        VISIT_NEIGHBORS call trigger_effect
        ret

.write_nb:
        mov rbx, rdx
        WRITE_CELL rdi, rsi, bl
        ret

; (x, y) = (rdi, rsi)
trigger_effect:
        ; check boundaries
        cmp rdi, 0
        jl .done
        cmp rdi, WIDTH
        jge .done
        cmp rsi, 0
        jl .done
        cmp rsi, HEIGHT
        jge .done

        READ_CELL rdi, rsi
        cmp rax, 0
        je .done
        dec rax

        ; if still >= 4, just write and exit
        cmp rax, 4
        jge .write_nb

        WRITE_CELL rdi, rsi, 0
        inc RESULT
        ; recursively trigger neighbors
        VISIT_NEIGHBORS call trigger_effect
        ret

.write_nb:
        mov rbx, rax
        WRITE_CELL rdi, rsi, bl
.done:
        ret
