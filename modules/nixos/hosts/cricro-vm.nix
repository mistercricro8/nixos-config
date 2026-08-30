{ inputs, ... }:
{
  flake.modules.nixos."hosts/cricro-vm" =
    {
      config,
      pkgs,
      ...
    }:
    let
      pkgsStable = inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      systemConstants.configName = "vm";

      imports =
        (with inputs.self.modules; [
          nixos."system/server"
          nixos."users/cricro"
          nixos."boot/minimal"
        ])
        ++ (with inputs.self.factories; [
          (nixos."services/tailscale" {
            hostname = "cricro-vm";
            hostType = "both";
          })
        ])
        ++ [
          (import _hardware/cricro-vm.nix { inherit inputs; })
        ];

      # ============== Networking
      networking.hostName = "cricro-vm";
      networking.enableIPv6 = false;

      # ============== Time
      time.timeZone = "America/Santiago";

      # ============== Extra
      boot.loader.efi.efiSysMountPoint = "/boot/efi";

      virtualisation.docker.package = pkgsStable.docker;
      # TODO: remove this once the kernel is updated to provide these attrs
      boot.kernelPackages = pkgsStable.linuxPackages.extend (self: super: {
        kernel = super.kernel.overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            target = old.passthru.target or pkgsStable.stdenv.hostPlatform.linux-kernel.target;
            buildDTBs = old.passthru.buildDTBs or pkgsStable.stdenv.hostPlatform.linux-kernel.DTB;
          };
        });
      });

      swapDevices = [
        {
          device = "/swapfile";
          size = 12 * 1024;
        }
      ];

      boot.kernelModules = [ "br_netfilter" ];

      networking.firewall = {
        allowedUDPPorts = [ ];
        allowedTCPPorts = [
          22 # ssh
          80 # http
          81 # http-alt
          443 # https
          444 # https-alt
        ];
        allowedUDPPortRanges = [
          {
            from = 27000; # pterodactyl
            to = 27150;
          }
          {
            from = 28000; # non-specified docker services
            to = 28099;
          }
        ];
        allowedTCPPortRanges = [
          {
            from = 27000; # pterodactyl
            to = 27150;
          }
          {
            from = 28000; # non-specified docker services
            to = 28099;
          }
        ];
        extraCommands = ''
          iptables -A FORWARD -i docker0 -j ACCEPT
          iptables -A FORWARD -o docker0 -j ACCEPT
          iptables -A FORWARD -i br-+ -j ACCEPT
          iptables -A FORWARD -o br-+ -j ACCEPT
          iptables -A FORWARD -i cni0 -j ACCEPT
          iptables -A FORWARD -o cni0 -j ACCEPT
        '';
        trustedInterfaces = [
          "docker0"
          "cni0"
          "flannel.1"
        ];
      };

      virtualisation.docker.daemon.settings = {
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        mtu = 1200;
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

      # ============== K3s Kubernetes Agent
      sops.secrets."cricro-vm/KHHLzm/kubeNodeToken" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      sops.secrets."cricro-vm/KHHLzm/kubeNodeConfig" = {
        sopsFile = inputs.self + "/secrets/cricro-vm.yaml";
        format = "yaml";
      };

      services.k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.sops.secrets."cricro-vm/KHHLzm/kubeNodeToken".path;
        configPath = config.sops.secrets."cricro-vm/KHHLzm/kubeNodeConfig".path;
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
          authenticationTokenConfigFile = config.sops.secrets."cricro-vm/WZ7uTl/gitlabTokenConfigFile".path;
          registrationFlags = [
            "--docker-security-opt seccomp:unconfined"
            "--docker-security-opt apparmor:unconfined"
          ];
        };
      };

      # ============== System
      system.stateVersion = "23.05";
    };
}
