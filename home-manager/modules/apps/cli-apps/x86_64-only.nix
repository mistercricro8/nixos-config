# bleh!

{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    rar
    wineWow64Packages.staging
  ];
}
