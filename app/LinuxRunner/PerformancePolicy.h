#ifndef LR_PERFORMANCE_POLICY_H
#define LR_PERFORMANCE_POLICY_H
#include <stdbool.h>
#include <stdint.h>

#define LR_GIB (UINT64_C(1024) * 1024 * 1024)
#ifndef LINUXRUNNER_M2_PROFILE
#define LINUXRUNNER_M2_PROFILE 0
#endif

// A build for the 16 GB M2 iPad can raise the aggregate anonymous-page budget,
// but only when iPadOS reports enough remaining allowance for this process.
// Leave at least 1 GB for file mappings, page tables, graphics and native UI.
// Keep Linux's per-process RAM advertisement at 4 GB: large V8 arenas hurt it.
static inline uint64_t lr_m2_anonymous_budget(uint64_t physical, uint64_t available) {
    uint64_t baseline = 4 * LR_GIB;
    if (physical < 12 * LR_GIB || available <= 5 * LR_GIB) return baseline;
    uint64_t budget = available - LR_GIB;
    if (budget > physical / 2) budget = physical / 2;
    if (budget > 8 * LR_GIB) budget = 8 * LR_GIB;
    return budget > baseline ? budget : baseline;
}

// No idle timer: this is a ceiling for already available external frames.
// Keep software fallback and hot/low-power devices at the previous 30 Hz cap.
static inline unsigned lr_external_frame_rate(bool m2, bool metal, bool constrained,
                                              unsigned screen_rate) {
    unsigned rate = m2 && metal && !constrained ? 60 : 30;
    return screen_rate && screen_rate < rate ? screen_rate : rate;
}
#endif
