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
      boot.kernelModules = [ "br_netfilter" ];
      # TODO: docker might be restarting this one despite the declaration
      boot.kernel.sysctl = {
        "net.bridge.bridge-nf-call-iptables" = 0;
        "net.bridge.bridge-nf-call-arptables" = 0;
        "net.bridge.bridge-nf-call-ip6tables" = 0;
      };

      networking.firewall = {
        allowedUDPPorts = [
          51820 # wireguard
          41641 # tailscale
        ];
        allowedTCPPorts = [
          22 # ssh
          80 # http
          81 # http-alt
          443 # https
          444 # https-alt
        ];
        allowedUDPPortRanges = [
          {
            from = 27000; # pterodactyl (eh)
            to = 27150;
          }
          {
            from = 28000; # non-specified docker services
            to = 28099;
          }
        ];
        allowedTCPPortRanges = [
          {
            from = 27000; # pterodactyl (eh)
            to = 27150;
          }
          {
            from = 28000; # non-specified docker services
            to = 28099;
          }
        ];
        extraCommands = ''
          iptables -t filter -N DOCKER-USER 2>/dev/null || true

          add_rule() {
            local table=$1; shift
            local chain=$1; shift
            local action=$1; shift
            if ! iptables -t "$table" -C "$chain" "$@" > /dev/null 2>&1; then
              iptables -t "$table" -"$action" "$chain" "$@"
            fi
          }

          add_rule filter DOCKER-USER A -i br-+ -j ACCEPT
          add_rule filter DOCKER-USER A -o br-+ -j ACCEPT
          add_rule filter FORWARD I -i tailscale0 -j ACCEPT
          add_rule filter FORWARD I -o tailscale0 -j ACCEPT

          add_rule nat POSTROUTING A -o enp0s6 -j MASQUERADE

          add_rule filter INPUT A -s 10.8.0.0/24 -p tcp -m tcp --dport 9100 -j ACCEPT
          add_rule filter INPUT A -s 10.8.0.0/24 -p tcp -m tcp --dport 8080 -j ACCEPT
        '';
        trustedInterfaces = [ "docker0" "cni0" ];
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

      virtualisation.docker.daemon.settings = {
        dns = [ "8.8.8.8" "1.1.1.1" ];
        mtu = 1200;
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
