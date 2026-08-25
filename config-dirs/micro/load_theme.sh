#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin/dms-load-theme" \
    --app "micro" \
    --json "${JSON_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json}" \
    --template "${TEMPLATE:-${XDG_CONFIG_HOME:-$HOME/.config}/micro/micro.template.micro}" \
    --output "${OUTPUT:-${OUTPUT_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/micro/colorschemes}/dms.micro}" \
    --mode "${MODE:-dark}"
