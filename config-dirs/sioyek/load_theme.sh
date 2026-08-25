#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/dms-load-theme" \
    --app "sioyek" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/sioyek/prefs_user.template.config}" \
    --output "${OUTPUT:-${XDG_CONFIG_HOME:-$HOME/.config}/sioyek/prefs_user.config}" \
    --mode "${MODE:-dark}"
