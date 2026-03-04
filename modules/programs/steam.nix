# Steam.
{ inputs, ... }:
{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.nur ];

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        extraCompatPackages = with pkgs; [
          nur.repos.forkprince.proton-dw-bin
        ];
      };
    };
}
