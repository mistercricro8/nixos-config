{ inputs, ... }:
{
  flake.modules.nixos."desktop/fonts" =
    { pkgs, ... }:
    {
      fonts.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          nerd-fonts.caskaydia-mono
          nerd-fonts.jetbrains-mono
          papirus-icon-theme
        ]
      );
    };
}
