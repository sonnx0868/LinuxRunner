#!/bin/bash
# Run INSIDE Debian's KDE terminal as the ordinary sudo user.
set -euo pipefail
[[ $(id -u) != 0 ]] || { echo 'Run as your ordinary Debian user, not root.' >&2; exit 1; }
[[ $(uname -m) == aarch64 ]] || { echo 'This setup requires Debian ARM64.' >&2; exit 1; }
. /etc/os-release
[[ $ID == debian && $VERSION_ID == 13 ]] || { echo 'This setup targets Debian 13.' >&2; exit 1; }
sudo apt-get update
sudo apt-get install -y --no-install-recommends chromium fcitx5 fcitx5-unikey \
    fcitx5-config-qt fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 \
    fcitx5-frontend-qt5 fcitx5-frontend-qt6 im-config fonts-noto-core fonts-noto-color-emoji
im-config -n fcitx5
mkdir -p "$HOME/.config/plasma-workspace/env" "$HOME/.config/autostart" \
    "$HOME/.local/bin" "$HOME/.local/share/applications"
cat > "$HOME/.config/plasma-workspace/env/linuxrunner-input.sh" <<'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
cat > "$HOME/.config/autostart/linuxrunner-fcitx5.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Fcitx 5
Exec=fcitx5 -d --replace
X-KDE-autostart-after=panel
EOF
source_dir=$(cd "$(dirname "$0")" && pwd)
install -m 755 "$source_dir/chromium-m2.sh" "$HOME/.local/bin/linuxrunner-chromium"
cat > "$HOME/.local/share/applications/linuxrunner-chromium.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Chromium (LinuxRunner M2)
Exec="$HOME/.local/bin/linuxrunner-chromium" %U
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
EOF
printf '%s\n' 'Setup complete. Restart the Linux desktop.' \
    'Open Fcitx 5 Configuration: add Keyboard - English (US) and Unikey.' \
    'Select Telex in Unikey. Ctrl+Space switches Vietnamese on/off.' \
    'Open Chromium (LinuxRunner M2) from the application menu.'
