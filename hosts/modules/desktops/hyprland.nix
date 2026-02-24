{
  inputs,
  pkgs,
  ...
}:

let
  hyprpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # ------------- mesa hyprland package -------------
  hardware = {
    graphics = {
      package = hyprpkgs.mesa;
    };
  };

  # ------------- hyprland -------------
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

}
