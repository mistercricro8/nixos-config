{ inputs, ... }:
{
  flake.factories.nixos."programs/mpv" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs [
        (pkgs.mpv.override {
          scripts = with pkgs.mpvScripts; [
            mpris
          ];
        })
      ];
    };
}
