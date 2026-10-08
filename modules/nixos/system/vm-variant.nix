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
      };
    };
}
