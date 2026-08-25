{ inputs, ... }:
{
  flake.factories.nixos."programs/obs" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs [
        (pkgs.wrapOBS {
          plugins = with pkgs.obs-studio-plugins; [
            obs-pipewire-audio-capture
          ];
        })
      ];
    };
}
