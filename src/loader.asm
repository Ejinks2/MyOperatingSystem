org 0x1000
bits 16

%define ENDL 0x0D, 0x0A

global _start

puts:
    push si
    push ax
    push bx

.loop:
    lodsb                   ; Load byte (next character) in al
    or al, al               ; Check if it's the null terminator
    jz .done                ; If zero, we've reached the end of the string

    mov ah, 0x0E            ; BIOS teletype function
    mov bh, 0x00            ; Page number (0)
    int 0x10                ; Call BIOS video interrupt

    jmp .loop               ; Repeat for the next character

.done:
    pop bx
    pop ax
    pop si
    ret

_start:
    cli                     ; Disable interrupts for safety
    
    ; Print startup message
    mov si, loader_start_msg
    call puts
    
    ; Print the alphabet (A-Z)
    mov cx, 26              ; 26 letters
    mov al, 0x41            ; Starting with 'A' (0x41)

.print_loop:
    mov ah, 0x0E            ; BIOS teletype function
    mov bh, 0x00            ; Page number
    int 0x10                ; Print character
    
    inc al                  ; Next character
    loop .print_loop
    
    ; Print newline
    mov ah, 0x0E
    mov al, 0x0D            ; Carriage return
    int 0x10
    mov al, 0x0A            ; Line feed
    int 0x10
    
    ; Print done message
    mov si, loader_done_msg
    call puts
    
    ; Halt
    cli
    hlt

loader_start_msg: db "Loader started!", ENDL, 0
loader_done_msg: db "Loader finished!", ENDL, 0