{ inputs, ... }:
{
  flake.modules.nixos."secrets/sops" =
    { ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.gnupg.sshKeyPaths = [ "/home/cricro/.ssh/id_rsa" ];
    };
}
