#!/bin/sh
# Reproduce Debian's launcher contract: it resets CHROMIUM_FLAGS before sourcing
# /etc/chromium.d, so setting only the desktop environment cannot fix the crash.
set -eu
cd "$(dirname "$0")/../../.."
repo=$PWD
base="$repo/build/m2-tests"
mkdir -p "$base"
work=$(mktemp -d "$base/chromium-compat.XXXXXX")
cleanup() { case "$work" in "$base"/chromium-compat.*) rm -rf -- "$work";; esac; }
trap cleanup EXIT HUP INT TERM
support="$repo/app/LinuxRunner/GUISupport.bundle"
mkdir -p "$work/etc/chromium.d" "$work/home/.config/chromium"
printf 'ID=debian\n' > "$work/etc/os-release"
printf 'CHROMIUM_FLAGS="--existing-option"\n' > "$work/etc/chromium.d/10-user"
printf 'keep cookies and preferences\n' > "$work/home/.config/chromium/Preferences"
cp "$work/home/.config/chromium/Preferences" "$work/expected-profile"
sh "$support/configure-chromium.sh" --root "$work"
first=$(cksum "$work/etc/chromium.d/90-linuxrunner")
sh "$support/configure-chromium.sh" --root "$work"
[ "$first" = "$(cksum "$work/etc/chromium.d/90-linuxrunner")" ]
cmp "$work/home/.config/chromium/Preferences" "$work/expected-profile"
grep -q 'existing-option' "$work/etc/chromium.d/10-user"
# Like the real Debian wrapper: ignore an incoming CHROMIUM_FLAGS value, then
# load each package-supported config fragment before forming the ELF argv.
CHROMIUM_FLAGS=
for fragment in "$work"/etc/chromium.d/*; do . "$fragment"; done
set -- $CHROMIUM_FLAGS
printf '%s\n' "$@" > "$work/arguments"
for flag in --existing-option --no-sandbox --no-zygote --disable-gpu --js-flags=--jitless --renderer-process-limit=2; do
    grep -qx -- "$flag" "$work/arguments"
done
if grep -qE '^--(single-process|user-data-dir|disable-site-isolation)' "$work/arguments"; then exit 1; fi
[ "$LIBGL_ALWAYS_SOFTWARE:$LR_MESA_METAL_MODE" = 1:off ]
LINUXRUNNER_CHROMIUM_COMPAT=0 CHROMIUM_FLAGS=--user-setting
. "$work/etc/chromium.d/90-linuxrunner"
[ "$CHROMIUM_FLAGS" = --user-setting ]
printf 'ID=arch\n' > "$work/etc/os-release"
rm "$work/etc/chromium.d/90-linuxrunner"
sh "$support/configure-chromium.sh" --root "$work"
[ ! -e "$work/etc/chromium.d/90-linuxrunner" ]
printf 'ID=debian\n' > "$work/etc/os-release"
ln -s "$work/expected-profile" "$work/etc/chromium.d/90-linuxrunner"
if [ -L "$work/etc/chromium.d/90-linuxrunner" ]; then
    if sh "$support/configure-chromium.sh" --root "$work"; then echo 'FAIL accepted symlink'; exit 1; fi
else
    echo 'SKIP symlink rejection: this filesystem emulates symbolic links (macOS CI checks real symlinks)'
fi
cmp "$work/home/.config/chromium/Preferences" "$work/expected-profile"
printf '%s\n' 'PASS Debian Chromium config: normal launcher flags, idempotence, profile retention, opt-out and distribution selection'
