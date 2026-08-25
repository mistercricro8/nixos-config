#!/usr/bin/env bash
set -euo pipefail

POST_CMD=""
if command -v bat &>/dev/null; then
    POST_CMD="bat cache --build"
fi

exec "$HOME/.local/bin/dms-load-theme" \
    --app "bat" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/bat/dms.template.tmTheme}" \
    --output "${OUTPUT:-${OUTPUT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/bat/themes}/dms.tmTheme}" \
    --mode "${MODE:-dark}" \
    ${POST_CMD:+--post-command "$POST_CMD"}
