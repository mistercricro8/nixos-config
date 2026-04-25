# Host: laptop

{ inputs, ... }:
{
  flake.modules.nixos."cricro-laptop" =
    { pkgs, config, ... }:
    let
      m = inputs.self.modules;
      split-monitor-workspaces-hypr =
        inputs.split-monitor-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.split-monitor-workspaces;
      uniWifiSsid = inputs.private.secrets.cricro-laptop.uniWiFiSsid;
    in
    {
      imports = with m; [
        nixos.system-desktop
        nixos.for-laptops
        nixos.catppuccin
        nixos.home-manager
        nixos."users/cricro"
        nixos.sBoot
        nixos.sSamba
        nixos.sTailscale
        nixos.steam
        nixos.sunshine
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
      };

      # ============== Networking
      networking.hostName = "cricro-laptop";

      # ============== Time
      time.timeZone = "America/Lima";

      # ============== Extra
      virtualisation.virtualbox.host.enable = true;
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
          size = 8192;
        }
      ];

      networking.nftables.enable = true;

      services.resolved.enable = true;
      sops.secrets."cricro-laptop/uniWiFiPwd" = {
        sopsFile = inputs.self + "/secrets/cricro-laptop.yaml";
        format = "yaml";
      };
      networking.networkmanager.dns = "systemd-resolved";
      networking.networkmanager.ensureProfiles = {
        profiles = {
          uniWifiSsid = {
            connection = {
              id = uniWifiSsid;
              type = "wifi";
            };
            wifi = {
              ssid = uniWifiSsid;
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk-flags = 1;
            };
            ipv4 = {
              method = "auto";
              ignore-auto-dns = false;
              dns-priority = -20000;
              dns-search = "~.";
            };
          };
        };
        secrets.entries = [
          {
            file = config.sops.secrets."cricro-laptop/uniWiFiPwd".path;
            key = "psk";
            matchId = uniWifiSsid;
            matchSetting = "802-11-wireless-security";
          }
        ];
      };

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
            homeManager.vscode
            homeManager.zed
            homeManager.fonts
            homeManager.for-laptops
            homeManager.semester
            homeManager.dotfiles
            homeManager.hyprland
          ];

          home.stateVersion = "24.11";
          systemConstants.configName = "laptop";

          sDotfiles = {
            enable = true;
            configs = {
              backgrounds.enable = true;
              bottom.enable = true;
              kitty.enable = true;
              rofi.enable = true;
              vscode.enable = true;
              zed.enable = true;
              winapps.enable = true;
              xsettingsd.enable = true;
              yazi.enable = true;
              mimeapps.enable = true;
              starship.enable = true;
              opencode.enable = true;
            };
          };

          sHyprland = {
            enable = true;
            extensions.dms.enable = true;
            plugins = {
              enable = true;
              plugins = [
                {
                  name = "libsplit-monitor-workspaces.so";
                  sourcePath = "${split-monitor-workspaces-hypr}/lib/libsplit-monitor-workspaces.so";
                }
              ];
            };
          };

          home.packages = with pkgs; [
            opencode
            antigravity
            python3
            mutagen
            distrobox
            nur.repos.ataraxiasjel.waydroid-script
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
