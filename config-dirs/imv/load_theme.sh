#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/dms-load-theme" \
    --app "imv" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/imv/imv.template.config}" \
    --output "${OUTPUT:-${OUTPUT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/imv}/config}" \
    --mode "${MODE:-dark}" \
    --strip-hash
