# Host: pc

{ inputs, ... }:
{
  flake.modules.nixos."cricro-pc" =
    { pkgs, config, ... }:
    let
      self = inputs.self;
      m = self.modules;
      split-monitor-workspaces-hypr =
        inputs.split-monitor-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.split-monitor-workspaces;
      storeDir = "/home/cricro/store";
      storeDirs = [
        "uni"
        "repos"
        "tiny-projects"
        "videos"
        "projects"
        "important"
      ];
    in
    {
      imports = with m; [
        nixos.system-desktop
        nixos.catppuccin
        nixos.home-manager
        nixos."users/cricro"
        nixos.sBoot
        nixos.sSamba
        nixos.sTailscale
        nixos.sunshine
        nixos.flatpak
        ./_hardware-cricro-pc.nix
      ];

      # ============== Options imports config
      systemConstants.configName = "pc";

      sBoot.enable = true;

      sSamba = {
        enable = true;
        dirs = {
          "files" = {
            path = "/home/LaEsquina/la-esquina-store/laesquina-management/files";
            guestOk = "no";
            writable = "yes";
            accessMode = "read-write";
            user = "LaEsquina";
            userData = {
              homeMode = "0777";
              hashedPassword = "$y$j9T$Fm/3aDe8MkmxKAX16PhK/0$sVt5FWmeQJbOkTFHQhT0DCqC3bti13ORbx/MiwDFXB2";
            };
          };
          "Archivos" = {
            path = "/home/LaEsquina/la-esquina-store/Archivos";
            guestOk = "no";
            writable = "yes";
            accessMode = "read-write";
            user = "LaEsquina";
          };
          "Medicina" = {
            path = "/home/LaEsquina/la-esquina-store/Medicina";
            guestOk = "no";
            writable = "yes";
            accessMode = "read-write";
            user = "LaEsquina";
          };
        };
      };

      sTailscale = {
        enable = true;
        hostName = "cricro-pc-l";
      };

      # ============== Networking
      networking.hostName = "cricro-pc";
      networking.interfaces.enp3s0.wakeOnLan.enable = true;
      networking.nftables.enable = true;

      # ============== Time
      time.timeZone = "America/Lima";
      time.hardwareClockInLocalTime = true;

      # ============== Extra
      programs.virt-manager.enable = true;
      users.groups.libvirtd.members = [ "cricro" ];
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
      programs.droidcam.enable = true;
      boot.kernelModules = [
        "v4l2loopback"
        "snd-aloop"
      ];
      boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
      environment.systemPackages = with pkgs; [
        v4l-utils
      ];

      virtualisation.docker.enableOnBoot = false;

      swapDevices = [
        {
          device = "/swapfile";
          size = 8 * 1024;
        }
      ];

      # ============== System
      system.stateVersion = "24.05";

      # ============== Home manager
      home-manager.users.cricro =
        {
          pkgs,
          config,
          ...
        }:
        {
          imports = with m; [
            homeManager."users/cricro"
            homeManager.cli-tools
            homeManager.desktop-apps
            homeManager.vscode-mutable
            homeManager.zed
            homeManager.fonts
            homeManager.semester
            homeManager.dotfiles
            homeManager.hyprland
            homeManager.sops
            homeManager.flatpak
          ];

          home.stateVersion = "24.11";
          systemConstants.configName = "pc";

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

          # These require the specific package name to work
          # The flatpak cli offers alternatives so check there first
          services.flatpak.packages = [
            "org.vinegarhq.Sober"
            "com.valvesoftware.Steam"
            "com.valvesoftware.Steam.Utility.steamtinkerlaunch"
            "net.davidotek.pupgui2"
            "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
            "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/25.08"
            "com.github.tchx84.Flatseal"
          ];

          home.packages = with pkgs; [
            blender
            opencode
            parsec-bin
            android-tools
            antigravity
            gemini-cli
            scrcpy
            easyeffects
            github-copilot-cli
            mutagen
            kubectl
          ];

          home.sessionVariables = {
            XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
          };

          home.file =
            (inputs.self.lib.mkSelectedFiles {
              inherit config;
              originDir = storeDir;
              selection = storeDirs;
              outDir = ".";
            })
            // {
              ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
              ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk}";
            };
        };

      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
    };
}
