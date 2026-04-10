# xdv-lib

`xdv-lib` is the target/runtime library for XDV-specific boot and kernel
services.

Design goal:
- Keep the Dust compiler target-agnostic and GCC-style object compatible.
- Put XDV boot/runtime behavior in a linkable library instead of compiler
  hardcoding.

This library defines K-regime APIs that XDV components can call. The compiler
should only compile and link calls; it should not embed any XDV-specific
runtime logic.
