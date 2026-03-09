# xdv_lib

- Source: `xdv-lib/sector/xdv_lib/lib.ds`
- Kind: Library Module
- Forge: `XdvLib`

## Purpose

`XdvLib` is the top-level runtime facade for XDV-specific boot/runtime behavior. It exposes a minimal K-regime API that callers use for boot preparation and final kernel transfer.

## Forge Overview

| Forge | Constants | Procedures |
|---|---:|---:|
| `XdvLib` | 1 | 3 |

## Constants

| Constant | Type | Value | Description |
|---|---|---|---|
| `ABI_REVISION` | `UInt32` | `1` | Library ABI revision returned by `init()`. |

## Procedures

| Domain | Procedure | Parameters | Returns | Behavior |
|---|---|---|---|---|
| `K` | `init` | `(none)` | `UInt32` | Emits `xdv-lib initialized` and returns `ABI_REVISION`. |
| `K` | `xdv_boot_prepare` | `seconds: UInt32` | `UInt32` | Waits splash duration, clears console, returns `0`. |
| `K` | `xdv_boot_transfer_kernel` | `(none)` | `UInt32` | Triggers final kernel handoff routine, returns `0`. |

## Call Flow

`xdv_boot_prepare(seconds)`:

1. Calls `xdv_boot_splash_wait_seconds(seconds)`.
2. Calls `xdv_boot_console_clear()`.
3. Returns `0`.

`xdv_boot_transfer_kernel()`:

1. Calls `xdv_boot_kernel_handoff()`.
2. Returns `0`.

## Integration Notes

- `XdvLib` is a facade layer and delegates low-level behavior to `XdvLibBootRuntime` and assembly exports.
- Intended use is from boot runtime components, including `xdv-boot` flow control.

## Example (DPL)

```dust
let abi = init();
if abi > 0 {
    xdv_boot_prepare(8);
    xdv_boot_transfer_kernel();
}
```
