// Native macOS fault injection: mirror the rejected 1008 Chromium stack mmap.
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>
static void *deny_stack(void *address, size_t length, int protection, int flags, int fd, off_t offset) {
    if (length == 0x810000 && protection == PROT_NONE && (flags & MAP_ANON)) {
        static const char message[] = "STACK_INJECTION: denied 0x810000 PROT_NONE host mmap\n";
        write(2, message, sizeof(message) - 1);
        errno = ENOMEM;
        return MAP_FAILED;
    }
    return mmap(address, length, protection, flags, fd, offset);
}
__attribute__((used,section("__DATA,__interpose")))
static const struct { const void *replacement, *original; } pair = {(void *)deny_stack, (void *)mmap};
