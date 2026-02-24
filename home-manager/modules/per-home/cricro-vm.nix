# Unique packages for cricro-vm
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fortune
  ];
}