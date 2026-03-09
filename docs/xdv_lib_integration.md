# xdv-lib Integration Guide

## Source of Truth

- Workspace manifest: `xdv-lib/State.toml`
- Package manifest: `xdv-lib/Dust.toml`
- Top-level API: `xdv-lib/sector/xdv_lib/lib.ds`
- Boot runtime API: `xdv-lib/sector/xdv_lib/boot_runtime.ds`
- Low-level backend: `xdv-lib/asm/xdv_lib_boot_runtime.asm`

## Library Position in XDV Stack

`xdv-lib` is a target/runtime support library for XDV boot behavior. It is intentionally separate from the Dust compiler so compiler codegen remains target-agnostic.

## Dependency Model

From `xdv-lib/State.toml`:

- Depends on `dustlib`.
- Depends on `dustlib_k`.

These dependencies provide shared Dust runtime types and K-regime support used by system components.

## Boot-Chain Integration

Typical xdv-os boot flow using xdv-lib-backed routines:

1. Stage-0 (`xdv-os/src/boot_sector.asm`) loads `boot.bin` only.
2. xdv-boot executes its boot contract and calls xdv-lib wrappers.
3. xdv-lib performs splash wait and console clear.
4. xdv-lib performs final kernel transfer routine.
5. `kernel.bin` entry executes.

In xdv-boot code, high-level calls include:

- `xdv_boot_prepare(seconds)`
- `xdv_boot_transfer_kernel()`

## Boot Metadata Contract

The assembly backend expects boot metadata at fixed addresses:

- boot record buffer base at `0x00000600`
- kernel relative LBA at offset `+32`
- kernel sector count at offset `+36`
- kernel entry offset at offset `+44`
- partition start LBA from stage-0 memory layout

If this contract changes, stage-0, xdv-boot, and xdv-lib assembly must be updated together.

## Build and Validation

### Check xdv-lib sector

```bash
dust check xdv-lib/sector/xdv_lib
```

### Verify integration callers

Validate xdv-boot call sites and boot path assumptions:

```bash
rg -n "xdv_boot_prepare|xdv_boot_transfer_kernel|xdv_boot_kernel_handoff" xdv-boot/src xdv-lib/sector/xdv_lib
```

## Portability Notes

- Current backend is x64 assembly and ATA PIO oriented.
- Delay timing is loop-based and not calibrated by hardware timer.
- Additional storage paths (AHCI/NVMe/UEFI protocols) can be introduced behind the same wrapper API to preserve upstream compatibility.

## Versioning and Compatibility

- Current package version: `0.1.0`.
- `XdvLib::ABI_REVISION` is the API compatibility indicator returned by `init()`.
- Keep wrapper signatures stable so callers do not require recompilation-level API rewrites.
