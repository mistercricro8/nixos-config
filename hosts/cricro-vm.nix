{
  rootCfgPath,
  ...
}:

let
  nixos-modules = rootCfgPath + "/hosts/modules";
in
{
  imports = [
    ./default.nix
    (nixos-modules + "/boot/minimal.nix")
    (nixos-modules + "/builder/default.nix")
    (nixos-modules + "/hardware/cricro-vm.nix")
    (nixos-modules + "/overlays/default.nix")

    ./n-modules/samba.nix
    ./n-modules/tailscale.nix
  ];

  # ------------- boot -------------
  # repartitioning provisioned stuff scary
  # TODO update the terraform script to:
  # - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-23.05 sudo bash -x
  # - or maybe NIX_CHANNEL=nixos-23.05 sudo bash -x nixos.sh since github hates anonymous curls
  # - umount /boot
  # - mkdir /boot/efi
  # - mount whatever /boot was using to /boot/efi (mount /dev/sda15 /boot/efi) MAYBE
  # - nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # - add this line v and update the fs mounts
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # - nix-shell -p git
  # - nixos-rebuild switch --upgrade
  # - reboot
  # - clone this repo, switch to dev
  # - UPDATE the hardware config fs devices :sob:
  # - nixos-rebuild switch --flake .#cricro-vm

  # ------------- time -------------
  time.timeZone = "America/Santiago";

  # ------------- vpn -------------
  sTailscale = {
    enable = true;
    hostName = "cricro-vm";
    hostType = "both";
  };

  # ------------- swap -------------
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  # ------------- samba -------------
  # sSamba = {
  #   enable = true;
  #   tailscaleOnly = true;
  #   dirs = {
  #     "shared" = {
  #       path = "/home/cricro/shared";
  #       guestOk = "no";
  #       writable = "yes";
  #       accessMode = "read-write";
  #       user = "cricro";
  #     };
  #   };
  # };

  # VERY EXPERIMENTAL DO NOT PUSH YET
  # systemd.services.tailscale-netdev-optimizations = {
  #   description = "Enable Tailscale UDP offload optimizations";
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = [
  #       "${pkgs.bash}/bin/bash" "-c" ''2
  #         NETDEV=$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 | cut -f5 -d" ")
  #         if [ -n "$NETDEV" ]; then
  #           ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
  #         else
  #           echo "Could not determine network interface."
  #         fi
  #       ''
  #     ];
  #     RemainAfterExit = true;
  #   };
  #   wantedBy = [ "multi-user.target" ];
  # };

  # ------------- a github runner (which i will make a module someday) -------------
  # sops.secrets.gh-runner-rp-token = {
  #   sopsFile = rootCfgPath + "/secrets/gh-runner-rp.yaml";
  #   format = "yaml";
  # };

  # services.github-runners = {
  #   rp-runner = {
  #     enable = true;
  #     url = builtins.extraBuiltins.eval-sops (rootCfgPath + "/secrets/gh-runner-rp.yaml") "gh-runner-rp-url";
  #     tokenFile = "/run/secrets/gh-runner-rp-token";
  #     extraPackages = with pkgs; [
  #       docker
  #     ];
  #     user = "root";
  #   };
  # };

  # ------------- firewall? -------------
  networking.firewall = {
    allowedUDPPorts = [
      51820
      21116
    ];
    allowedTCPPorts = [
      22
      80
      443
      2022

      9100 # node-exporter
      8080 # cadvisor
    ];
    allowedUDPPortRanges = [
      {
        from = 27100;
        to = 27150;
      }
    ];
    allowedTCPPortRanges = [
      {
        from = 27000;
        to = 27999;
      }
      {
        from = 21115;
        to = 21119;
      }
    ];
  };

  # ------------- docker socket proxy hook -------------
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

  # ------------- networking -------------
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "127.0.0.1";
        FallbackDNS = [
          "8.8.8.8"
          "1.1.1.1"
        ];
        DNSStubListener = "no";
      };
    };
  };

  # ------------- wireguard for vpn2 -------------
  sops.secrets."cricro-vm/wg-quick-eh" = {
    sopsFile = rootCfgPath + "/secrets/cricro-vm.yaml";
    format = "yaml";
  };

  networking.wg-quick.interfaces.eh = {
    configFile = "/run/secrets/cricro-vm/wg-quick-eh";
  };

  # ------------- system stuff -------------
  # uhh perhaps look out to keep this synced with the nix infect terraform script
  system.stateVersion = "23.05";
}
