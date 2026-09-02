{ ... }:
{
  flake.modules.nixos."services/derived-keys" =
    { pkgs, ... }:
    let
      setupScript = pkgs.writeShellScript "setup-derived-keys" ''
        set -euo pipefail

        SSH_DIR="$HOME/.ssh"
        AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
        ED25519_KEY="$SSH_DIR/id_ed25519"
        RSA_KEY="$SSH_DIR/id_rsa"

        if [ -f "$ED25519_KEY" ]; then
          DERIVED_AGE=$(${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$ED25519_KEY")
          DERIVED_PUB=$(${pkgs.ssh-to-age}/bin/ssh-to-age -i "$ED25519_KEY.pub" 2>/dev/null || true)

          mkdir -p "$(dirname "$AGE_KEY_FILE")"
          touch "$AGE_KEY_FILE"
          chmod 0600 "$AGE_KEY_FILE"

          if ! grep -qF "$DERIVED_AGE" "$AGE_KEY_FILE" 2>/dev/null; then
            echo "Adding derived age key ($DERIVED_PUB) to $AGE_KEY_FILE..."
            printf "\n# derived from id_ed25519 (%s)\n%s\n" "$DERIVED_PUB" "$DERIVED_AGE" >> "$AGE_KEY_FILE"
          fi
        fi
      '';
    in
    {
      systemd.user.services.setup-derived-keys = {
        description = "Automatically derive Age key from user Ed25519 SSH key";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${setupScript}";
          RemainAfterExit = true;
        };
      };
    };
}
