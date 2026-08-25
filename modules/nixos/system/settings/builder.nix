{ ... }:
{
  flake.modules.nixos."system/settings/builder" =
    {
      pkgs,
      ...
    }:
    {
      boot.binfmt.emulatedSystems = pkgs.lib.filter (system: system != pkgs.stdenv.hostPlatform.system) [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
