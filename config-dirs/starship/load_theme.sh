#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/dms-load-theme" \
    --app "starship" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.template.toml}" \
    --output "${OUTPUT:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}" \
    --mode "${MODE:-dark}" \
    --type "starship"
