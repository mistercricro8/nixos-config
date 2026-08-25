{ inputs, ... }:
{
  flake.factories.nixos."development/zed" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      dotfiles.profiles = [ "zed" ];
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs; [ zed-editor ]
      );
    };
}
