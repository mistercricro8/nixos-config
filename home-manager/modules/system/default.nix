# System / Debug tools
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    net-tools
    lm_sensors
    usbutils
  ];
}
