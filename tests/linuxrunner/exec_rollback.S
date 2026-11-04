// No guest libc/rootfs download: the fixture exercises real ARM64 syscalls.
.global _start
.text
_start:
    // Register a robust list: failed exec must not clear its address.
    adr x0, robust
    mov x1, 24
    mov x8, 99
    svc 0
    cbnz x0, fail
    mov x19, 32
again:
    adr x0, denied
    adr x1, denied_argv
    adr x2, empty_env
    mov x8, 221
    svc 0
    cmn x0, 12
    b.ne fail
    mov x0, 0
    adr x1, robust_result
    adr x2, robust_size
    mov x8, 100
    svc 0
    cbnz x0, fail
    adr x1, robust_result
    ldr x1, [x1]
    adr x2, robust
    cmp x1, x2
    b.ne fail
    subs x19, x19, 1
    b.ne again
    // A successful exec still commits and reaches the replacement program.
    adr x0, accepted
    adr x1, accepted_argv
    adr x2, empty_env
    mov x8, 221
    svc 0
fail:
    mov x0, 1
    mov x8, 94
    svc 0
.data
.balign 8
robust: .quad robust, 0, 0
robust_result: .quad 0
robust_size: .quad 0
denied_argv: .quad denied, 0
accepted_argv: .quad accepted, 0
empty_env: .quad 0
denied: .asciz "/bin/deny-image"
accepted: .asciz "/bin/exec-ok"
