#!/usr/bin/env bash

# Passphrase setup for opentofu usage
passphrase=$(sops -d --extract '["passphrase"]' provisioning/secrets/tf.yaml 2>/dev/null)
if [ $? -eq 0 ]; then
  export TF_VAR_passphrase="$passphrase"
fi

# Private flake gh token setup
token=$(sops -d --extract '["githubToken"]' secrets/private-access.yaml 2>/dev/null)
if [ $? -eq 0 ]; then
  export NIX_CONFIG="access-tokens = github.com=$token"
  export GH_TOKEN="$token"
fi
