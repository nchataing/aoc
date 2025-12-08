section .text

%define PTR r12
%define LEN r13
%define HEAP_SIZE r14
%define CMP_PTR r15

global sort
global heap_push
global heap_pop

; @in rdi: pointer to the i64 array that needs sorting
; @in rsi: size of the array
; @in rdx: pointer to the compare function
;
; A heap is a binary tree with the property that each element is bigger than both of their children
; The child of a node at index i are store at index 2*i + 1 & 2*i + 2
sort:
        test rsi, rsi                       ; test length
        jne .a1                             ; if length > 0, proceed
        ret                                 ; empty array, nothing to do
.a1:    push r12                            ; save reg
        push r13                            ;
        push r14                            ;
        push r15                            ;
        mov LEN, rsi                        ; save length of the array in another reg
        mov PTR, rdi                        ; save pointer to the array
        mov CMP_PTR, rdx                    ; save pointer to compare function
        mov HEAP_SIZE, 1                    ; initial heap size is 1
.a:     cmp HEAP_SIZE, LEN                  ; while HEAP_SIZE < LEN
        jge .b                              ; done inserting all elements, now dequeue
        mov rdi, PTR                        ; prepare arguments for heap_push
        mov rsi, HEAP_SIZE                  ;
        mov rdx, CMP_PTR                    ;
        mov rcx, qword [PTR + HEAP_SIZE*8]  ; element to insert
        sub rsp, 8                          ; align stack
        call heap_push                      ;
        add rsp, 8                          ; restore stack
        inc HEAP_SIZE                       ; increase heap size
        jmp .a                              ; repeat
.b:     dec HEAP_SIZE                       ; dequeue all elements
        test HEAP_SIZE, HEAP_SIZE           ;
        je .c                               ; while HEAP_SIZE > 0
        mov rdi, PTR                        ; prepare arguments for heap_pop
        mov rsi, HEAP_SIZE                  ;
        mov rdx, CMP_PTR                    ;
        sub rsp, 8                          ; align stack
        call heap_pop                       ; pop max element (it is placed at the end of the array)
        add rsp, 8                          ; restore stack
        jmp .b
.c:     pop r15                             ; restore registers
        pop r14
        pop r13
        pop r12
        ret

; rdi: pointer to the i64 array in which to push an element
; rsi: size of the array (used as an index internally)
; rdx: pointer to the compare function
; rcx: element to push
heap_push:
        test rsi, rsi                   ; if size == 0
        jz .b                           ; insert
        push rsi                        ; save current index
        mov r8, rsi                     ; compute parent index in r8
        dec r8                          ;
        shr r8, 1                       ; parent index = (current index - 1) / 2
        push rdi                        ; save array pointer
        mov rsi, qword [rdi + r8*8]     ; parent value
        mov rdi, rcx                    ; element value
        sub rsp, 8                      ;
        call rdx                        ; compare
        add rsp, 8                      ;
        pop rdi                         ; restore array pointer
        mov r10, rsi                    ; parent value in r10
        pop rsi                         ; restore current index
        cmp rax, 0                      ; if new element <= parent
        jle .b                          ; stop and insert here
        mov qword [rdi + rsi*8], r10    ; else write parent value at current index
        mov rsi, r8                     ;
        jmp heap_push                   ; repeat with parent index
.b:     mov qword [rdi + rsi*8], rcx    ; place new element at its final position
        ret

; Registers used in heap_pop
%define ELT r8
%define LEFT r9
%define RIGHT r10
%define CHILD_IDX r11

; rdi: pointer to the i64 heap array from which to pop an element
; rsi: size of the heap
; rdx: pointer to the compare function
heap_pop:
        test rsi, rsi
        jnz .a                                  ; if heap not empty
        xor rax, rax                            ; heap empty, return 0
        ret                                     ; early exit
.a:     push r12                                ; save registers
        push r13                                ;
        mov CMP_PTR, rdx                        ; save compare function pointer
        mov PTR, rdi                            ;
        mov HEAP_SIZE, rsi                      ;
        mov ELT, qword [PTR + HEAP_SIZE*8]      ; get last element (value to bubble down)
        mov r9, qword [PTR]                     ; get root element
        mov qword [PTR + HEAP_SIZE*8], r9       ; place root at the end
        push r9                                 ; return value in rax
        xor rcx, rcx                            ; start at the root
.b:     mov CHILD_IDX, rcx                      ; compute left child index
        shl CHILD_IDX, 1                        ;
        inc CHILD_IDX                           ; 2*rcx + 1
        cmp CHILD_IDX, HEAP_SIZE                ; left child exists?
        jge .e                                  ; no children, we're done
        mov LEFT, qword [PTR + CHILD_IDX*8]     ; left child value
        inc CHILD_IDX                           ; 2*rcx + 2 (right child index)
        cmp CHILD_IDX, HEAP_SIZE                ;
        jl .c                                   ; right child?
        dec CHILD_IDX                           ; no, revert to left child index
        jmp .d                                  ; compare current value against it
.c:     mov RIGHT, qword [PTR + CHILD_IDX*8]    ; left & right exist, put biggest in (LEFT@CHILD_IDX)
        mov rdi, LEFT                           ; compare left & right
        mov rsi, RIGHT                          ;
        call CMP_PTR                            ;
        cmp rax, 0                              ; left <= right ?
        cmovl LEFT, RIGHT                       ; max(LEFT,RIGHT) in LEFT
        jl .d                                   ; CHILD_IDX already points to right child
        dec CHILD_IDX                           ; revert to left child index
.d:     mov rdi, ELT                            ; compare current value with biggest child
        mov rsi, LEFT                           ;
        call CMP_PTR                            ;
        cmp rax, 0                              ;
        jge .e                                  ; ELT > CHILD, heap property satisfied
        mov qword [PTR + rcx*8], LEFT           ; bubble up biggest child
        mov rcx, CHILD_IDX                      ; move down to child's index
        jmp .b                                  ; repeat
.e:     mov qword [PTR+rcx*8], ELT              ; place value at its final position
        pop rax                                 ; return value (pushed earlier when getting root)
        pop r13                                 ; restore values
        pop r12                                 ;
        ret                                     ;
