{
  ...
}:
{
  imports = [
    ./default.nix
    ./n-modules/hyprland.nix
    ./n-modules/dotfiles.nix
  ];
  sDotfiles.enable = false;
  sHyprland.enable = false;
}
