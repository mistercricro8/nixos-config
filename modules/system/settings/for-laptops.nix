# Settings and apps for laptops
{ inputs, ... }:
{
  flake.modules.nixos.for-laptops =
    { ... }:
    {
      networking.wireless.iwd = {
        enable = true;
        settings = {
          IPv6.Enabled = true;
          Settings.AutoConnect = true;
        };
      };
      networking.networkmanager.wifi.backend = "iwd";
    };

  flake.modules.homeManager.for-laptops =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
          brightnessctl
        ]
      );
    };
}
