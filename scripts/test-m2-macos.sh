#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { echo 'Use an ARM64 macOS Bitrise machine.' >&2; exit 1; }
mkdir -p build/m2-tests
swiftc app/LinuxRunner/AppUpdateManifest.swift tests/linuxrunner/update-manifest-probe.swift -o build/m2-tests/update-manifest
build/m2-tests/update-manifest
swiftc app/LinuxRunner/Environment.swift app/LinuxRunner/Diagnostics.swift tests/linuxrunner/diagnostics/DiagnosticsTests.swift -o build/m2-tests/diagnostics
build/m2-tests/diagnostics
python3 tests/linuxrunner/gui/test_plasma_exit.py
swiftc -typecheck -swift-version 5 -target arm64-apple-ios15.0 -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" app/LinuxRunner/AppUpdateManifest.swift app/LinuxRunner/AppUpdater.swift
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
clang -O2 -Wall -Wextra -Werror -DGUEST_ARM64=1 -DENGINE_ASBESTOS=1 -I. -Ibuild/m2-host \
    tests/linuxrunner/signal-evidence.c build/m2-host/libish.a build/m2-host/libish_emu.a build/m2-host/libfakefs.a \
    -lsqlite3 -lm -pthread -o build/m2-tests/signal-evidence
python3 -c 'import subprocess; subprocess.run(["build/m2-tests/signal-evidence"], check=True, timeout=30)'
python3 tests/linuxrunner/run-exec-rollback-macos.py --runtime build/m2-host/ish --fakefsify build/m2-host/tools/fakefsify
python3 tests/linuxrunner/run-thread-stack-macos.py --runtime build/m2-host/ish --fakefsify build/m2-host/tools/fakefsify
