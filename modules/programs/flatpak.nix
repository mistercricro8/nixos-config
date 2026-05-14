# Enables the flatpak module
{ inputs, ... }:
{
  flake.modules.nixos.flatpak = {
    services.flatpak.enable = true;
  };

  flake.modules.homeManager.flatpak = {
    imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  };
}
