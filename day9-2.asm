        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern sort

%include "lib/macros.asm"

%macro PUSH 0
        push rdi
        push rsi
        push rdx
        push r8
        push rcx
%endmacro

%macro POP 0
        pop rcx
        pop r8
        pop rdx
        pop rsi
        pop rdi
%endmacro


        section .bss
COORDS: resq 500 * 2         ; max 500 lines of (x, y)
EDGES:  resq 500             ; index in coords

WALL_FLAG: resb 1
EDGE_FLAG: resb 1
MIN_FLAG: resb 1
MAX_FLAG: resb 1

%define IN_PTR r12
%define EDGES_LEN r13
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
        mov EDGES_LEN, LEN              ; consider all horizontal edges
        shr EDGES_LEN, 1                ;
        cmp rcx, LEN                    ;
        mov rcx, 0                      ;
.c:     cmp rcx, EDGES_LEN              ; populate array for edges sorting
        jge .d                          ;
        mov [EDGES + rcx*8], rcx        ;
        inc rcx                         ;
        jmp .c                          ;
.d:     mov rdi, EDGES                  ; sort edges
        mov rsi, EDGES_LEN              ;
        lea rdx, [rel cmp_edges]        ;
        ALIGN call sort                 ;
        mov RESULT, 0                   ; reset result
        ALIGN call process
        PRINT RESULT
        EXIT 0

process:
        mov rcx, 0
.a:     cmp rcx, LEN                    ; loop over all pairs
        jge .d                          ; done
        PRINT rcx
        mov rdx, rcx                    ;
        inc rdx                         ; only loop over rcx + 1 onward
.b:     cmp rdx, LEN                    ; loop over all pairs
        jge .c
        mov rdi, rcx
        mov rsi, rdx
        push rcx
        push rdx
        ALIGN call process_rect         ; process rectangle
        pop rdx
        pop rcx
        inc rdx
        jmp .b
.c:     inc rcx
        jmp .a
.d:     ret

; compute the area first
; if it's less than the current result, don't bother checking its validity
; as it's not a candidate
process_rect:
        shl rdi, 4                  ;
        mov r8, COORDS              ;
        add r8, rdi                 ; r8 points to (x1, y1)
        shl rsi, 4                  ;
        mov r9, COORDS              ;
        add r9, rsi                 ; r9 points to (x2, y2)
        mov rdi, [r8]               ; x1
        mov rsi, [r8+8]             ; y1
        mov rdx, [r9]               ; x2
        mov r8, [r9+8]              ; y2
        cmp rdi, rdx                ; Swap (x1,x2) to have x1 <= x2
        jle .a                      ;
        mov rax, rdi                ; yes -> swap values
        mov rdi, rdx                ;
        mov rdx, rax                ;
.a:     cmp rsi, r8                 ; Swap (y1,y2) to have y1 <= y2
        jle .b                      ;
        mov rax, rsi                ; yes -> swap values
        mov rsi, r8                 ;
        mov r8, rax                 ;
.b:     ALIGN call area             ; compute area
        cmp rax, RESULT             ; check against current max
        jle .c                      ; return immediatly
        push rax                    ; push area
        ALIGN call rect_is_valid    ; rdi=x1, rsi=y1, rdx=x2, r8=y2
        pop rbx                     ; get back area
        test rax, rax               ; if result is ok (0)
        cmovnz RESULT, rbx          ; update result
.c:     ret


; compute area of rect (rdi, rsi) [upper right corner] -> (rdx, r8) [lower left corner]
area:
        push rdx
        mov rax, rdx                ; compute area
        sub rax, rdi                ;
        inc rax                     ; rax = x2 - x1 + 1
        mov rbx, r8                 ;
        sub rbx, rsi                ;
        inc rbx                     ; rbx = y2 - y1 + 1
        mul rbx                     ; rax = area
        pop rdx
        ret


; for a rectangle to be valid, we need every point of the perimeter to be in the
; global shape
; (rdi, rsi) = (x1, y1)
; (rdx, r8) = (x2, y2)
rect_is_valid:
.b:     mov rcx, rdi                ; x <- x1
.c:     cmp rcx, rdx                ; while x <= x2
        jg .d                       ;
        PUSH
        mov rdi, rcx                ; x
        mov rsi, rsi                ; y1
        call point_is_valid         ;
        POP
        test rax, rax               ; if rax == 0
        jz .z                       ; point is not in shape, stop immediately
        PUSH
        mov rdi, rcx                ; x
        mov rsi, r8                 ; y2
        call point_is_valid         ;
        POP
        test rax, rax               ; if rax == 0
        jz .z                       ; point is not in shape, stop immediately
        inc rcx                     ;
        jmp .c                      ; loop
.d:     mov rcx, rsi                ; x <- x1
        inc rcx                     ; x <- x1 + 1
        dec r8                      ;
.e:     cmp rcx, r8                 ; while x <= x2 - 1 (exclude bounds)
        jge .f
        PUSH
        mov rdi, rdi                ; x1
        mov rsi, rcx                ; y
        call point_is_valid         ;
        POP
        test rax, rax               ; if rax == 0
        jz .z                       ; point is not in shape, stop immediately
        PUSH
        mov rdi, rdx                ; x2
        mov rsi, rcx                ; y
        call point_is_valid         ;
        POP
        test rax, rax               ; if rax == 0
        jz .z                       ; point is not in shape, stop immediately
        inc rcx                     ;
        jmp .e                      ; loop
.f:     mov rax, 1
.z:     ret

; rdi = x
; rsi = y
; cast a ray from (y, 0) to (y, x) and count intersections with edges
; so essentially iterate over all edges
point_is_valid:
        mov rcx, 0
        mov byte [WALL_FLAG], 0
        mov byte [EDGE_FLAG], 0
        mov byte [MIN_FLAG], 0
        mov byte [MAX_FLAG], 0
.a:     cmp rcx, EDGES_LEN          ; loop over edges
        jge .f                      ; done
        mov rdx, [EDGES + rcx*8]    ; get edge index
        inc rcx                     ; increment now for the next iteration
        shl rdx, 3+1+1              ;
        add rdx, COORDS             ; pointer to the edge at index rcx
        mov r8, [rdx]               ; edge[0].x (for recall edge[0].x == edge[1].x)
        cmp rdi, r8                 ; point.x < edge.x ?
        jl .f                       ; we finished counting
        mov r9, [rdx+8]             ; edge[0].y
        mov r10, [rdx+24]           ; edge[1].y
        cmp r9, r10                 ; swap if needed
        jle .b
        mov r11, r9
        mov r9, r10
        mov r10, r11
.b:     cmp rsi, r9                 ; point.y < edge.min_y ?
        jl .a                       ; no interection
        cmp rsi, r10                ; point.y > edge.max_y ?
        jg .a                       ; no intersection
        cmp rsi, r9                 ; point.y == edge.min_y ?
        jne .c                      ; no, continue
        ALIGN call handle_edge_min  ; handle edge through min y
        jmp .e                      ; continue
.c:     cmp rsi, r10                ; point.y == edge.max_y ?
        jne .d                      ; no, continue
        ALIGN call handle_edge_max  ; handle edge through max y
        jmp .e                      ; continue
.d:     mov al, byte [WALL_FLAG]    ; strict middle of edge, toggle wall flag
        xor al, 1                   ; toggle
        mov byte [WALL_FLAG], al    ;
.e:     cmp rdi, r8                 ; point.x == edge.x ?
        jne .a                      ; continue
        mov rax, 1                  ; special case: on edge is considered inside
.special:
        ret
.f:     movzx rax, byte [WALL_FLAG] ;
        movzx rbx, byte [EDGE_FLAG] ;
        or rax, rbx                 ; either wall or edge flag set means inside
.g:
        ret

handle_edge_min:
        mov al, [EDGE_FLAG]         ; on edge?
        test al, al                 ; are we already on an edge?
        jz .a                       ; no do as if crossing normally
        mov al, [MIN_FLAG]          ;
        test al, al                 ; did we enter through min before?
        jz .b                       ; no => do as if we crossed a single wall
.a:     mov bl, [WALL_FLAG]         ; toggle wall if entering or if we entered through min
        xor bl, 1                   ;
        mov [WALL_FLAG], bl         ; store back
.b:     mov al, [EDGE_FLAG]
        xor al, 1                   ;
        mov [EDGE_FLAG], al         ; EDGE_FLAG = ~EDGE_FLAG
        mov byte [MIN_FLAG], 1      ; set min flag
        mov byte [MAX_FLAG], 0      ; reset max flag
.c:     ret

handle_edge_max:
        mov rax, 0
        mov al, [EDGE_FLAG]         ; on edge?
        test al, al                 ; are we already on an edge?
        jz .a                       ; no do as if crossing normally
        mov al, [MAX_FLAG]          ;
        test al, al                 ; did we enter through max before?
        jz .b                       ; no => do as if we crossed a single wall
.a:     mov bl, [WALL_FLAG]         ; toggle wall if entering or if we entered through max
        xor bl, 1                   ;
        mov [WALL_FLAG], bl         ; store back
.b:     mov al, [EDGE_FLAG]
        xor al, 1                   ;
        mov [EDGE_FLAG], al         ; EDGE_FLAG = ~EDGE_FLAG
        mov byte [MIN_FLAG], 0      ; reset min flag
        mov byte [MAX_FLAG], 1      ; set max flag
        ret

; rdi = index of first edge
; rsi = index of second edge
; basically we reconsider (COORDS[2*n], COORDS[2*n+1]) as the list of vertical edges
; since COORDS[2*n].x == COORDS[2*n+1].x
; compare the x coordinate of the two edges
cmp_edges:
        push rdi
        push rsi
        shl rdi, 3+1+1          ; 3 = 8 bytes, 2 = (x,y), 2 = two vertices per edges
        shl rsi, 3+1+1          ; same
        mov rax, [COORDS+rdi]   ; load VERT[0].x
        sub rax, [COORDS+rsi]   ; substract VERT[1].x
        pop rsi
        pop rdi
        ret

; for debugging purpose
;print:
;        mov rsi, 0
;.a:     cmp rsi, 15
;        jge .d
;        mov rdi, 0
;.b:     cmp rdi, 15
;        jge .c
;        push rdi
;        push rsi
;        ALIGN call point_is_valid
;        PRINT rax
;        pop rsi
;        pop rdi
;        inc rdi
;        jmp .b
;.c      inc rsi
;        jmp .a
;.d:     ret
