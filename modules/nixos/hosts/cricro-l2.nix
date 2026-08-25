{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-l2" =
    {
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "l2";

      imports =
        (with inputs.self.modules; [
          nixos."system/server"
          nixos."system/settings/for-laptops"
          nixos."users/cricro"
          nixos."boot/minimal"
        ])
        ++ (with inputs.self.factories; [
          (nixos."system/settings/networking" {
            netInterfaces = [ "enp5s0" ];
            wakeonlan = true;
            nftables = true;
          })
          (nixos."services/tailscale" {
            hostname = "cricro-l2";
            hostType = "client";
          })
        ])
        ++ [
          (import _hardware/cricro-l2.nix { inherit inputs; })
        ];

      # ============== Networking
      networking.hostName = "cricro-l2";
      networking.interfaces.enp5s0.wakeOnLan.enable = true;
      networking.firewall.trustedInterfaces = [
        "tailscale0"
      ];

      # ============== Time
      time.timeZone = "America/Lima";

      # ============== Extra
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
      };

      environment.systemPackages = with pkgs; [
        wakeonlan
      ];

      swapDevices = [
        {
          device = "/swapfile";
          size = 8 * 1024;
        }
      ];

      # ============== System
      system.stateVersion = "24.05";
    };
}
