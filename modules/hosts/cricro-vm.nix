# Host: vm

{ inputs, ... }:
{
  flake.modules.nixos."cricro-vm" =
    { pkgs, lib, config, ... }:
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

      # notably, docker enables these, this might be useful info for a host that doesn't run docker
      # boot.kernel.sysctl = {
      #   "net.ipv4.ip_forward" = 1;
      #   "net.ipv6.conf.all.forwarding" = 1;
      # };

      networking.firewall = {
        allowedUDPPorts = [
          51820 # wireguard
          41641 # tailscale
          21116 # rustdesk
        ];
        allowedTCPPorts = [
          22 # ssh
          80 # http
          81 # http-alt
          443 # https
          444 # https-alt
          2022 # sftp (eh)
        ];
        allowedUDPPortRanges = [
          {
            from = 27000; # pterodactyl (eh)
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
            to = 27150;
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
        extraCommands = ''
          iptables -D INPUT -i tailscale0 -j ACCEPT || true
          iptables -D FORWARD -i tailscale0 -j ACCEPT || true
          iptables -D FORWARD -o tailscale0 -j ACCEPT || true

          iptables -I INPUT 1 -i tailscale0 -j ACCEPT
          iptables -I FORWARD 1 -i tailscale0 -j ACCEPT
          iptables -I FORWARD 1 -o tailscale0 -j ACCEPT

          iptables -D INPUT -s 10.8.0.0/24 -p tcp --dport 9100 -j ACCEPT || true
          iptables -D INPUT -s 10.8.0.0/24 -p tcp --dport 8080 -j ACCEPT || true

          iptables -A INPUT -s 10.8.0.0/24 -p tcp --dport 9100 -j ACCEPT
          iptables -A INPUT -s 10.8.0.0/24 -p tcp --dport 8080 -j ACCEPT

          iptables -t nat -D POSTROUTING -o enp0s6 -j MASQUERADE || true
          iptables -t nat -A POSTROUTING -o enp0s6 -j MASQUERADE
        '';
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
          Domains=~kube.ynoacamino.me
          FallbackDNS=8.8.8.8 1.1.1.1
          DNSStubListener=no
        '';
      };

      # ============== Wireguard
      sops.secrets."cricro-vm/KHHLzm/wgQuickConfig" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      networking.wg-quick.interfaces.eh = {
        configFile = "/run/secrets/cricro-vm/KHHLzm/wgQuickConfig";
      };

      # ============== Rather cheap kubernetes
      sops.secrets."cricro-vm/KHHLzm/kubeAdminConfig" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
        owner = "cricro";
      };

      sops.secrets."cricro-vm/KHHLzm/kubeNodeToken" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      sops.secrets."cricro-vm/KHHLzm/kubeNodeConfig" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      environment.variables.KUBECONFIG = "/run/secrets/cricro-vm/KHHLzm/kubeAdminConfig";

      environment.systemPackages = with pkgs; [
        kubectl
      ];

      services.k3s = {
        enable = true;
        role = "agent";
        tokenFile = "/run/secrets/cricro-vm/KHHLzm/kubeNodeToken";
        configPath = "/run/secrets/cricro-vm/KHHLzm/kubeNodeConfig";
        serverAddr = inputs.private.secrets.cricro-vm.KHHLzm.serverAddress;
      };

      # ============== Gitlab Runner
      sops.secrets."cricro-vm/WZ7uTl/gitlabTokenConfigFile" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      services.gitlab-runner = {
        enable = true;
        services.WZ7uTl = {
          executor = "docker";
          dockerImage = "moby/buildkit:rootless";
          authenticationTokenConfigFile = "/run/secrets/cricro-vm/WZ7uTl/gitlabTokenConfigFile";
          registrationFlags = [
            "--docker-security-opt seccomp:unconfined"
            "--docker-security-opt apparmor:unconfined"
          ];
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
