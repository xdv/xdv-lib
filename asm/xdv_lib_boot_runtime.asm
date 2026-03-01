; xdv-lib boot/runtime implementation for xdv-os boot.bin path.
; Provides concrete low-level routines:
; - splash delay
; - VGA text clear
; - kernel transfer by loading /console/kernel.bin from xdvfs data region

BITS 64
DEFAULT REL

section .text

global xdv_lib_boot_main
global xdv_lib_delay_seconds
global xdv_lib_console_clear
global xdv_lib_kernel_transfer
global xdv_boot_splash_wait_seconds
global xdv_boot_console_clear
global xdv_boot_kernel_handoff

extern boot_main

%define VGA_TEXT_BASE 0x000B8000
%define VGA_TEXT_CELLS 2000
%define BOOTREC_BASE 0x00000600
%define BOOTREC_KERNEL_REL_LBA_OFF (BOOTREC_BASE + 32)
%define BOOTREC_KERNEL_SECTORS_OFF (BOOTREC_BASE + 36)
%define BOOTREC_KERNEL_ENTRY_OFF (BOOTREC_BASE + 44)
%define MBR_PARTITION0_START_LBA_OFF 0x00007DC6
%define KERNEL_IMAGE_BASE 0x00020000
%define DELAY_LOOPS_PER_SECOND 700000000
%define ATA_WAIT_SPINS 1000000
%define ATA_IO_DATA 0x1F0
%define ATA_IO_SECCOUNT 0x1F2
%define ATA_IO_LBA_LOW 0x1F3
%define ATA_IO_LBA_MID 0x1F4
%define ATA_IO_LBA_HIGH 0x1F5
%define ATA_IO_DRIVE_HEAD 0x1F6
%define ATA_IO_COMMAND_STATUS 0x1F7
%define ATA_CMD_READ_SECTORS 0x20

xdv_lib_boot_main:
    push rbp
    mov rbp, rsp

    ; Execute dust-level boot profile.
    ; boot_main performs the full contract, including final kernel handoff.
    call boot_main

.hang:
    hlt
    jmp .hang

xdv_boot_splash_wait_seconds:
    ; rdi = seconds
    test rdi, rdi
    jz .delay_done
.delay_outer:
    mov rcx, DELAY_LOOPS_PER_SECOND
.delay_inner:
    dec rcx
    jne .delay_inner
    dec rdi
    jne .delay_outer
.delay_done:
    xor eax, eax
    ret

xdv_boot_console_clear:
    cld
    mov rdi, VGA_TEXT_BASE
    mov rcx, VGA_TEXT_CELLS
    mov ax, 0x0720
    rep stosw
    xor eax, eax
    ret

xdv_boot_kernel_handoff:
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Resolve absolute kernel LBA from xdvfs boot record + partition start.
    mov eax, dword [abs BOOTREC_KERNEL_REL_LBA_OFF]
    mov ebx, dword [abs MBR_PARTITION0_START_LBA_OFF]
    add eax, ebx
    mov r12d, eax

    ; Sector count and destination image window.
    mov r13d, dword [abs BOOTREC_KERNEL_SECTORS_OFF]
    mov r15d, r13d
    test r13d, r13d
    jz .load_fail
    mov r14, KERNEL_IMAGE_BASE

.read_loop:
    cmp r13d, 0
    je .kernel_ready
    mov eax, r12d
    mov rdi, r14
    call ata_pio_read_lba28_sector
    jc .load_fail
    add r14, 512
    inc r12d
    dec r13d
    jmp .read_loop

.kernel_ready:
    mov eax, dword [abs BOOTREC_KERNEL_ENTRY_OFF]
    test eax, eax
    jz .load_fail

    mov ecx, r15d
    imul ecx, 512
    cmp eax, ecx
    jae .load_fail

    add rax, KERNEL_IMAGE_BASE
    mov r11, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    call r11
    xor eax, eax
    ret

.load_fail:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov eax, 1
    ret

ata_pio_read_lba28_sector:
    ; In:
    ;   eax = absolute LBA (28-bit)
    ;   rdi = destination buffer (512-byte aligned)
    ; Out:
    ;   CF clear = success, CF set = failure
    push rbx
    push rcx
    push rdx

    mov ebx, eax
    call ata_wait_not_busy
    jc .io_fail

    mov dx, ATA_IO_DRIVE_HEAD
    mov eax, ebx
    shr eax, 24
    and al, 0x0F
    or al, 0xE0
    out dx, al

    mov dx, ATA_IO_SECCOUNT
    mov al, 1
    out dx, al

    mov dx, ATA_IO_LBA_LOW
    mov eax, ebx
    out dx, al

    mov dx, ATA_IO_LBA_MID
    mov eax, ebx
    shr eax, 8
    out dx, al

    mov dx, ATA_IO_LBA_HIGH
    mov eax, ebx
    shr eax, 16
    out dx, al

    mov dx, ATA_IO_COMMAND_STATUS
    mov al, ATA_CMD_READ_SECTORS
    out dx, al

    call ata_wait_drq
    jc .io_fail

    mov dx, ATA_IO_DATA
    mov rcx, 256
    cld
    rep insw
    clc
    jmp .io_done

.io_fail:
    stc

.io_done:
    pop rdx
    pop rcx
    pop rbx
    ret

ata_wait_not_busy:
    mov ecx, ATA_WAIT_SPINS
    mov dx, ATA_IO_COMMAND_STATUS
.wait_busy:
    in al, dx
    test al, 0x80
    jz .ready
    dec ecx
    jnz .wait_busy
    stc
    ret
.ready:
    clc
    ret

ata_wait_drq:
    mov ecx, ATA_WAIT_SPINS
    mov dx, ATA_IO_COMMAND_STATUS
.wait_drq:
    in al, dx
    test al, 0x01
    jnz .fail
    test al, 0x20
    jnz .fail
    test al, 0x80
    jnz .spin
    test al, 0x08
    jnz .ok
.spin:
    dec ecx
    jnz .wait_drq
.fail:
    stc
    ret
.ok:
    clc
    xor eax, eax
    ret

xdv_lib_delay_seconds:
    jmp xdv_boot_splash_wait_seconds

xdv_lib_console_clear:
    jmp xdv_boot_console_clear

xdv_lib_kernel_transfer:
    jmp xdv_boot_kernel_handoff
