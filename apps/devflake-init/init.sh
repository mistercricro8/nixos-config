#!/usr/bin/env bash

if [[ $# -lt 1 || ($1 != "copy" && $1 != "load") ]]; then
  echo "Usage: devflake-init [copy | load]"
  exit 0
fi

if [ "$1" == "copy" ]; then
  cp "$HOME/nixos-config/apps/devflake-init/base.nix" flake.nix
else
  git add .

  touch .gitignore
  grep -Pzo '.direnv' .gitignore
  if [ $? -ne 0 ]; then
    printf '.direnv\n' >> .gitignore
  fi

  echo "use flake" >>.envrc
  direnv allow
fi
