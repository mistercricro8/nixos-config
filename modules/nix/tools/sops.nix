# Enables the sops module
{ inputs, ... }:
{
  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops.gnupg.sshKeyPaths = [ "/home/cricro/.ssh/id_rsa" ];
  };

  flake.modules.homeManager.sops = {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops.gnupg.sshKeyPaths = [ "/home/cricro/.ssh/id_rsa" ];
  };
}
