#!/bin/sh
# Sourced only by the Plasma session. The native setting can opt out.
if [ "${LR_PLASMA_COMPATIBILITY:-1}" = 1 ]; then
    export QT_XCB_GL_INTEGRATION=none QT_QUICK_BACKEND=software
    export LIBGL_ALWAYS_SOFTWARE=1 KWIN_COMPOSE=N
fi
# IME modules must be inherited by applications from the session's start.
if command -v fcitx5 >/dev/null 2>&1; then
    export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx
fi
