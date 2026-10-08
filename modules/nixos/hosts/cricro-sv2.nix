{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-sv2" =
    {
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "sv2";

      imports =
        (with inputs.self.modules; [
          nixos."system/server"
          nixos."users/cricro/default"
          nixos."boot/minimal"
        ])
        ++ (with inputs.self.factories; [
          (nixos."secrets/ssh-keys" {
            keys = [ "id_ed25519" ];
          })
          (nixos."system/settings/networking" {
            netInterfaces = [ "enp30s0" ];
            wakeonlan = true;
            nftables = true;
          })
          (nixos."services/tailscale" {
            hostname = "cricro-sv2";
            hostType = "client";
          })
        ])
        ++ [
          (import _hardware/cricro-sv2.nix { inherit inputs; })
        ];

      # ============== Networking
      networking.hostName = "cricro-sv2";
      networking.firewall.trustedInterfaces = [
        "tailscale0"
      ];

      # ============== Time
      time.timeZone = "America/Lima";

      environment.systemPackages = with pkgs; [
        wakeonlan
      ];

      # ============== System
      system.stateVersion = "24.05";
    };
}
