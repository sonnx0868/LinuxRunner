#!/bin/bash
set -euo pipefail
exec bash "$(dirname "$0")/../app/LinuxRunner/GUISupport.bundle/setup-debian-m2.sh" "$@"
