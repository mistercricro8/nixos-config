{ inputs, ... }:
{
  flake.factories.nixos."virtualisation/winapps" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      dotfiles.profiles = [ "winapps" ];
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs [
        inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps
      ];
    };
}
