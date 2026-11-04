#!/bin/sh
set -eu
# Debian's real Chromium package, separate from LinuxRunner's Qt browser.
launcher=$(command -v chromium) || { echo 'Install Chromium first: sudo apt install chromium' >&2; exit 127; }
printf '%s\n' 'CHROMIUM_COMPAT: launcher=m2 sandbox=off zygote=off gpu=software v8=jitless' >&2
export LIBGL_ALWAYS_SOFTWARE=1 LR_MESA_METAL_MODE=off
profile="${XDG_CONFIG_HOME:-$HOME/.config}/linuxrunner/chromium"
mkdir -p "$profile"
if [ "$#" -eq 0 ]; then set -- about:blank; fi
# Keep site isolation and separate renderer processes. The renderer limit is
# a soft limit; Chromium can exceed it for security boundaries. Guest V8 JIT
# is disabled independently of the native LinuxRunner JIT.
exec "$launcher" --user-data-dir="$profile" \
    --no-sandbox --no-zygote --disable-gpu --disable-gpu-compositing \
    --renderer-process-limit=2 --disable-extensions --disable-background-networking \
    --disable-sync --no-first-run --no-default-browser-check \
    '--js-flags=--jitless --max-old-space-size=512' "$@"
