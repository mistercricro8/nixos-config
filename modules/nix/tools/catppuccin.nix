# Enables catppuccin themes for both NixOS and Home Manager.
{ inputs, ... }:
{
  flake.modules.nixos.catppuccin = {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];
  };

  flake.modules.homeManager.catppuccin = {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin = {
      flavor = "mocha";
      accent = "yellow";
    };
  };
}
