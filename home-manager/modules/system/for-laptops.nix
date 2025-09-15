# System / Debug tools used for laptops
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    brightnessctl
  ];
}
