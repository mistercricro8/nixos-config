# Host: vm

{ inputs, ... }:
{
  flake.modules.nixos."cricro-vm" =
    { pkgs, ... }:
    let
      m = inputs.self.modules;
    in
    {
      imports = with m; [
        nixos.system-server
        nixos.catppuccin-stable
        nixos.home-manager-stable
        nixos."users/cricro"
        nixos.sBoot
        nixos.sTailscale
        ./_hardware-cricro-vm.nix
      ];

      # ============== Options imports config
      systemConstants.configName = "vm";

      sBoot = {
        enable = true;
        mode = "minimal";
      };

      sTailscale = {
        enable = true;
        hostName = "cricro-vm";
        hostType = "both";
      };

      # ============== Networking
      networking.hostName = "cricro-vm";

      # ============== Time
      time.timeZone = "America/Santiago";

      # ============== Extra
      boot.loader.efi.efiSysMountPoint = "/boot/efi";

      swapDevices = [
        {
          device = "/swapfile";
          size = 16384;
        }
      ];

      networking.firewall = {
        allowedUDPPorts = [
          51820 # wireguard
          21116 # rustdesk
        ];
        allowedTCPPorts = [
          22 # ssh
          80 # http
          443 # https
          2022 # sftp (eh)

          9100 # node-exporter
          8080 # cadvisor
        ];
        allowedUDPPortRanges = [
          {
            from = 27100; # pterodactyl (eh)
            to = 27150;
          }
          {
            from = 28100; # non-specified docker services
            to = 28150;
          }
        ];
        allowedTCPPortRanges = [
          {
            from = 27000; # pterodactyl (eh)
            to = 27999;
          }
          {
            from = 21115; # rustdesk
            to = 21119;
          }
          {
            from = 28000; # non-specified docker services
            to = 28099;
          }
        ];
      };

      # ============== Docker proxy for preventing docker updates from breaking socket access
      virtualisation.oci-containers.backend = "docker";
      virtualisation.oci-containers.containers."docker-proxy" = {
        image = "tecnativa/docker-socket-proxy";
        extraOptions = [
          "--privileged"
          "--network-alias=docker-proxy"
          "--network=internal-proxy"
        ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
        environment = {
          "ALLOW_RESTART" = "1";
          "ALLOW_START" = "1";
          "ALLOW_STOP" = "1";
          "AUTH" = "1";
          "BUILD" = "1";
          "COMMIT" = "1";
          "CONFIGS" = "1";
          "CONTAINERS" = "1";
          "DISTRIBUTION" = "1";
          "EXEC" = "1";
          "GRPC" = "1";
          "IMAGES" = "1";
          "INFO" = "1";
          "NETWORKS" = "1";
          "NODES" = "1";
          "PLUGINS" = "1";
          "POST" = "1";
          "SECRETS" = "1";
          "SERVICES" = "1";
          "SESSION" = "1";
          "SWARM" = "1";
          "SYSTEM" = "1";
          "TASKS" = "1";
          "VOLUMES" = "1";
        };
      };

      systemd.services."docker-docker-proxy" = {
        partOf = [ "docker.service" ];
        after = [
          "docker.socket"
          "docker.service"
        ];
        wantedBy = [ "docker.service" ];
      };

      systemd.services.docker.restartIfChanged = false;
      systemd.services."docker-docker-proxy".restartIfChanged = false;

      # ============== Pihole
      services.resolved = {
        enable = true;
        extraConfig = ''
          [Resolve]
          DNS=127.0.0.1
          FallbackDNS=8.8.8.8 1.1.1.1
          DNSStubListener=no
        '';
      };

      # ============== Wireguard
      sops.secrets."cricro-vm/wg-quick-eh" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      networking.wg-quick.interfaces.eh = {
        configFile = "/run/secrets/cricro-vm/wg-quick-eh";
      };

      # ============== Gitlab Runner
      sops.secrets."cricro-vm/gitlab-WZ7uTl" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      services.gitlab-runner = {
        enable = true;
        services.WZ7uTl = {
          executor = "docker";
          dockerImage = "moby/buildkit:rootless";
          authenticationTokenConfigFile = "/run/secrets/cricro-vm/gitlab-WZ7uTl";
        };
      };

      # ============== System
      system.stateVersion = "23.05";

      # ============== Home manager
      home-manager.users.cricro = {
        imports = with m; [
          homeManager."users/cricro"
          homeManager.cli-tools
          homeManager.dotfiles
          homeManager.semester
        ];

        sDotfiles = {
          enable = true;
          configs = {
            bottom.enable = true;
            rofi.enable = true;
            yazi.enable = true;
            starship.enable = true;
          };
        };

        home.stateVersion = "24.11";
        systemConstants.configName = "vm";
      };

      home-manager.extraSpecialArgs = {
        inherit inputs;
      };
    };
}
