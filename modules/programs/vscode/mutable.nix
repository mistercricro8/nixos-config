# VSCode.
{ inputs, ... }:
{
  flake.modules.homeManager.vscode-mutable =
    { pkgs, ... }:
    {
      # TODO: for deps check zed.nix, althout I'm somewhat unsure on
      # how willing is vscode to use direnv sourced deps

      programs.vscode = {
        enable = true;
        mutableExtensionsDir = true;
      };
    };
}
