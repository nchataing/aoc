%macro EXIT 1
    mov rax, 60
    mov rdi, %1
    syscall
%endmacro

%macro READ_BYTE 2
    mov rax, 0          ; read
    mov al, [%1 + %2]
%endmacro

%macro ALIGN 1
        sub rsp, 8
        %1
        add rsp, 8
%endmacro

%macro PRINT 1
        push rax
        push rcx
        push rdx
        push rsi
        push rdi
        push r8
        push r9
        push r10
        push r11
        mov rdi, %1
        call print_unsigned
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rax
%endmacro
