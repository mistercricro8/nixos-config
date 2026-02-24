{
  pkgs,
  ...
}:

{
  # ------------- steam -------------
  programs.steam.enable = true;
  programs.steam.extraCompatPackages = with pkgs; [
    nur.repos.forkprince.proton-dw-bin
  ];
}
