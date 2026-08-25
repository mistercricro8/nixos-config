{ inputs, ... }:
{
  flake.modules.nixos."system/vm-variant" =
    { lib, ... }:
    {
      virtualisation.vmVariant = {
        virtualisation.memorySize = lib.mkDefault 4096;
        virtualisation.cores = lib.mkDefault 4;
        sops.gnupg.sshKeyPaths = lib.mkForce [ ];
        virtualisation.libvirtd.enable = lib.mkForce false;

        systemd.tmpfiles.rules = [
          "d /home/cricro/nixos-config 0755 cricro users -"
        ];

        systemd.services.replicate-nixos-config = {
          description = "Replicate nixos-config repository into VM home directory";
          wantedBy = [ "basic.target" ];
          before = [ "hjem-activate@cricro.service" ];
          after = [ "local-fs.target" ];
          script = ''
            mkdir -p /home/cricro/nixos-config
            if [ ! -f /home/cricro/nixos-config/flake.nix ]; then
              cp -r ${inputs.self}/. /home/cricro/nixos-config/
              chown -R cricro:users /home/cricro/nixos-config
              chmod -R u+rw /home/cricro/nixos-config
            fi
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };
      };
    };
}
