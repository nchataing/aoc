        global print_unsigned
        global read_stdin
        global read_unsigned

        extern alloc

        section .bss
buffer resb 32

        section .text

; allocate 1MB stack space to read input buffer
; return pointer in rax, length in rdx
read_stdin:
        mov rdi, 1024*1024              ; 1MB
        sub rsp, 8                      ; align stack
        call alloc                      ; allocate buffer
        add rsp, 8                      ; restore stack
        mov r8, rax                     ; save base pointer
        mov rax, 0                      ; read syscall
        mov rdi, 0                      ; stdin
        mov rsi, r8                     ; buffer to read into
        mov rdx, 1024*1024              ; max size to read
        syscall                         ;
        mov byte [rbx+rax], 0           ; make sure length is null-terminated
        mov rdx, rax                    ; length in rdx
        mov rax, r8                     ; pointer in rax
        ret

; @in rdi: buffer to read from
; @out rax: number read (we assume input holds on u64, no overflow check)
; @out rdx: number of bytes read
read_unsigned:
        mov rax, 0                      ; result
        mov rdx, 0                      ; byte count
.loop:  movzx rcx, byte [rdi + rdx]     ; read byte
        cmp rcx, '0'                    ; stop if character is not between '0' and '9'
        jl .done                        ;
        cmp rcx, '9'                    ;
        jg .done                        ;
        sub rcx, '0'                    ; convert ASCII to digit
        imul rax, 10                    ; rax = rax * 10
        add rax, rcx                    ; rax = rax + digit
        inc rdx                         ; move to next byte
        jmp .loop                       ; repeat
.done:  ret

; rdi is the number to print, followed by a line break
print_unsigned:
        push rbx
        add rsp, 8
        ; Check if the number is zero
        cmp rdi, 0
        jne .convert_number

        ; If zero, write '0' and newline
        mov byte [buffer], '0'
        mov byte [buffer + 1], 10  ; newline

        ; write syscall
        mov rax, 1
        mov rdi, 1
        mov rsi, buffer
        mov rdx, 2
        syscall
        jmp .ret

.convert_number:
        mov byte [buffer + 31], 10   ; newline character at the end of the buffer
        mov rsi, buffer + 30        ; pointer to the end of the buffer
        mov rax, rdi                ; work on rax
        mov rbx, 10                 ; divide by 10
.convert_loop:
        xor rdx, rdx
        div rbx                     ; rax = rax / 10, rdx = rax % 10
        add rdx, '0'                ; convert remainder to ASCII
        mov byte [rsi], dl
        dec rsi
        test rax, rax
        jnz .convert_loop

        ; write syscall
        inc rsi
        mov rax, 1
        mov rdi, 1
        ; rsi is already set
        mov rdx, buffer + 32
        sub rdx, rsi
        syscall

.ret:
        sub rsp, 8
        pop rbx
        ret
