{
  inputs,
  pkgs,
  ...
}:

let
  hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{
  hardware = {
    graphics = {
      package = hyprpkgs.mesa;
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

}
