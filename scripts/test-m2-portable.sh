#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/m2-tests
sh tests/linuxrunner/gui/test-chromium-compat.sh
read -r -a compiler <<< "${CC:-cc}"
flags=(-std=c11 -O2 -Wall -Wextra -Werror -UNDEBUG -I.)
"${compiler[@]}" "${flags[@]}" -pthread tests/linuxrunner/gui/m2_policy_test.c -lm -o build/m2-tests/policy-test
build/m2-tests/policy-test
"${compiler[@]}" "${flags[@]}" tests/linuxrunner/gui/rfb_protocol_test.c app/LinuxRunner/RFBProtocol.c -lm -o build/m2-tests/rfb-test
build/m2-tests/rfb-test
