# Enables catppuccin themes for both NixOS and Home Manager. Uses stable branch.
{ inputs, ... }:
{
  flake.modules.nixos."catppuccin-stable" = {
    imports = [ inputs.catppuccin-stable.nixosModules.catppuccin ];
  };

  flake.modules.homeManager."catppuccin-stable" = {
    imports = [ inputs.catppuccin-stable.homeModules.catppuccin ];
    catppuccin = {
      flavor = "mocha";
      accent = "yellow";
    };
  };
}
