#!/usr/bin/env bash
set -e

AVAILABLE_LANGS=("python" "node" "go" "java" "rust")

languages=()
nix_args=()
parsing_languages=true

for arg in "$@"; do
  if [[ "$arg" == "--" ]]; then
    parsing_languages=false
    continue
  fi
  if [[ "$arg" == -* ]]; then
    parsing_languages=false
  fi

  if [ "$parsing_languages" = true ]; then
        matched=false
    for valid in "${AVAILABLE_LANGS[@]}"; do
      if [[ "$arg" == "$valid" ]]; then
        languages+=("$arg")
        matched=true
        break
      fi
    done
    if [ "$matched" = false ]; then
      echo "Error: Unknown language/tooling '$arg'" >&2
      echo "Valid options are: ${AVAILABLE_LANGS[*]}" >&2
      exit 1
    fi
  else
    nix_args+=("$arg")
  fi
done

if [ ${#languages[@]} -eq 0 ]; then
  if ! command -v fzf &>/dev/null; then
    echo "Error: fzf is not installed, but it is required for the interactive menu." >&2
    echo "You can launch the environment by specifying languages as arguments, e.g.:" >&2
    echo "  develop-env python node rust" >&2
    exit 1
  fi

    selected=$(printf "%s\n" "${AVAILABLE_LANGS[@]}" | fzf --multi --prompt="Select toolchains (Tab to toggle, Enter to confirm): ")

  if [ -z "$selected" ]; then
    echo "No toolchains selected. Exiting."
    exit 0
  fi

    while read -r line; do
    if [ -n "$line" ]; then
      languages+=("$line")
    fi
  done <<< "$selected"
fi

nix_list=""
for lang in "${languages[@]}"; do
  nix_list="$nix_list \"$lang\""
done

expr='let flake = builtins.getFlake "/home/cricro/nixos-config/apps/develop-env"; system = builtins.currentSystem; makeShell = flake.outputs.lib.${system}.makeShell; in makeShell ['"$nix_list"']'

echo "Entering develop-env with: ${languages[*]}"

exec nix develop --impure --expr "$expr" -c "$SHELL" "${nix_args[@]}"
