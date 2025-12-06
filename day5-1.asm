        global _start
        extern print_unsigned
        extern read_stdin
        extern read_unsigned
        extern sort
        extern bsearch

%include "lib/macros.asm"

%define RESULT r13
%define NB_RANGES r14
%define INPUT_PTR r15

        section .bss
RANGES  resq 512            ; space for ranges (start,end) * 256
SORTED  resq 256            ; pointers to ranges
MERGED  resq 256            ; pointers to merged ranges
        section .text
_start:
        add rsp, 8
        call read_stdin
        sub rsp, 8
        mov INPUT_PTR, rax        ; base address of input
        mov NB_RANGES, 0

.read_ranges:
        movzx rax, byte [INPUT_PTR]
        cmp rax, 10                     ; newline
        je .read_finished
        mov rdi, INPUT_PTR
        mov rsi, '-'
        call read_unsigned
        mov rdi, NB_RANGES
        shl rdi, 4
        mov [RANGES+rdi], rax  ;
        add INPUT_PTR, rdx                  ; move pointer forward by number of bytes read
        inc INPUT_PTR                       ; skip '-'
        mov rdi, INPUT_PTR
        mov rsi, 10                         ; newline
        call read_unsigned
        mov rdi, NB_RANGES
        shl rdi, 4
        mov [RANGES+rdi+8], rax
        inc NB_RANGES
        add INPUT_PTR, rdx
        inc INPUT_PTR                       ; skip \n
        jmp .read_ranges
.read_finished:
        inc INPUT_PTR                       ; skip final newline

        ; build an array of pointers to the different ranges
        mov rcx, 0
.build_ptrs:
        cmp rcx, NB_RANGES
        jge .sort
        mov rax, rcx
        shl rax, 4
        add rax, RANGES
        mov [SORTED+rcx*8], rax
        inc rcx
        jmp .build_ptrs

.sort:
        mov rdi, SORTED
        mov rsi, NB_RANGES
        lea rdx, [rel cmp_ranges]
        call sort

; now that the ranges are sorted, we can merge them
        mov rcx, 0      ; first index in SORTED
        mov rdx, 1      ; second index in SORTED
        mov r8, 0       ; index in MERGED
.merge:

        mov rax, [SORTED+rcx*8]
        mov rdi, [rax+8]    ; end1
        mov rax, [SORTED+rdx*8]
        mov rsi, [rax]      ; start2
        cmp rdi, rsi
        jl .no_overlap
        ; there is an overlap merge the two ranges
        ; end1 <- max(end1, end2)
        mov rax, [SORTED+rdx*8]     ; ptr to range 2
        mov rdi, [rax+8]            ; end2
        mov rax, [SORTED+rcx*8]     ; ptr to range 1
        mov rsi, [rax+8]            ; end1
        cmp rdi, rsi
        cmovl rdi, rsi              ; rdi = max(end1, end2)
        mov [rax+8], rdi            ; update end1
        inc rdx
        cmp rdx, NB_RANGES
        jl .merge
        ; copy last range to MERGED
        mov rax, [SORTED+rcx*8]
        mov [MERGED+r8*8], rax
        inc r8
        jmp .merge_end
.no_overlap:
        ; no overlap, copy range1 addr to MERGED
        mov rax, [SORTED+rcx*8]
        mov [MERGED+r8*8], rax
        inc r8
        mov rcx, rdx
        inc rdx
        cmp rdx, NB_RANGES
        jl .merge
        ; copy last range
        mov rax, [SORTED+rcx*8]
        mov [MERGED+r8*8], rax
        inc r8
.merge_end:

        mov RESULT, 0                       ; part 2 result
        mov rcx, 0
.print_ranges:
        mov NB_RANGES, r8
        mov rax, [MERGED+rcx*8]
        mov rdx, [rax]
        sub RESULT, rdx
        ;PRINT rdx
        mov rdx, [rax+8]
        add RESULT, rdx
        inc RESULT                          ; include end value
        ;PRINT rdx
        inc rcx
        cmp rcx, NB_RANGES
        jl .print_ranges

        PRINT RESULT
        mov RESULT, 0
.check_ids:
        movzx rax, byte [INPUT_PTR]         ; if current char is...
        cmp rax, 0                          ; ...newline, then...
        je .exit                            ; ...we are done
        mov rdi, INPUT_PTR                  ; read input...
        mov rsi, 10                         ; ...until newline
        call read_unsigned                  ; it's a number
.b:     add INPUT_PTR, rdx                  ; move input pointer
        inc INPUT_PTR                       ; skip newline
        mov rdi, rax                        ; value to search
        mov rsi, MERGED                     ; array of merged ranges
        mov rdx, NB_RANGES                  ; number of ranges
        lea rcx, [rel cmp_into_range]       ; comparison function
        call bsearch                        ; perform search
        test rax, rax                       ; if rax == 0
        jnz .cont                           ; not found
       ;PRINT rdi                           ; print found ID
        inc RESULT                          ; increment nb of found IDs
.cont:  jmp .check_ids                      ; loop
.exit:  PRINT RESULT                        ; print result
        EXIT 0                              ; exit program

cmp_ranges:
        ; rdi = ptr to range 1 ( start1, end1 )
        ; rsi = ptr to range 2 ( start2, end2 )
        ; return rax = start1 - start2
        push rbx
        mov rax, [rdi]
        mov rbx, [rsi]
        sub rax, rbx
        pop rbx
        ret

cmp_into_range:
        ; rdi = value to search
        ; rsi = ptr to range ( start, end )
        ; return rax <0 if value < start
        ;            =0 if start <= value <= end
        ;            >0 if value > end
        mov rax, [rsi]
        cmp rdi, rax
        jl .l
        mov rax, [rsi+8]
        cmp rdi, rax
        jg .g
        mov rax, 0
        ret
.l:     mov rax, -1
        ret
.g:     mov rax, 1
        ret
