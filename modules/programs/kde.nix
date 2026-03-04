# KDE (the desktop environment)
{ ... }:
{
  flake.modules.nixos.kde =
    { ... }:
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = false;
      };
      services.desktopManager.plasma6.enable = true;
    };
}
