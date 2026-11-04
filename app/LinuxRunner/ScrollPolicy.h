#ifndef LR_SCROLL_POLICY_H
#define LR_SCROLL_POLICY_H
#include <math.h>
// Bound work per UIKit event, preserving sub-step movement. Excess above the
// bound is discarded rather than flooding the guest after a long gesture.
static inline int lr_scroll_steps(double translation, double threshold, double *residual) {
    *residual = 0;
    if (!isfinite(translation) || !isfinite(threshold) || threshold <= 0) return 0;
    double count = trunc(translation / threshold);
    *residual = fmod(translation, threshold);
    return count > 32 ? 32 : count < -32 ? -32 : (int)count;
}
#endif
