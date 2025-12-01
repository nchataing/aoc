        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern sort
        extern bsearch

%include "lib/macros.asm"

%define OUT 0x6f757400000000    ; "\0out\0\0\0\0"
%define YOU 0x796f7500000000    ; "\0you\0\0\0\0"
%define SVR 0x73767200000000    ; "\0svr\0\0\0\0"
%define FFT 0x66667400000000    ; "\0fft\0\0\0\0"
%define DAC 0x64616300000000    ; "\0dac\0\0\0\0"

        section .bss
%define ADJ_LEN 30
GRAPH resd 1000 * ADJ_LEN   ; for each vert x: &GRAPH[ADJ_LEN*x] represents the list of adjacent nodes (prefixed by its length)
VERTS resq 1000             ; [0sssxxxx] -> sss is the input string, xxxx is the input line
NB_VERTS resq 1
YOU_IDX resq 1
SVR_IDX resq 1
FFT_IDX resq 1
DAC_IDX resq 1

%macro FIND_TAG_IDX 2
        mov rdi, %1
        ALIGN call find_tag_idx
        mov [%2], rax
        ;PRINT [%2]
%endmacro

%macro TRAVERSE 2
        ALIGN call reset_verts          ; reset vertices for traversal
        mov rdi, %1                     ; start %1
        mov rsi, %2                     ; target %2
        ALIGN call traverse             ; compute nb of paths from %1 to %2
        ;PRINT rax
%endmacro


        section .text
_start:
        ALIGN call read_stdin           ; read input
        mov r15, rax                    ; input
        mov qword [NB_VERTS], 1         ; reserve index 0 for out
        mov rax, OUT                    ;
        mov [VERTS], rax                ;
.a:     ALIGN call parse_line
        mov al, [r15]
        test al, al                     ; 0 means we reached the end
        jnz .a
        mov rdi, VERTS
        mov rsi, [NB_VERTS]
        lea rdx, [rel cmp_tags]
        ALIGN call sort
        ALIGN call postprocess
        FIND_TAG_IDX YOU, YOU_IDX
        FIND_TAG_IDX FFT, FFT_IDX
        FIND_TAG_IDX DAC, DAC_IDX
        FIND_TAG_IDX SVR, SVR_IDX

        ; part 1
        TRAVERSE [YOU_IDX], 0
        PRINT rax

        ; compute paths SVR -> FFT -> DAC -> OUT
        TRAVERSE [SVR_IDX], [FFT_IDX]
        mov rbx, rax
        TRAVERSE [FFT_IDX], [DAC_IDX]
        mul rbx
        mov rbx, rax
        TRAVERSE [DAC_IDX], 0
        mul rbx
        push rax

        ; compute paths SVR -> DAC -> FFT -> OUT
        TRAVERSE [SVR_IDX], [DAC_IDX]
        mov rbx, rax
        TRAVERSE [DAC_IDX], [FFT_IDX]
        mul rbx
        mov rbx, rax
        TRAVERSE [FFT_IDX], 0
        mul rbx
        mov rbx, rax
        pop rax
        add rax, rbx
        PRINT rax
        EXIT 0
.d:     EXIT 1                          ; error: initial node "you" not found


%macro PARSE_TAG 0
        mov rax, 0
        mov al, [r15]
        shl rax, 8
        mov al, [r15+1]
        shl rax, 8
        mov al, [r15+2]
        add r15, 3
%endmacro

parse_line:
        mov rdx, [NB_VERTS]             ;
        PARSE_TAG                       ;
        shl rax, 32                     ;
        add rax, rdx                    ; add current index
        mov [VERTS+rdx*8], rax          ;
        mov r8, rdx
        imul r8, ADJ_LEN*4              ; r8 = offset in GRAPH
        add r8, GRAPH                   ; r8 = &GRAPH[ADJ_LEN*rdx]
        inc r15                         ; skip over ':'
        mov rcx, 0                      ; number of elements
.a:     movzx rax, byte [r15]           ; fetch next byte
        cmp rax, 10                     ; while no newline
        je .b                           ;
        inc rcx                         ; increment now so that &r8[rcx] points to the tag to write
        inc r15                         ; skip over ' '
        PARSE_TAG                       ; parse
        mov [r8+rcx*4], eax             ; write tag
        jmp .a                          ;
.b:     inc r15                         ; skip over newline
        mov [r8], ecx                   ; write length
        inc rdx                         ; increment & write number of nodes
        mov [NB_VERTS], rdx             ;
        ret

postprocess:
        mov rcx, 0                      ;
.a:     cmp rcx, [NB_VERTS]             ; loop over all vertices
        jge .d                          ;
        ;PRINT rcx
        mov r8, rcx                     ;
        imul r8, ADJ_LEN*4              ;
        add r8, GRAPH                   ; r8 = &GRAPH[ADJ_LEN*rcx]
        mov r9d, dword [r8]             ; length of adjacency list
        add r8, 4                       ;
        mov r10, 0                      ; index in adjacency list
.b:     cmp r10, r9                     ; loop over adjacency list
        jge .c                          ; continue to next vertex
        mov eax, dword [r8+r10*4]       ; get tag
        ;PRINT rax
        shl rax, 32                     ; put in high part
        mov rdi, rax                    ;
        mov rsi, VERTS                  ;
        mov rdx, [NB_VERTS]             ;
        push rcx                        ;
        lea rcx, [rel cmp_tags]         ;
        call bsearch                    ;
        pop rcx                         ;
        ;cmp rax, -1                     ; not found?
        ;je .e                           ;
        shl rax, 32                     ;
        shr rax, 32                     ;
        mov [r8+r10*4], eax             ; replace tag with index
        inc r10
        jmp .b
.c:     inc rcx
        jmp .a
.d:     ret
.e:     EXIT 1                          ; error: tag not found

cmp_tags:
        mov rax, rdi
        mov rbx, rsi
        shr rax, 32                     ; get tag part
        shr rbx, 32                     ;
        sub rax, rbx
        ret

; find index for tag in rdi
find_tag_idx:
        mov rsi, VERTS                  ;
        mov rdx, [NB_VERTS]             ;
        lea rcx, [rel cmp_tags]         ;
        ALIGN call bsearch              ; search for vertex "you"
        cmp rax, -1                     ; not found?
        je .a                           ;
        shl rax, 32                     ;
        shr rax, 32                     ; return index
        ret
.a:     EXIT 1


; prepare VERTS array for a traversal
reset_verts:
        mov rcx, 0                      ;
.a:     cmp rcx, [NB_VERTS]             ;
        jge .b                          ;
        mov qword [VERTS+rcx*8], -1     ; VERTS array now that we have build the graph
        inc rcx                         ;
        jmp .a                          ;
.b:     ret


; rdi: starting node index
; rsi: target node index
; VERTS[rdi]: number of paths from node to "out", 0 = unvisited, -1 = currently being visited
; if we find a node being currently visited, we have a cycle -> PRINT 42 & EXIT 1
traverse:
        cmp rdi, rsi                    ; test recursion base case
        jne .0                          ;
        mov rax, 1                      ; base case, one path from target to itself
        ret
.0:     mov rax, [VERTS+rdi*8]          ;
        cmp rax, -1                     ; already visited?
        jne .c                          ; yes, directly return
        mov rcx, 0                      ; sum of paths from neighbors
        mov r8, rdi                     ;
        imul r8, ADJ_LEN*4              ;
        add r8, GRAPH                   ; r8 = &GRAPH[ADJ_LEN*rdi]
        mov r9d, dword [r8]             ; length of adjacency list
        add r8, 4                       ; skip length
        mov r10, 0                      ; index in adjacency list
.a:     cmp r10, r9                     ; loop over adjacency list
        jge .b                          ;
        mov eax, dword [r8+r10*4]       ; get neighbor index
        push rcx                        ; save sum
        push r8
        push r9
        push r10
        push rdi
        mov rdi, rax                    ;
        call traverse                   ;
        pop rdi
        pop r10
        pop r9
        pop r8
        pop rcx                         ; restore sum
        add rcx, rax                    ; add paths from neighbor
        inc r10                         ;
        jmp .a                          ; loop
.b:     mov [VERTS+rdi*8], rcx          ; store number of paths from this node
        mov rax, rcx                    ; return number of paths
.c:     ;PRINT rdi
        ;PRINT r9
        ;PRINT rax
        ret
