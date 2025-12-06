section .text

%define PTR r8
%define LEN r9
%define HEAP_SIZE r10
%define CMP_PTR r11

; different names depending on the context
%define ELT rdi
%define PARENT rsi
%define LEFT rsi
%define RIGHT rdx
%define CHILD_IDX rbx

global sort

; rdi: pointer to the i64 array that needs sorting
; rsi: size of the array
; rdx: pointer to the compare function

; use an in-place heap sort algorithm
sort:
    test rsi, rsi
    jne .heapify
    ret

.heapify:
    push r8
    push r9
    push r10
    push r11

    mov PTR, rdi
    mov LEN, rsi
    mov CMP_PTR, rdx

    ; a heap is a binary tree with the property that each element
    ; is bigger than both of their children
    ; the child of a node at index i are store at index 2*i + 1 & 2*i + 2
    ; store the size of the heap in r12 (HEAP_SIZE)
    ; we start with a heap comprised of one element
    mov HEAP_SIZE, 1

.insert_one_elt:
    mov rcx, HEAP_SIZE
    mov ELT, qword [PTR + rcx*8]     ; store value of the current element to insert
    ; bubble up the new element to restore heap property
.bubble_up_one_elt:
    test rcx, rcx
    jz .inserted
    mov rdx, rcx
    dec rdx
    shr rdx, 1                      ; parent index = (current index - 1) / 2
    mov rsi, qword [PTR + rdx*8]    ; parent value
    call CMP_PTR
    cmp rax, 0
    jle .inserted
    mov qword [PTR + rcx*8], rsi    ; bubble down parent value
    mov rcx, rdx                    ; continue with parent index
    jmp .bubble_up_one_elt
.inserted:
    mov qword [PTR + rcx*8], ELT     ; place new element at its final position
    inc HEAP_SIZE
    cmp HEAP_SIZE, LEN
    jl .insert_one_elt

.dequeue:
    ; now dequeue elements one by one
    ; swap the root of the heap (biggest element) with the last element
    dec HEAP_SIZE
    test HEAP_SIZE, HEAP_SIZE
    je .end
    mov ELT, qword [PTR + HEAP_SIZE*8]     ; get last element
    mov rdx, qword [PTR]                   ; get root element
    mov qword [PTR + HEAP_SIZE*8], rdx     ; place root at the end
    ; value to bubble down is in ELT
    xor rcx, rcx                    ; start at the root
.bubble_down:
    ; get value of left & right children
    mov CHILD_IDX, rcx
    shl CHILD_IDX, 1
    inc CHILD_IDX
    cmp CHILD_IDX, HEAP_SIZE
    jge .placed                      ; no children, we're done
    mov LEFT, qword [PTR + CHILD_IDX*8]     ; left child
    inc CHILD_IDX
    cmp CHILD_IDX, HEAP_SIZE
    jl .choose_bigger_child         ; no right child
    dec CHILD_IDX                         ; revert to left child index
    jmp .compare_with_biggest_child

.choose_bigger_child:
    mov RIGHT, qword [PTR + CHILD_IDX*8]    ; right child
    push rdi
    push rsi
    mov rdi, LEFT
    mov rsi, RIGHT
    call CMP_PTR
    pop rsi
    pop rdi
    cmp rax, 0                      ; left <= right ?
    cmovl LEFT, RIGHT               ; right is bigger
    jl .compare_with_biggest_child
    dec CHILD_IDX                         ; revert to left child index

.compare_with_biggest_child:
    ; LEFT = value of biggest child
    ; CHILD_IDX = index of biggest child
    ; ELT = rdi, LEFT = rsi, already the right convention for CMP_PTR
    call CMP_PTR
    cmp rax, 0
    jge .placed                     ; heap property satisfied
    ; swap with biggest child
    mov qword [PTR + rcx*8], LEFT   ; bubble up biggest child
    mov rcx, CHILD_IDX
    jmp .bubble_down

.placed:
    mov qword [PTR+rcx*8], ELT      ; place value at its final position
    jmp .dequeue

.end:
    pop r11
    pop r10
    pop r9
    pop r8

    ret
