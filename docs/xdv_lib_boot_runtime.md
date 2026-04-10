# xdv_lib_boot_runtime

- Source: `xdv-lib/sector/xdv_lib/boot_runtime.ds`
- Kind: Library Module
- Forge: `XdvLibBootRuntime`

## Purpose

`XdvLibBootRuntime` defines boot/runtime service procedures used by higher-level xdv-lib facades:

- splash delay
- console clear
- kernel handoff

## Forge Overview

| Forge | Constants | Procedures |
|---|---:|---:|
| `XdvLibBootRuntime` | 1 | 3 |

## Constants

| Constant | Type | Value | Description |
|---|---|---|---|
| `STATUS_OK` | `UInt32` | `0` | Success return value for boot/runtime wrappers. |

## Procedures

| Domain | Procedure | Parameters | Returns | Behavior |
|---|---|---|---|---|
| `K` | `xdv_boot_splash_wait_seconds` | `seconds: UInt32` | `UInt32` | Calls `xdv_lib_delay_seconds(seconds)`, returns `STATUS_OK`. |
| `K` | `xdv_boot_console_clear` | `(none)` | `UInt32` | Calls `xdv_lib_console_clear()`, returns `STATUS_OK`. |
| `K` | `xdv_boot_kernel_handoff` | `(none)` | `UInt32` | Calls `xdv_lib_kernel_transfer()`, returns `STATUS_OK`. |

## Implementation Relationship

These procedures are thin DPL wrappers around assembly-level routines exported by `xdv-lib/asm/xdv_lib_boot_runtime.asm`:

- `xdv_lib_delay_seconds`
- `xdv_lib_console_clear`
- `xdv_lib_kernel_transfer`

## Integration Notes

- Wrapper behavior is intentionally simple and deterministic.
- Error details for kernel transfer are handled at assembly level; wrapper return is the stable API status value.

## Example (DPL)

```dust
xdv_boot_splash_wait_seconds(8);
xdv_boot_console_clear();
xdv_boot_kernel_handoff();
```
