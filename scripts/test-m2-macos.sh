#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { echo 'Use an ARM64 macOS Bitrise machine.' >&2; exit 1; }
mkdir -p build/m2-tests
for probe in rfb_decode_probe rfb_guest_probe; do
    clang -fobjc-arc -fblocks -I. -framework Foundation \
        "tests/linuxrunner/gui/$probe.m" app/LinuxRunner/RFBClient.m app/LinuxRunner/RFBProtocol.c \
        -o "build/m2-tests/$probe"
done
python3 tests/linuxrunner/gui/test_rfb_decode.py --probe build/m2-tests/rfb_decode_probe --delivery patch --expect-raw-bytes 180 --output build/m2-tests/decode-patch.json
python3 tests/linuxrunner/gui/test_rfb_decode.py --probe build/m2-tests/rfb_decode_probe --delivery snapshot --expect-raw-bytes 180 --output build/m2-tests/decode-snapshot.json
python3 tests/linuxrunner/gui/test_rfb_failures.py --probe build/m2-tests/rfb_guest_probe --output build/m2-tests/protocol-negative
meson setup build/m2-host -Dengine=asbestos -Dguest_arch=arm64 -Djit=false -Djit_emit=false -Dcli_aot= -Dvdso_required=true
ninja -C build/m2-host ish tools/fakefsify
python3 tests/linuxrunner/run-exec-rollback-macos.py --runtime build/m2-host/ish --fakefsify build/m2-host/tools/fakefsify
