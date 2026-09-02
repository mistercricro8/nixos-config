{ inputs, ... }:
{
  flake.modules.nixos."secrets/sops" =
    { ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.useSystemdActivation = true;
      # TODO: autodeployments should consider pushing this key up
      sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    };
}
