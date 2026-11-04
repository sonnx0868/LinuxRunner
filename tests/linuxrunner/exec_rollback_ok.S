.global _start
.text
_start:
    mov x0, 1
    adr x1, message
    mov x2, 19
    mov x8, 64
    svc 0
    mov x0, 0
    mov x8, 94
    svc 0
message: .ascii "EXEC_ROLLBACK_PASS\n"
