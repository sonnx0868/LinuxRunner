// Exercise glibc's stack reservation shape without a distro/libc download.
// The host refuses all full 8 MiB + 64 KiB inaccessible mappings. Private
// stacks must use demand-zero backing; MAP_SHARED proves injection is active.
.global _start
.text
_start:
    mov x0, 0
    mov x1, 0x810000
    mov x2, 0
    mov x3, 0x21
    movk x3, 2, lsl 16
    mov x4, -1
    mov x5, 0
    mov x8, 222
    svc 0
    cmn x0, 12
    b.ne fail
    mov x19, 0
    adr x20, bases
create:
    mov x0, 0
    mov x1, 0x810000
    mov x2, 0
    mov x3, 0x22
    movk x3, 2, lsl 16
    mov x4, -1
    mov x5, 0
    mov x8, 222
    svc 0
    cmp x0, 0
    b.lt fail
    str x0, [x20, x19, lsl 3]
    mov x21, x0
    add x0, x21, 0x10000
    mov x1, 0x800000
    mov x2, 3
    mov x8, 226
    svc 0
    cbnz x0, fail
    // Two sparse pages must materialize; untouched memory stays zero-filled.
    add x22, x21, 0x10000
    ldr x0, [x22]
    cbnz x0, fail
    add x23, x21, 0x810000
    sub x23, x23, 8
    ldr x0, [x23]
    cbnz x0, fail
    add x24, x19, 1
    str x24, [x22]
    str x24, [x23]
    // The 64 KiB guard must still reject syscall reads (EFAULT, not output).
    mov x0, 2
    mov x1, x21
    mov x2, 1
    mov x8, 64
    svc 0
    cmn x0, 14
    b.ne fail
    // Reprotect a materialized page, then restore it without losing data.
    mov x0, x22
    mov x1, 4096
    mov x2, 0
    mov x8, 226
    svc 0
    cbnz x0, fail
    mov x0, 2
    mov x1, x22
    mov x2, 1
    mov x8, 64
    svc 0
    cmn x0, 14
    b.ne fail
    mov x0, x22
    mov x1, 4096
    mov x2, 3
    mov x8, 226
    svc 0
    cbnz x0, fail
    ldr x0, [x22]
    cmp x0, x24
    b.ne fail
    add x19, x19, 1
    cmp x19, 48
    b.ne create
    // All live reservations retain distinct backing and can be released.
    mov x19, 0
release:
    ldr x21, [x20, x19, lsl 3]
    add x22, x21, 0x10000
    add x23, x21, 0x810000
    sub x23, x23, 8
    add x24, x19, 1
    ldr x0, [x22]
    cmp x0, x24
    b.ne fail
    ldr x0, [x23]
    cmp x0, x24
    b.ne fail
    mov x0, x21
    mov x1, 0x810000
    mov x8, 215
    svc 0
    cbnz x0, fail
    mov x0, 2
    mov x1, x22
    mov x2, 1
    mov x8, 64
    svc 0
    cmn x0, 14
    b.ne fail
    add x19, x19, 1
    cmp x19, 48
    b.ne release
    mov x0, 1
    adr x1, success
    mov x2, success_end-success
    mov x8, 64
    svc 0
    mov x0, 0
    mov x8, 94
    svc 0
fail:
    mov x0, 1
    adr x1, failure
    mov x2, failure_end-failure
    mov x8, 64
    svc 0
    mov x0, 31
    mov x8, 94
    svc 0
success: .ascii "THREAD_STACK_PASS\n"
success_end:
failure: .ascii "THREAD_STACK_FAIL\n"
failure_end:
.data
.balign 8
bases: .skip 384
