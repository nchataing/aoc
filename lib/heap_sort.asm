section .text

global sort

; rdi: pointer to the i64 array that needs sorting
; rsi: size of the array

; use an in-place heap sort algorithm
sort:
    test rsi, rsi
    jne .heapify
    ret

.heapify:
    ; a heap is a binary tree with the property that each element
    ; is bigger than both of their children
    ; the child of a node at index i are store at index 2*i + 1 & 2*i + 2
    ; store the size of the heap in rax
    ; we start with a heap comprised of one element
    mov rax, 1

.insert_one_elt:
    mov rcx, rax
    mov r8, qword [rdi + rcx*8]     ; store value of the current element to insert
    ; bubble up the new element to restore heap property
.bubble_up_one_elt:
    test rcx, rcx
    jz .inserted
    mov rdx, rcx
    dec rdx
    shr rdx, 1                      ; parent index = current index / 2
    mov r9, qword [rdi + rdx*8]     ; parent value
    cmp r8, r9
    jle .inserted
    mov qword [rdi + rcx*8], r9     ; bubble down parent value
    mov rcx, rdx                    ; continue with parent index
    jmp .bubble_up_one_elt
.inserted:
    mov qword [rdi + rcx*8], r8     ; place new element at its final position
    inc rax
    cmp rax, rsi
    jl .insert_one_elt

.dequeue:
    ; now dequeue elements one by one
    ; swap the root of the heap (biggest element) with the last element
    dec rax
    test rax, rax
    je .end
    mov r8, qword [rdi + rax*8]     ; get last element
    mov rdx, qword [rdi]            ; get root element
    mov qword [rdi + rax*8], rdx    ; place root at the end
    ; value to bubble down is in r8
    xor rcx, rcx                    ; start at the root
.bubble_down:
    ; get value of left & right children
    mov rbx, rcx
    shl rbx, 1
    inc rbx
    cmp rbx, rax
    jge .placed                     ; no children, we're done
    mov r9, qword [rdi + rbx*8]     ; left child
    inc rbx
    cmp rbx, rax
    jl .choose_bigger_child         ; no right child
    dec rbx                         ; revert to left child index
    jmp .compare_with_biggest_child

.choose_bigger_child:
    mov r10, qword [rdi + rbx*8]    ; right child
    cmp r9, r10
    cmovl r9, r10                   ; right is bigger
    jl .compare_with_biggest_child
    dec rbx                         ; revert to left child index

.compare_with_biggest_child:
    ; r9 = value of biggest child
    ; rbx = index of biggest child
    cmp r8, r9
    jge .placed                     ; heap property satisfied
    ; swap with biggest child
    mov qword [rdi + rcx*8], r9
    mov rcx, rbx
    jmp .bubble_down


.placed:
    mov qword [rdi+rcx*8], r8       ; place value at its final position
    jmp .dequeue

.end:
    ret
