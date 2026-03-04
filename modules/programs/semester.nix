# Current uni semester apps.
{ inputs, ... }:
{
  flake.modules.homeManager.semester =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (with pkgs; [ octaveFull ]);
    };
}
