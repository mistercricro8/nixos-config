{ inputs, ... }:
{
  flake.factories.nixos."development/vscode" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      dotfiles.profiles = [ "vscode" ];
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs; [ vscode ]
      );
    };
}
