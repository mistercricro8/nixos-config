#!/usr/bin/env bash
set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <derivation> <build-host>"
    exit 1
fi

ts_hostname="$(tailscale status --json | jq -r '.Self.HostName')"
echo "[INFO] Tailscale hostname is ${ts_hostname}"

rsync -av --delete --info=progress2 --filter=':- .gitignore' . "$2":~/.current-nixos-rebuild/
echo "[INFO] Synced to $2:~/.current-nixos-rebuild/"

# shellcheck disable=SC2029
ssh "$2" "cd .current-nixos-rebuild && nixos-rebuild --flake .#$1 --target-host $ts_hostname --sudo --ask-sudo-password switch" 