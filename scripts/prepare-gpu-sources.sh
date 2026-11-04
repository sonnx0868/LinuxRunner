#!/bin/bash
# Pinned inputs from docs/BUILDING.md. Run on the Bitrise macOS builder.
set -euo pipefail
: "${GPU_DEPS:?Set GPU_DEPS to the build dependency directory}"
mkdir -p "$GPU_DEPS"
GPU_DEPS=$(cd "$GPU_DEPS" && pwd)
checkout() {
    local directory=$1 remote=$2 revision=$3
    if [[ ! -d "$GPU_DEPS/$directory/.git" ]]; then
        git clone --filter=blob:none "$remote" "$GPU_DEPS/$directory"
    fi
    local existing
    existing=$(git -C "$GPU_DEPS/$directory" status --porcelain)
    [[ -z "$existing" ]] || { echo "Dependency has local edits: $directory" >&2; exit 1; }
    git -C "$GPU_DEPS/$directory" fetch --depth=1 origin "$revision"
    git -C "$GPU_DEPS/$directory" checkout --detach "$revision"
    [[ $(git -C "$GPU_DEPS/$directory" rev-parse HEAD) == "$revision" ]]
}
checkout depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git a20039648c0de69d8156906b18052bd47e9bf230
checkout virglrenderer https://gitlab.freedesktop.org/virgl/virglrenderer.git e0a1caf3b147bb26dfe524dbb85ded1177e7e49e
checkout libepoxy https://github.com/anholt/libepoxy.git d1f952c4565c389d82fd1657153e84e050f35b27
checkout angle https://chromium.googlesource.com/angle/angle feebf60fe088ccec3a26a7419d6ac68edf542c7a
export PATH="$GPU_DEPS/depot_tools:$PATH" DEPOT_TOOLS_UPDATE=0 DEPOT_TOOLS_METRICS=0
cd "$GPU_DEPS/angle"
python3 scripts/bootstrap.py
# Bitrise starts from a clean VM. The full LLVM/CTS/SwiftShader histories
# are large; the build only needs the revisions pinned by ANGLE's DEPS.
gclient sync --no-history --revision feebf60fe088ccec3a26a7419d6ac68edf542c7a
