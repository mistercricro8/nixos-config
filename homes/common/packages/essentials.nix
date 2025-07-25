{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swaynotificationcenter
    waybar
    rofi-wayland
    wl-clipboard
    cliphist
  ];
}
