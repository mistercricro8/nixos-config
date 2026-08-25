#!/usr/bin/env bash
set -euo pipefail

POST_CMD=""
if command -v fish &>/dev/null; then
    POST_CMD="fish -c 'fish_config theme choose dms'"
fi

exec "$HOME/.local/bin/dms-load-theme" \
    --app "fish" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/fish/dms.template.theme}" \
    --output "${OUTPUT:-${THEME_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/fish/themes}/dms.theme}" \
    --mode "${MODE:-dark}" \
    --strip-hash \
    ${POST_CMD:+--post-command "$POST_CMD"}
