        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern alloc
        extern sort
        extern join

%include "lib/macros.asm"

%define LEN 1000           ; input length
%define EDGES 1000
;%define LEN 20             ; test input length
;%define EDGES 10         ; how much edges to retrieve
%define IN_PTR r12
%define COORDS r13          ; store pointer to coords
%define HEAP r14
%define HEAP_SIZE r11

        section .bss
DISTANCES resq 0                     ; store pointer to distances
UNION_FIND resq LEN * 16             ; union find array

        section .text
_start:
        ALIGN call read_stdin           ; read input
        mov IN_PTR, rax                 ; base address of input
        mov rdi, 1024 * 1024 * 8
        ALIGN call alloc                ; allocate coords array
        mov COORDS, rax                 ; save coords pointer
        mov rdi, 1024 * 1024 * 8
        ALIGN call alloc                ; allocate heap array
        mov HEAP, rax                   ; save heap pointer
        mov rdi, 1024 * 1024 * 8
        ALIGN call alloc                ; allocate distances array
        mov [DISTANCES], rax            ; save distances pointer
        xor rcx, rcx                    ; coords index
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
        mov rsi, ','                    ; delimiter
        push rcx                        ; save index
        call read_unsigned              ; read y
        pop rcx                         ; restore index
        mov [COORDS + rcx], rax         ; store y
        add IN_PTR, rdx                 ; advance input pointer
        inc IN_PTR                      ; skip delimiter
        add rcx, 8                      ; next coordinate
        mov rdi, IN_PTR                 ; buffer
        mov rsi, 10                     ; delimiter \n
        push rcx                        ; save index
        call read_unsigned              ; read z
        pop rcx                         ; restore index
        mov [COORDS + rcx], rax         ; store z
        add IN_PTR, rdx                 ; advance input pointer
        inc IN_PTR                      ; skip delimiter
        add rcx, 16                     ; next coordinate (align to 32 bytes)
        jmp .a
.b:     mov rcx, 0                      ; coord i * LEN + j
        mov HEAP_SIZE, 0                ; initialize heap size
.c:     cmp rcx, LEN*LEN                ; loop over all pairs
        jge .e                          ; done
        mov rdx, 0                      ; prepare div
        mov rax, rcx                    ; copy
        mov rbx, LEN                    ; divisor
        div rbx                         ; rax = i, rdx = j
        mov r8, rax                     ; r8 = i
        mov r9, rdx                     ; r9 = j
        cmp r8, r9
        jl .d                           ; only compute for i < j
        inc rcx                         ; next pair
        jmp .c
.d:     ALIGN call compute_distance     ; compute distance
        mov rbx, [DISTANCES]            ; load distances pointer
        mov [rbx + rcx*8], rax          ; store distance
        mov [HEAP + HEAP_SIZE*8], rcx   ; push edge index onto heap
        inc rcx                         ; next pair
        inc HEAP_SIZE                   ; increase heap size
        jmp .c                          ; repeat
.e:     mov rdi, HEAP                   ; pointer to heap
        mov rsi, HEAP_SIZE              ; size of heap
        lea rdx, [rel compare_edges]    ; comparison function
        call sort
        mov rcx, 0                      ; initialize UNION_FIND
.f:     cmp rcx, LEN                    ;
        jge .g                          ;
        mov rdx, rcx
        shl rdx, 4                      ; rcx * 16
        mov [UNION_FIND + rdx], rcx     ; repurpose array
        add rdx, 8
        mov qword [UNION_FIND + rdx], 1 ; size = 1
        inc rcx                         ;
        jmp .f                          ;
.g:     mov rcx, 0                      ; processing edges
.h:     mov rdx, 0
        mov rax, [HEAP + rcx*8]         ; get edge index
        mov rbx, LEN
        div rbx                         ; rax = i, rdx = j
        mov rdi, UNION_FIND
        mov rsi, rax                    ; rdx already contains second point
        push rsi
        push rdx
        ALIGN call join
        cmp rax, LEN                    ; check if all connected
        je .i                           ; if size == LEN, all points connected
        pop rax                         ; discard values
        pop rax                         ;
        inc rcx
        jmp .h
.i:     pop rax                         ; first point
        shl rax, 5
        mov rbx, [COORDS + rax]         ; x coord
        pop rax                         ; second point
        shl rax, 5
        mov rax, [COORDS + rax]         ; x coord
        mul rbx
        PRINT rax                       ; print product of x coords
        EXIT 0

; compute distance between coord of points r8 and r9
compute_distance:
        push r8                 ; save indices
        push r9                 ;
        shl r8, 5               ; r8 = r8 * 32
        lea r8, [COORDS + r8]   ; r8 = &COORDS[r8*32]
        shl r9, 5               ; r9 = r9 * 32
        lea r9, [COORDS + r9]   ; r8 = &COORDS[r8*32]
        mov rdx, 0
        mov rax, [r8]           ; x1
        sub rax, [r9]           ; x2
        mul rax
        mov r10, rax            ; store in r10
        mov rdx, 0
        mov rax, [r8+8]         ; y1
        sub rax, [r9+8]         ; y2
        mul rax                 ;
        add r10, rax            ;
        mov rdx, 0
        mov rax, [r8+16]        ; z1
        sub rax, [r9+16]        ; z2
        mul rax                 ;
        add rax, r10            ; rax = z1 * z2 + r10 (intermediate dot product)
        pop r9                  ; restore indices
        pop r8
        ret

; rdi = first edge
; rsi = second edge
; when dequeing, we want the smallest distance first
; compute DISTANCES[second] - DISTANCES[first]
compare_edges:
        mov rbx, [DISTANCES]    ; load distances pointer
        mov rax, [rbx + rdi*8]    ; load distance of second edge
        sub rax, [rbx + rsi*8]
        ret
