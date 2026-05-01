#!/usr/bin/env bash
mutagen sync create \
  --name "${USER}-nixos-config" \
  -c mutagen.yml \
  ./ \
  ${MUTAGEN_BETA}
