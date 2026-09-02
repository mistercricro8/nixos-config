{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-laptop" =
    {
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "laptop";

      # ============== Secrets
      sops.secrets."projects/KHHLzm/kubeAdminConfig" = {
        sopsFile = inputs.self + "/secrets/projects.yaml";
        format = "yaml";
        path = "/home/cricro/.kube/config";
        owner = "cricro";
      };

      imports =
        (with inputs.self.modules; [
          nixos."system/desktop"
          nixos."system/settings/for-laptops"
          nixos."users/cricro/default"
          nixos."users/cricro/desktop"
          nixos."boot/full"
          nixos."gaming/sunshine"
          nixos."programs/flatpak"
          nixos."programs/generic/sys-utils"
          nixos."development/vscode-server"
          nixos."desktop/fonts"
          nixos."virtualisation/virt-manager"
          nixos."system/settings/builder"
        ])
        ++ (with inputs.self.factories; [
          (nixos."secrets/ssh-keys" {
            keys = [
              "id_ed25519"
              {
                name = "gh_mistercricro8";
                shared = true;
              }
            ];
          })
          (nixos."virtualisation/waydroid" { user = "cricro"; })
          (nixos."system/settings/networking" {
            netInterfaces = [
              "wlp3s0"
              "enp2s0"
            ];
            wakeonlan = false;
            nftables = true;
          })
          (nixos."services/samba" {
            shares = {
              "datafest" = {
                path = "/home/datafest/datafest";
                guestOk = "no";
                writable = "yes";
                accessMode = "read-write";
                user = "datafest";
                userData = {
                  homeMode = "0777";
                  hashedPassword = "$y$j9T$l/PxxMweO25/XtIUHR6Kf/$lML0xzPUPhR7XB1kfKgfAVH.1qfCzjvh0vi6azQjR4/";
                };
              };
            };
          })
          (nixos."services/tailscale" {
            hostname = "cricro-laptop";
            hostType = "client";
          })
        ])
        ++ [
          (import _hardware/cricro-laptop.nix { inherit inputs; })
        ];

      dotfiles.profiles = [ "arduino-ide" ];

      # ============== Time
      time.timeZone = "America/Lima";

      # ============== Extra
      networking.hostName = "cricro-laptop";

      programs.wireshark = {
        enable = true;
        dumpcap.enable = true;
        usbmon.enable = true;
      };
      users.extraGroups.wireshark.members = [ "cricro" ];

      environment.systemPackages = with pkgs; [
        wireshark
        linux-wifi-hotspot
      ];

      swapDevices = [
        {
          device = "/swapfile";
          size = 8 * 1024;
        }
      ];

      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
      };

      networking.firewall.trustedInterfaces = [
        "cni0"
        "tailscale0"
      ];

      # ============== System
      system.stateVersion = "24.05";

      # ============== Flatpak packages
      services.flatpak.packages = [
        "com.unity.UnityHub"
        "com.valvesoftware.Steam"
        "com.github.Matoking.protontricks"
        "net.davidotek.pupgui2"
        "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
        "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/25.08"
        "com.github.tchx84.Flatseal"
      ];
    };
}
