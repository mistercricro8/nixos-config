{ ... }:
{
  flake-file.inputs = {
    hyprland.url = "github:hyprwm/hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin-grub = {
      url = "github:catppuccin/grub";
      flake = false;
    };
  };
}
