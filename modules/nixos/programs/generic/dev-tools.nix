{ inputs, ... }:
{
  flake.factories.nixos."programs/generic/dev-tools" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          opencode
          github-copilot-cli
          antigravity-cli
          android-tools
          kubectl
        ]
      );
    };
}
