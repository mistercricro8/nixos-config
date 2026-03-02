{
  pkgs,
  ...
}:

{
  # ------------- steam -------------
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [
      nur.repos.forkprince.proton-dw-bin
    ];
  };
}
