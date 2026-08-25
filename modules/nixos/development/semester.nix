{ inputs, ... }:
{
  flake.factories.nixos."development/semester" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs; [ octaveFull ]
      );
    };
}
