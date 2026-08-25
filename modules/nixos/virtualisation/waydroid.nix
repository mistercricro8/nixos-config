{ inputs, ... }:
{
  flake.factories.nixos."virtualisation/waydroid" =
    {
      user ? "cricro",
    }:
    { config, pkgs, ... }:
    {
      virtualisation.waydroid = {
        enable = true;
        package = if (config.networking.nftables.enable or false) then pkgs.waydroid-nftables else pkgs.waydroid;
      };

      networking.firewall.trustedInterfaces = [ "waydroid0" ];

      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs [
        pkgs.waydroid-helper
      ];
    };
}
