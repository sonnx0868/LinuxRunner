#!/bin/sh
# Install a package-supported config fragment. Do not replace /usr/bin/chromium,
# the ELF binary, .desktop files, or the user's browser profile.
set -eu
support=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_root=
if [ "$#" != 0 ]; then
    # Offline staging for packaging/tests; never used by the live session.
    [ "$#" = 2 ] && [ "$1" = --root ] || exit 2
    target_root=$2
    case "$target_root" in /*) ;; *) echo 'CHROMIUM_COMPAT: staging root must be absolute' >&2; exit 2;; esac
    [ "$target_root" != / ] || exit 2
elif [ "$(id -u)" != 0 ]; then
    echo 'CHROMIUM_COMPAT: run this configuration step with sudo' >&2
    exit 1
fi
distro=$(sed -n 's/^ID=//p' "$target_root/etc/os-release" 2>/dev/null | tr -d '"')
[ "$distro" = debian ] || { echo 'CHROMIUM_COMPAT: configuration not needed for this distribution'; exit 0; }
directory="$target_root/etc/chromium.d"
destination="$directory/90-linuxrunner"
if [ -L "$directory" ] || [ -L "$destination" ]; then
    echo 'CHROMIUM_COMPAT: refusing a symbolic-link configuration target' >&2
    exit 1
fi
mkdir -p "$directory"
if ! cmp -s "$support/chromium-compat.conf" "$destination"; then
    temporary=$(mktemp "$directory/.linuxrunner-compat.XXXXXX")
    trap 'rm -f "$temporary"' EXIT HUP INT TERM
    cat "$support/chromium-compat.conf" > "$temporary"
    chmod 644 "$temporary"
    mv -f "$temporary" "$destination"
    trap - EXIT HUP INT TERM
fi
echo 'CHROMIUM_COMPAT: Debian launcher configured (terminal, KDE and app launcher)'
