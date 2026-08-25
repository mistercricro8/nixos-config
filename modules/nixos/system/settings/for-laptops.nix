{ ... }:
{
  flake.modules.nixos."system/settings/for-laptops" =
    {
      pkgs,
      ...
    }:
    {
      networking.wireless.enable = false;
      networking.wireless.iwd = {
        enable = true;
        settings = {
          IPv6.Enabled = true;
          Settings.AutoConnect = true;
        };
      };
      networking.networkmanager.wifi.backend = "iwd";
      environment.systemPackages = [ pkgs.brightnessctl ];
    };
}
