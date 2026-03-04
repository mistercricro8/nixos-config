# Fonts
{ inputs, ... }:
{
  flake.modules.homeManager.fonts =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
          nerd-fonts.caskaydia-mono
          nerd-fonts.jetbrains-mono
        ]
      );
    };
}
