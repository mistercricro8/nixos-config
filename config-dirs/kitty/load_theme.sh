#!/usr/bin/env bash
set -euo pipefail

POST_CMD=""
if command -v pgrep &>/dev/null && pgrep -x kitty &>/dev/null; then
    POST_CMD="kill -SIGUSR1 \$(pgrep -x kitty) 2>/dev/null || true"
fi

exec "$HOME/.local/bin/dms-load-theme" \
    --app "kitty" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty/dms.template.conf}" \
    --output "${OUTPUT:-${OUTPUT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}/dank-theme.conf}" \
    --mode "${MODE:-dark}" \
    ${POST_CMD:+--post-command "$POST_CMD"}
