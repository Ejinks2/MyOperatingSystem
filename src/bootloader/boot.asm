org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

_start:
    jmp main                ; Jump to the main function

; prints string to screen
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

main:                       
    ; Setting up segments, stack and other registers.
    xor ax, ax              ; Clear ax
    mov ds, ax              ; Set data segment to 0
    mov es, ax              ; Set extra segment to 0
    
    mov ss, ax
    mov sp, 0x7C00          ; Set stack pointer to the end of the boot sector

    ; Print startup message
    mov si, startup_msg
    call puts

    mov bx, 0x1000          ; Set BX to the offset where we want to load the next stage

    call disk_read          ; Call the disk read function to load the next stage

    ; Setup segment registers for the secondary bootloader
    mov ax, 0x0000
    mov es, ax
    mov ds, ax

    ; Print message before jumping to stage 2
    mov si, jump_msg
    call puts

    call 0x1000             ; Jump to the next stage (Bootloader Stage 2)
    jmp $                   ; Infinite loop to prevent falling through

    mov si, msg
    call puts               ; Print the message

    mov si, goodbye_msg
    call puts               ; Print goodbye message

    cli                     ; Clear interrupts
    hlt                     ; Halt the CPU

.halt:
    jmp .halt               ; Infinite loop to keep the CPU halted


disk_read:
    pusha
    push dx
    
    ; Physical 0x1000, so let's use ES=0, BX=0x1000
    xor ax, ax
    mov es, ax              ; ES = 0
    mov bx, bx              ; BX should already be 0x1000 from caller

    ; Load Bootloader Stage 2 from Disk
    mov ah, 0x02            ; BIOS read sector function
    mov al, 1               ; Number of sectors to read (1 sector = 512 bytes)
    mov ch, 0x00            ; Cylinder 0
    mov cl, 0x02            ; Sector 2 (bootloader is sector 1, loader is sector 2)
    mov dh, 0x00            ; Head 0
    mov dl, 0x80            ; Load the boot drive number
    
    mov si, disk_attempt_msg
    call puts               ; Print attempt message
    
    int 0x13                ; Call BIOS disk interrupt

    ; Check for read error
    jc .disk_error

    ; Verify we read something valid (check for common signatures)
    cmp byte [es:bx], 0x55  ; Check if first byte looks reasonable
    je .read_success
    
    ; If not, print warning but continue
    mov si, disk_warn_msg
    call puts
    
.read_success:
    mov si, test_msg
    call puts               ; Print test message to confirm we read from disk

    pop dx
    cmp al, 1
    jne .disk_error         ; If we didn't read the expected number of sectors, it's an error

    popa
    ret

.disk_error:
    ; Print error message and halt
    mov si, disk_error_msg
    call puts
    cli
    hlt

.halt:
    jmp .halt

msg:	db "Hello World!", ENDL, 0   ; Our actual message to print
goodbye_msg: db "Goodbye!", ENDL, 0
disk_error_msg: db "Disk read error!", ENDL, 0
test_msg: db "Did we make it here?", ENDL, 0
startup_msg: db "Bootloader starting...", ENDL, 0
jump_msg: db "Jumping to stage 2...", ENDL, 0
disk_attempt_msg: db "Attempting disk read...", ENDL, 0
disk_warn_msg: db "Warning: Unexpected data read!", ENDL, 0
BOOT_DRIVE: db 0                     ; Variable to store the boot drive number


; Remainder of the 445 bytes of boot sector code
times 445 - ($ - $$) db 0

; Primary Partition Table
; Each partition entry is 16 bytes, and there are 4 entries (64 bytes total)
db 0x80                     ; Boot Indicator (0x80 = bootable)
db 0x01, 0x01, 0x00         ; Starting CHS (Head 1, Sector 1, Cylinder 0)
db 0x0B                     ; Partition Type (0x0B = FAT32)
db 0x10, 0x3F, 0x44         ; Ending CHS (Head 16, Sector 63, Cylinder 68)
dd 0x00000000               ; Starting LBA (0 for the first partition)
dd 0x0001F000               ; Total Sectors (126976 sectors, 62 MB)

times 16 db 0                     ; Partition 2 (16 bytes)
times 16 db 0                     ; Partition 3 (16 bytes)
times 16 db 0                     ; Partition 4 (16 bytes)

times 510 - ($ - $$) db 0   ; Fill the rest of the boot sector with zeros

; Boot Signature
dw 0xaa55
