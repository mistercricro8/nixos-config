{ ... }:
{
  flake.modules.nixos."gaming/steam" =
    {
      pkgs,
      ...
    }:
    {
      programs.steam = {
        enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [
          dwproton-bin
        ];
      };
    };
}
