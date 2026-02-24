#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <vscode-version>"
  exit 1
fi

VSCODE_VERSION="$1"

exprs=(
  "extensions.vscode-marketplace-release.github.copilot-chat"
  "extensions.vscode-marketplace-release.bbenoist.doxygen"
)

commits=$(gh api repos/nix-community/nix-vscode-extensions/commits)

for commit in $(echo "$commits" | jq -r '.[].sha'); do
  echo "----------------------------------------------------------------"
  echo "Checking commit: $commit"

  build_list="["
  for expr in "${exprs[@]}"; do
      build_list="$build_list $expr"
  done
  build_list="$build_list ]"

  if NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --builders '' --impure --expr "
    let
      pkgs = import <nixpkgs> { config.allowUnfree = true; };
      flake = builtins.getFlake \"github:nix-community/nix-vscode-extensions/${commit}\";
      system = builtins.currentSystem;
      extensions = flake.extensions.\${system}.forVSCodeVersion \"${VSCODE_VERSION}\";
    in
    ${build_list}
  "; then
    echo
    echo "Working commit: $commit"
    exit 0
  else
    echo "Build failed for commit $commit"
  fi
done

echo
echo "No working commit found"
exit 1
