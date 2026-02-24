#!/usr/bin/env bash

# GPG setup from ssh rsa
ssh-to-pgp -private-key -i $HOME/.ssh/id_rsa | gpg --import 2>/dev/null

# Passphrase setup for opentofu usage
passphrase=$(sops -d --extract '["passphrase"]' provisioning/secrets/tf.yaml 2>/dev/null)
if [ $? -eq 0 ]; then
  export TF_VAR_passphrase="$passphrase"
fi
