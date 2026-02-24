# bleh!

{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    rar
    wineWowPackages.stable
    winetricks
  ];
}
