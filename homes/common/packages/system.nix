{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pavucontrol
    tree
    htop
    net-tools
    lm_sensors
    usbutils
  ];
}
