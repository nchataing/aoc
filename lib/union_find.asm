        global join
        extern print_unsigned

%include "lib/macros.asm"

        section .text

; rdi: pointer to union find array
; rsi: element to find root of
; rax: returns root of element & compress path
find_root:
        mov rdx, rsi
        shl rdx, 4                  ; rdx = rsi * 16
        mov rax, [rdi + rdx]        ; parent of element
        cmp rax, rsi                ; check if root
        jne .a
        ret                         ; root in rax
.a:     push rsi                    ; save rsi
        mov rsi, rax                ; move to parent
        call find_root              ; recursive call
        pop rsi                     ; restore rsi
        mov [rdi + rdx], rax        ; path compression
        ret

; rdi: pointer to union find array
; rsi: first element to join
; rdx: second element to join
join:
        push rdx                    ; save rdx
        call find_root              ; find root of rsi
        mov r8, rax                 ; save root1
        pop rsi                     ; restore rdx
        ALIGN call find_root        ; find root of rdx
        cmp r8, rax                 ; compare roots
        je .a
        shl rax, 4                  ; rax = root2 * 16
        mov [rdi + rax], r8         ; union: root2 -> root1
        add rax, 8                  ; point to size of root2
        shl r8, 4                   ; r8 = root1 * 16
        add r8, 8                   ; point to size
        mov rdx, [rdi + r8]         ; size of root1
        add rdx, [rdi + rax]        ; add size of root2
        mov [rdi + r8], rdx         ; update size of root1
        mov qword [rdi + rax], 0    ; size of root2 = 0
        mov rax, rdx                ; return new size
.a:     ret
