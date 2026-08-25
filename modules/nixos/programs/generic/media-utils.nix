{ inputs, ... }:
{
  flake.factories.nixos."programs/generic/media-utils" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          yt-dlp
          ffmpeg
          moonlight-qt
          sioyek
        ]
      );
    };
}
