# Winapps.
{ inputs, ... }:
{
  flake.modules.homeManager.winapps =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs [
        inputs.winapps.packages.${pkgs.stdenv.hostPlatform.system}.winapps
      ];
    };
}
