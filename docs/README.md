# xdv-lib Documentation

This directory contains complete Markdown documentation for the `xdv-lib` target/runtime library.

## Scope

`xdv-lib` is the XDV-specific runtime library used by boot/runtime components.
It keeps XDV behavior out of the Dust compiler and in linkable library code.

## Document Index

| Document | Source | Summary |
|---|---|---|
| `xdv_lib.md` | `sector/xdv_lib/lib.ds` | Top-level `XdvLib` forge API and orchestration entry points. |
| `xdv_lib_boot_runtime.md` | `sector/xdv_lib/boot_runtime.ds` | Boot/runtime helper API for delay, clear, and kernel handoff wrappers. |
| `xdv_lib_boot_runtime_asm.md` | `asm/xdv_lib_boot_runtime.asm` | Concrete low-level implementation, memory contracts, and ATA PIO kernel transfer flow. |
| `xdv_lib_integration.md` | `State.toml`, `Dust.toml`, downstream callers | Build and linkage model, boot-chain integration, and validation guidance. |

## Library Summary

- Package: `xdv_lib`
- Version: `0.1.0`
- Workspace sector: `sector/xdv_lib`
- Primary role: provide XDV boot/runtime functions as a library, not compiler hardcoding.

## Quick Validation

```bash
dust check xdv-lib/sector/xdv_lib
```

## Notes

- xdv-lib APIs are K-regime procedures intended for boot/runtime paths.
- Kernel transfer behavior is implemented in assembly and currently targets the boot profile used by xdv-os.
