# Unique packages for cricro-l2
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fortune
  ];
}
