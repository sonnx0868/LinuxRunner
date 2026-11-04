#ifndef ISH_ANON_BUDGET_H
#define ISH_ANON_BUDGET_H
#include <stdbool.h>
#include <stdatomic.h>

// Shared by the actual allocator and the standalone boundary/concurrency test.
static inline bool anon_budget_try_reserve(_Atomic long *used, long limit, long pages) {
    if (pages < 0 || limit < 0) return false;
    long count = atomic_load(used);
    do {
        if (pages > limit || count > limit - pages) return false;
    } while (!atomic_compare_exchange_weak(used, &count, count + pages));
    return true;
}
#endif
