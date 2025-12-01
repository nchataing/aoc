        global _start
        extern print_unsigned
        extern read_unsigned
        extern read_stdin
        extern sort
        extern bsearch

%include "lib/macros.asm"

%define MAX_BUTTONS 13
%define MAX_LIGHTS 16

        section .bss
INDICATOR resq 1
NB_BUTTONS resb 1
BUTTONS resq MAX_BUTTONS
CONFIGS resq 8192       ; 2^13 = 8192
REQS resq MAX_LIGHTS
PART1 resq 1
PART2 resq 1

        section .text
_start:
        ALIGN call read_stdin           ; read input
        mov r15, rax                    ; input
        mov qword [PART1], 0
        mov qword [PART2], 0
.a1:    cmp byte [r15], 0
        je .a2
        xor rcx, rcx
.b1:    cmp rcx, MAX_LIGHTS
        jge .b2
        mov qword [REQS + rcx*8], 0
        inc rcx
        jmp .b1
.b2:
        ALIGN call parse_line
        ALIGN call part1_and_memo
        mov rbx, [PART1]
        add rbx, rax
        mov [PART1], rbx
        mov rdi, REQS
        ALIGN call part2
        mov rbx, [PART2]
        add rbx, rax
        mov [PART2], rbx
        PRINT rax
        jmp .a1
.a2:    PRINT qword [PART1]
        PRINT qword [PART2]
        EXIT 0

parse_indicator:
        inc r15                 ; skip '['
        mov rax, 0              ; result
        mov rdx, 1              ; power of 2
.a:     mov bl, [r15]           ;
        cmp bl, ']'             ;
        je .c                   ; finished
        cmp bl, '.'             ;
        je .b                   ;
        add rax, rdx            ; add current pow of 2 to result
.b:     shl rdx, 1              ; shift and loop
        inc r15                 ;
        jmp .a                  ;
.c:     inc r15                 ; skip over ']'
        ret                     ;

parse_button:
        xor rax, rax                ; button base 2 repr
.a:     mov bl, [r15]
        cmp bl, ')'                 ; while next character != )
        je .e                       ;
        inc r15                     ; skip ','
        push rax                    ; save context
        mov rdi, r15                ;
        call read_unsigned          ; read next number
        add r15, rdx                ; advance stream
        mov rdx, 1                  ;
        mov rcx, rax                ;
        shl rdx, cl                 ;
        pop rax                     ;
        add rax, rdx                ;
        jmp .a                      ;
.e:     ret

parse_reqs:
        movzx r8, byte [NB_BUTTONS] ; reset requirements
        xor rcx, rcx                ; button counter
.a1:    cmp rcx, r8
        jge .a2
        mov qword [REQS+rcx*8], 0
        inc rcx
        jmp .a1
.a2:    xor rcx, rcx
.b1:    mov bl, [r15]
        cmp bl, '}'                 ;
        je .b2                      ;
        inc r15                     ; skip ',' or initial '{'
        mov rdi, r15                ;
        push rcx
        call read_unsigned          ; read requirement
        pop rcx
        mov [REQS+rcx*8], rax       ; store requirement
        add r15, rdx                ; advance stream
        inc rcx                     ;
        jmp .b1                     ;
.b2:    inc r15                     ; skip '}'
        ret

parse_line:
        ALIGN call parse_indicator  ;
        mov qword [INDICATOR], rax  ;
        inc r15                     ;
        xor rcx, rcx                ; button counter
.a1:    mov bl, [r15]               ;
        cmp bl, '{'                 ;
        je .a2                      ;
        push rcx                    ;
        call parse_button           ;
        pop rcx                     ;
        mov qword [BUTTONS + rcx*8], rax ; store button
        inc rcx                     ;
        add r15, 2                  ; skip over ') '
        jmp .a1
.a2:    mov [NB_BUTTONS], cl
        ALIGN call parse_reqs
        inc r15                     ; skip over '{'
        ret

part1_and_memo:
        movzx r10, byte [NB_BUTTONS]
        mov cl, [NB_BUTTONS]        ; number of buttons
        mov rax, 1                  ;
        shl rax, cl                 ; 2^nb_buttons
        dec rax                     ; max combination
        mov rcx, rax                ; combination counter
.a1:    mov rdi, rcx
        push rcx
        call compute_config
        pop rcx
        mov [CONFIGS + rcx*8], rax  ; memoize config
        cmp rax, [INDICATOR]
        jne .a2
        popcnt rax, rcx
        cmp rax, r10
        cmovl r10, rax
.a2:    dec rcx
        cmp rcx, 0
        jne .a1
        mov rax, r10
        ret


; rdi = buttons that need to be pressed (i-th button is pressed if i-th bit is 1)
; rax = light indicator for the pressed buttons
compute_config:
        xor rax, rax                ; light indicator
        xor rcx, rcx                ; button index
.a0:    mov r9, rdi                 ;
        and r9, 1                   ; check if button is pressed
        cmp r9, 1                   ; if pressed
        jne .a1                     ;
        mov r9, [BUTTONS + rcx*8]   ; get button
        xor rax, r9                 ; update light indicator
.a1:    inc rcx                     ; button index
        shr rdi, 1                  ; shift to next button
        cmp rcx, [NB_BUTTONS]       ;
        jge .e                      ; finished
        jmp .a0                     ; loop
.e:     ret


; rdi = pointer to current requirements
part2:
        push rdi
        call get_target_config
        mov r14, rax                ; target config for this recursive call
        mov r13, 10000              ; min buttons pressed (large number for now)
        movzx r10, byte [NB_BUTTONS]
        mov cl, [NB_BUTTONS]        ; number of buttons
        mov rax, 1                  ;
        shl rax, cl                 ; 2^nb_buttons
        dec rax                     ; max combination
        mov rcx, rax                ; combination counter
.a1:    pop rdi
        push rdi
        mov rdx, rcx
        mov rax, [CONFIGS + rcx*8]
        cmp rax, r14                ; check if pressed buttons yield target config
        jne .a2
        popcnt r9, rcx              ; count number of pressed buttons
        push rcx
        push r9
        push r14
        push r13
        sub rsp, 8 * MAX_LIGHTS     ; allocate space on stack for recursive calls
        mov rsi, rsp                ; pointer to new requirements
        ALIGN call copy_reqs        ; copy current to new
        mov rdi, rsi                ;
        mov rsi, rdx
        call substract_button_reqs ; substract pressed button requirements
        ALIGN call div_reqs_by_2_and_recurse ; recurse
        add rsp, 8 * MAX_LIGHTS     ; deallocate stack space
        pop r13
        pop r14
        pop r9
        pop rcx
        add rax, r9                 ; 2 * #buttons pressed in recursive call + #buttons pressed now
        cmp rax, r13                ; check if new min
        cmovl r13, rax              ; update min
.a2:    dec rcx
        cmp rcx, 0
        jge .a1
        mov rax, r13                ; return min buttons pressed
        pop rdi
        ret

copy_reqs:
        xor rcx, rcx
.a0:    cmp rcx, MAX_LIGHTS         ; copy current requirements to new requirements
        jge .a1                     ;
        mov rax, qword [rdi+rcx*8]  ;
        mov qword [rsi+rcx*8], rax  ;
        inc rcx                     ;
        jmp .a0                     ;
.a1:    ret                         ;

print_reqs:
        xor rcx, rcx
.a0:    cmp rcx, MAX_LIGHTS         ; copy current requirements to new requirements
        jge .a1                     ;
        PRINT [rdi+rcx*8]           ;
        inc rcx                     ;
        jmp .a0                     ;
.a1:    ret                         ;


; rdi = pointer to current requirements
; rsi = set of pressed buttons
substract_button_reqs:
        xor rcx, rcx                ; button index
.b0:    mov r9, rsi                 ;
        and r9, 1                   ; check if button is pressed
        cmp r9, 1                   ; if pressed
        jne .b1                     ;
        push rsi
        push rcx
        mov rsi, [BUTTONS + rcx*8]  ; get button
        ALIGN call substract_one_button
        pop rcx
        pop rsi
.b1:    inc rcx                     ; button index
        shr rsi, 1                  ; shift to next button
        cmp rcx, [NB_BUTTONS]       ;
        jge .b2                     ; finished
        jmp .b0                     ; loop
.b2:    ret

; rdi = pointer to current requirements
div_reqs_by_2_and_recurse:
        xor rcx, rcx                ; check if any requirement is negative and divide by 2
        xor rax, rax                ; result status
.c0:    cmp rcx, MAX_LIGHTS         ;
        jge .c2
        mov r8, qword [rdi+rcx*8]   ; get requirement
        cmp r8, 0                   ;
        jl .imp                     ; if negative, impossible
        jz .c1
        or rax, 1                   ; at least one requirement > 0
.c1:    shr r8, 1                   ; divide requirement by 2
        mov qword [rdi+rcx*8], r8   ; store new requirement
        inc rcx
        jmp .c0
.c2:    cmp rax, 0                  ; all requirements are 0?
        je .end                     ; if yes, done
        ALIGN call part2            ; recurse with new requirements
        shl rax, 1                  ; multiply result by 2
.end:   ret
.imp:   mov rax, 10000              ; dead-end => return large number
        ret

; rdi = pointer to requirements to update with button press
; rsi = pressed button
substract_one_button:
        xor rcx, rcx                ; button counter
        mov r8, 1                   ; button mask
.a1:    cmp rcx, MAX_LIGHTS         ;
        jge .a3
        mov rax, rsi
        and rax, r8                 ; check if button affects this light
        test rax, rax               ;
        jz .a2
        mov rax, qword [rdi+rcx*8]  ; get current requirement
        dec rax                     ; decrease requirement
        mov [rdi+rcx*8], rax        ; store new requirement
.a2:    inc rcx
        shl r8, 1                   ; shift button mask
        jmp .a1
.a3:    ret



; rdi = pointer to current requirements
get_target_config:
        xor rcx, rcx            ; counter
        mov rax, 0              ; result
        mov rdx, 1              ; power of 2
.a1:    cmp rcx, MAX_LIGHTS
        jge .a3
        mov r8, [rdi+rcx*8]
        and r8, 1               ; check if requirement is odd
        cmp r8, 1               ;
        jne .a2
        add rax, rdx            ; add current power of 2 to target config
.a2:    shl rdx, 1              ; shift power of 2
        inc rcx                 ; inc counter
        jmp .a1                 ; loop
.a3:    ret
