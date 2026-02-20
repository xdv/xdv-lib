# xdv_lib_boot_runtime.asm

- Source: `xdv-lib/asm/xdv_lib_boot_runtime.asm`
- Kind: Low-Level Runtime Implementation (x64 assembly)

## Purpose

This file provides the concrete boot/runtime implementation for xdv-lib in the xdv-os boot path. It implements:

1. Splash delay.
2. VGA text console clear.
3. Kernel transfer by loading `/console/kernel.bin` metadata from the xdvfs boot record and reading sectors via ATA PIO.

## Exported Symbols

| Symbol | Role |
|---|---|
| `xdv_lib_boot_main` | Entry shim that calls Dust `boot_main` and halts afterward. |
| `xdv_lib_delay_seconds` | Alias to splash-delay routine. |
| `xdv_lib_console_clear` | Alias to console-clear routine. |
| `xdv_lib_kernel_transfer` | Alias to kernel-handoff routine. |
| `xdv_boot_splash_wait_seconds` | Splash delay implementation used by DPL wrappers. |
| `xdv_boot_console_clear` | VGA clear implementation used by DPL wrappers. |
| `xdv_boot_kernel_handoff` | Kernel transfer implementation used by DPL wrappers. |

## External Symbol Dependency

| Symbol | Source |
|---|---|
| `boot_main` | Dust-level boot contract flow (linked from xdv-boot code). |

## Key Constants and Memory Contract

### Video

| Constant | Value | Meaning |
|---|---|---|
| `VGA_TEXT_BASE` | `0x000B8000` | VGA text memory base. |
| `VGA_TEXT_CELLS` | `2000` | 80x25 text cells. |

### Boot Record / Kernel Metadata

| Constant | Value | Meaning |
|---|---|---|
| `BOOTREC_BASE` | `0x00000600` | Boot record buffer base in low memory. |
| `BOOTREC_KERNEL_REL_LBA_OFF` | `BOOTREC_BASE + 32` | Relative LBA for kernel image. |
| `BOOTREC_KERNEL_SECTORS_OFF` | `BOOTREC_BASE + 36` | Kernel sector count. |
| `BOOTREC_KERNEL_ENTRY_OFF` | `BOOTREC_BASE + 44` | Kernel entry offset from image base. |
| `MBR_PARTITION0_START_LBA_OFF` | `0x00007DC6` | Partition 0 start LBA in stage-0 memory layout. |
| `KERNEL_IMAGE_BASE` | `0x00020000` | Kernel load destination base address. |

### Delay and ATA

| Constant | Value | Meaning |
|---|---|---|
| `DELAY_LOOPS_PER_SECOND` | `700000000` | Busy-loop iteration count per second. |
| `ATA_WAIT_SPINS` | `1000000` | Polling timeout spin count. |
| `ATA_CMD_READ_SECTORS` | `0x20` | ATA PIO read command. |

ATA ports used: `0x1F0` to `0x1F7`.

## Procedure Behavior

### `xdv_lib_boot_main`

- Sets frame pointer.
- Calls `boot_main` (Dust-level flow).
- Enters halt loop (`hlt; jmp`) after return.

### `xdv_boot_splash_wait_seconds`

- Input: `rdi = seconds`.
- For each second, runs an inner decrement loop with `DELAY_LOOPS_PER_SECOND` iterations.
- Returns `eax = 0`.

### `xdv_boot_console_clear`

- Writes `0x0720` (space + light-gray-on-black attribute) across all VGA cells.
- Clears whole text screen.
- Returns `eax = 0`.

### `xdv_boot_kernel_handoff`

1. Reads kernel relative LBA from boot record.
2. Reads MBR partition start LBA from stage-0 memory layout.
3. Computes absolute kernel LBA.
4. Reads kernel sector count.
5. Loads each sector to `KERNEL_IMAGE_BASE` via `ata_pio_read_lba28_sector`.
6. Computes kernel entry address from `BOOTREC_KERNEL_ENTRY_OFF + KERNEL_IMAGE_BASE`.
7. Calls computed kernel entry.
8. Returns `0` on success path, `1` on load failure path.

### `ata_pio_read_lba28_sector`

- Programs ATA registers for one 28-bit LBA sector read.
- Waits for not-busy and DRQ readiness.
- Transfers 256 words (`rep insw`) into destination buffer.
- Returns with CF clear on success, CF set on failure.

## Alias Routines

- `xdv_lib_delay_seconds` jumps to `xdv_boot_splash_wait_seconds`.
- `xdv_lib_console_clear` jumps to `xdv_boot_console_clear`.
- `xdv_lib_kernel_transfer` jumps to `xdv_boot_kernel_handoff`.

## Constraints and Assumptions

1. Assumes x64 long-mode context (`BITS 64`) with valid low-memory handoff data from stage-0.
2. Uses ATA PIO LBA28 path for kernel sector reads.
3. Expects xdvfs boot record and partition metadata at fixed handoff addresses.
4. Delay routine is busy-loop based and hardware-frequency dependent.

## Operational Outcome

This assembly implementation is the concrete runtime backend for xdv-lib boot services and enables a strict boot.bin-driven final transfer into `kernel.bin`.
