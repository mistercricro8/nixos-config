# Host: laptop

{ inputs, ... }:
{
  flake.modules.nixos."cricro-laptop" =
    { pkgs, config, ... }:
    let
      m = inputs.self.modules;
      stablePkgs = inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = with m; [
        nixos."users/cricro"
        nixos.system-desktop
        nixos.for-laptops
        nixos.catppuccin
        nixos.home-manager
        nixos.sBoot
        nixos.sSamba
        nixos.sTailscale
        nixos.sunshine
        nixos.flatpak
        ./_hardware-cricro-laptop.nix
      ];

      # ============== Options imports config
      systemConstants.configName = "laptop";

      sBoot.enable = true;

      sSamba = {
        enable = false;
        dirs = {
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
      };

      sTailscale = {
        enable = true;
        hostName = "cricro-laptop";
        # secretKeyPath = "tailscale/cricroLaptop";
      };

      # ============== Networking
      networking.hostName = "cricro-laptop";

      # ============== Time
      time.timeZone = "America/Lima";

      # ============== Extra
      users.extraGroups.vboxusers.members = [ "cricro" ];
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

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.nftables.enable = true;

      services.resolved.enable = true;
      # sops.secrets."cricro-laptop/uniWiFiPwd" = {
      #   sopsFile = inputs.self + "/secrets/cricro-laptop.yaml";
      #   format = "yaml";
      # };
      networking.networkmanager.dns = "systemd-resolved";
      # networking.networkmanager.ensureProfiles = {
      #   profiles = {
      #     uniWifiSsid = {
      #       connection = {
      #         id = uniWifiSsid;
      #         type = "wifi";
      #       };
      #       wifi = {
      #         ssid = uniWifiSsid;
      #       };
      #       wifi-security = {
      #         key-mgmt = "wpa-psk";
      #         psk-flags = 1;
      #       };
      #       ipv4 = {
      #         method = "auto";
      #         ignore-auto-dns = false;
      #         dns-priority = -20000;
      #         dns-search = "~.";
      #       };
      #     };
      #   };
      #   secrets.entries = [
      #     {
      #       file = config.sops.secrets."cricro-laptop/uniWiFiPwd".path;
      #       key = "psk";
      #       matchId = uniWifiSsid;
      #       matchSetting = "802-11-wireless-security";
      #     }
      #   ];
      # };

      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
      };

      virtualisation.docker.enableOnBoot = false;
      virtualisation.waydroid.enable = true;

      # ============== System
      system.stateVersion = "24.05";

      # ============== Home manager
      home-manager.users.cricro =
        { pkgs, config, ... }:
        {
          imports = with m; [
            homeManager."users/cricro"
            homeManager.cli-tools
            homeManager.desktop-apps
            homeManager.vscode-mutable
            homeManager.zed
            homeManager.fonts
            homeManager.for-laptops
            homeManager.semester
            homeManager.dotfiles
            homeManager.hyprland
            homeManager.sops
            homeManager.flatpak
          ];

          home.stateVersion = "24.11";
          systemConstants.configName = "laptop";

          sops.secrets."projects/KHHLzm/kubeAdminConfig" = {
            sopsFile = inputs.self + "/secrets/projects.yaml";
            format = "yaml";
          };

          home.sessionVariables = {
            KUBECONFIG = config.sops.secrets."projects/KHHLzm/kubeAdminConfig".path;
          };

          sDotfiles = {
            enable = true;
            configs = {
              backgrounds.enable = true;
              bottom.enable = true;
              kitty.enable = true;
              rofi.enable = true;
              vscode.enable = true;
              zed.enable = true;
              xsettingsd.enable = true;
              yazi.enable = true;
              mimeapps.enable = true;
              starship.enable = true;
              opencode.enable = true;
              gemini.enable = true;
              copilot.enable = true;
              mangohud.enable = true;
              flatpak-overrides.enable = true;
              sioyek.enable = true;
              arduino-ide.enable = true;
            };
          };

          sHyprland = {
            enable = true;
            extensions.dms.enable = true;
            plugins = {
              enable = true;
              plugins = [
                {
                  name = "split-monitor-workspaces";
                  sourcePath = "${inputs.split-monitor-workspaces}";
                }
              ];
            };
          };

          # These require the specific package name to work
          # The flatpak cli offers alternatives so check there first
          services.flatpak.packages = [
            "com.unity.UnityHub"
            "com.valvesoftware.Steam"
            "com.valvesoftware.Steam.Utility.steamtinkerlaunch"
            "net.davidotek.pupgui2"
            "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
            "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/25.08"
            "com.github.tchx84.Flatseal"
          ];

          home.packages = with pkgs; [
            opencode
            gemini-cli
            github-copilot-cli
            antigravity-cli
            open-webui

            blender
            mutagen
            nur.repos.ataraxiasjel.waydroid-script
            kubectl
          ];

          home.file = {
            ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
            ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk}";
          };
        };

      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
    };
}
