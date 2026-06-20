#!/usr/bin/env bash

# GPG setup from ssh rsa
ssh-to-pgp -private-key -i $HOME/.ssh/id_rsa | gpg --import 2>/dev/null

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

# Mutagen beta secret setup
mutagenbeta=$(sops -d --extract '["mutagenBeta"]' secrets/private-access.yaml 2>/dev/null)
if [ $? -eq 0 ]; then
  export MUTAGEN_BETA="$mutagenbeta"
fi
