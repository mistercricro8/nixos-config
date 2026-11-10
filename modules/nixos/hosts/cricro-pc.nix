{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-pc" =
    {
      config,
      pkgs,
      ...
    }:
    {
      systemConstants.configName = "pc";

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
          nixos."users/cricro/default"
          nixos."users/cricro/desktop"
          nixos."boot/full"
          nixos."gaming/sunshine"
          nixos."system/settings/builder"
          nixos."programs/flatpak"
          nixos."programs/generic/sys-utils"
          nixos."development/vscode-server"
          nixos."desktop/fonts"
          nixos."virtualisation/virt-manager"
        ])
        ++ (with inputs.self.factories; [
          (nixos."system/impermanence" {
            device = "/dev/disk/by-partlabel/disk-main-root";
            user = "cricro";
            directories = [
              "/var/lib/tailscale"
              "/etc/NetworkManager/system-connections"
              "/var/lib/NetworkManager"
              "/var/lib/flatpak"
              "/var/lib/docker"
              "/var/lib/libvirt"
              "/var/lib/cups"
            ];
            userDirectories = [
              ".var/app"
              "nixos-config"
              ".gnupg"
              ".local/share/keyrings"
              ".local/share/pki"
              ".pki"
              ".config/discord"
              ".mozilla"
              ".config/mozilla"
              ".config/chromium"
              ".config/BraveSoftware"
              ".config/pulse"
              ".local/state/wireplumber"
              ".local/share/atuin"
              ".local/share/fish"
              ".local/share/zoxide"
              ".gemini"
              ".omp"
              ".config/context7"
              ".config/gh"
              ".config/glab-cli"
              ".local/share/direnv"
              ".config/orca"
              ".orca"
              ".config/obs-studio"
              ".config/dconf"
              ".local/state/dms"
              ".config/Code"
              ".vscode/extensions"
              ".vscode-server"
              ".android"
              ".config/Google"
              ".local/share/Google"
              ".cache/uv"
              ".local/share/uv"
              ".cargo"
              ".rustup"
              ".gradle"
              ".local/share/zed"
              ".cache/zed"
              ".cache/pnpm"
              ".local/share/pnpm"
              ".cache/bun"
              ".cache/.bun"
              ".cache/huggingface"
              ".cache/ms-playwright"
            ];
          })
          (nixos."secrets/ssh-keys" {
            keys = [
              "id_ed25519"
              {
                name = "gh_mistercricro8";
                shared = true;
              }
            ];
          })
          (nixos."system/settings/networking" {
            netInterfaces = [ "enp3s0" ];
            wakeonlan = true;
            ipv6 = false;
            nftables = true;
            profiles = inputs.self.lib.networking.mkIgnoreLocalDns {
              name = "ignore-local-dns";
              interface = "enp3s0";
            };
          })
          (nixos."services/tailscale" {
            hostname = "cricro-pc-l";
          })
        ])
        ++ [
          (import _hardware/cricro-pc.nix { inherit inputs; })
        ];

      # ============== Time
      time.timeZone = "America/Lima";
      time.hardwareClockInLocalTime = true;

      # ============== Extra
      networking.hostName = "cricro-pc";
      networking.firewall.allowedUDPPorts = [ 7790 ];

      programs.droidcam.enable = true;
      boot.kernelPackages = pkgs.linuxPackages_zen;
      boot.kernelModules = [
        "v4l2loopback"
        "snd-aloop"
      ];
      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      environment.systemPackages = with pkgs; [
        v4l-utils
      ];

      swapDevices = [
        {
          device = "/swapfile";
          size = 16 * 1024;
        }
      ];

      environment.unixODBCDrivers = with pkgs; [
        unixodbcDrivers.msodbcsql18
        unixodbcDrivers.psql
      ];

      # ============== System
      system.stateVersion = "24.05";

      # ============== Flatpak packages
      services.flatpak.packages = [
        "org.vinegarhq.Sober"
        "com.valvesoftware.Steam"
        "com.github.Matoking.protontricks"
        "net.davidotek.pupgui2"
        "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
        "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/25.08"
        "com.github.tchx84.Flatseal"
      ];
    };
}
