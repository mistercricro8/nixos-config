#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/dms-load-theme" \
    --app "atuin" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/atuin/dms.template.toml}" \
    --output "${OUTPUT:-${OUTPUT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/atuin/themes}/dms.toml}" \
    --mode "${MODE:-dark}"
