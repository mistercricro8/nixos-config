# Configuration for hosts that work as desktops
{ inputs, ... }:
{
  flake.modules.nixos.system-desktop = {
    imports = with inputs.self.modules; [
      nixos.system-default
      nixos.hyprland-system
      nixos.kde
      nixos.peripherals
    ];

    # thanks gtk
    programs.dconf.enable = true;

    # thunar
    programs.xfconf.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
