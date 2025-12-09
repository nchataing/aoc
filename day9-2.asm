        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern sort

%include "lib/macros.asm"

        section .bss
COORDS resq 500 * 2         ; max 500 lines of (x, y)
EDGES  resq 250             ; index in coords

WALL_FLAG resb 1
EDGE_FLAG resb 1
MIN_FLAG resb 1
MAX_FLAG resb 1

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
        mov rdi, 12
        mov rsi, 1
        ;ALIGN call point_is_valid
        ;PRINT rax
        ALIGN call print
.break
        EXIT 0

print:
        mov rsi, 0
.a:     cmp rsi, 15
        jge .d
        mov rdi, 0
.b:     cmp rdi, 15
        jge .c
        push rdi
        push rsi
        ALIGN call point_is_valid
        PRINT rax
        pop rsi
        pop rdi
        inc rdi
        jmp .b
.c      inc rsi
        jmp .a
.d:     ret

;.e:     cmp rcx, LEN                    ; loop over all pairs
;        jge .g                          ; done
;        mov rdx, rcx                    ;
;        inc rdx                         ; only loop over rcx + 1 onward
;.f:     cmp rdx, LEN                    ; loop over all pairs
;        jge .f
;        mov rdi, rcx
;        mov rsi, rdx
;        push rcx
;        push rdx
;        ALIGN call process_rect         ; process rectangle (it will save & restore rcx + rdx)
;        pop rdx
;        pop rcx
;        mov rdi, rcx
;        inc rdx
;        jmp .e
;.f:     inc rcx
;        jmp .d
;.g:     PRINT RESULT
;        EXIT 0

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
        mov rax, [r8]               ; x1
        push rax                    ; save x1
        mov rbx, [r9]
        push rbx                    ; save x2
        sub rax, rbx                ; -x2
        cmp rax, 0
        jge .a
        imul rax, -1
.a:     inc rax
        add r8, 8
        add r9, 8
        mov rbx, [r8]               ; y1
        push rbx                    ; save y1
        mov r9, [r9]                ; y2
        push r9                     ; save y2
        sub rbx, r9                 ; -y2
        cmp rbx, 0
        jge .b
        imul rbx, rbx, -1
.b:     inc rbx
        mul rbx
        cmp RESULT, rax             ; check against current max
        jle .c                      ; return immediatly
        pop r8                      ; y2
        pop rsi                     ; y1
        pop rdx                     ; x2
        pop rdi                     ; x1
        push rax                    ; push area
        ALIGN call rect_is_valid    ; rdi=x1, rsi=y1, rdx=x2, r8=y2
        pop r8                      ; get back area
        test rax, rax               ; if result is ok (0)
        cmovz RESULT, r8            ; update result
.c:     ret

; for a rectangle to be valid, we need every point of the perimeter to be in the
; global shape
; (rdi, rsi) = (x1, y1)
; (rdx, r8) = (x2, y2)
rect_is_valid:
        ret

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
        ret
.f:     movzx rax, byte [WALL_FLAG] ;
        movzx rbx, byte [EDGE_FLAG] ;
        or rax, rbx                 ; either wall or edge flag set means inside
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
        shl rdi, 3+1+1          ; 3 = 8 bytes, 2 = (x,y), 2 = two vertices per edges
        shl rsi, 3+1+1          ; same
        mov rax, [COORDS+rdi]   ; load VERT[0].x
        sub rax, [COORDS+rsi]   ; substract VERT[1].x
        ret
