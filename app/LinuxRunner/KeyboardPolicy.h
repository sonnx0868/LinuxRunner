#ifndef LR_KEYBOARD_POLICY_H
#define LR_KEYBOARD_POLICY_H
#include <stdbool.h>
#include <stdint.h>

// USB HID positions, independent of UIKit's active language/marked text.
// The guest uses an English (US) XKB layout; its IME handles Telex/VNI.
// Caps Lock is a separate guest key, so do not apply host Caps Lock here.
static inline uint32_t lr_hid_us_symbol(unsigned hid, bool shift) {
    if (hid >= 4 && hid <= 29) return (shift ? 'A' : 'a') + hid - 4;
    if (hid >= 30 && hid <= 39) return (uint8_t)(shift ? "!@#$%^&*()" : "1234567890")[hid - 30];
    if (hid >= 45 && hid <= 56) return (uint8_t)(shift ? "_+{}|~:\"~<>?" : "-=[]\\#;'`,./")[hid - 45];
    if (hid >= 58 && hid <= 69) return 0xffbe + hid - 58;
    if (hid >= 104 && hid <= 115) return 0xffca + hid - 104;
    if (hid >= 89 && hid <= 97) return 0xffb1 + hid - 89;
    switch (hid) {
        case 40: return 0xff0d; case 41: return 0xff1b;
        case 42: return 0xff08; case 43: return 0xff09;
        case 44: return ' '; case 57: return 0xffe5;
        case 70: return 0xff61; case 71: return 0xff14; case 72: return 0xff13;
        case 73: return 0xff63; case 74: return 0xff50; case 75: return 0xff55;
        case 76: return 0xffff; case 77: return 0xff57; case 78: return 0xff56;
        case 79: return 0xff53; case 80: return 0xff51; case 81: return 0xff54; case 82: return 0xff52;
        case 83: return 0xff7f; case 84: return 0xffaf; case 85: return 0xffaa;
        case 86: return 0xffad; case 87: return 0xffab; case 88: return 0xff8d;
        case 98: return 0xffb0; case 99: return 0xffae;
        case 100: return shift ? '|' : '\\'; case 101: return 0xff67;
        default: return 0;
    }
}
#endif
