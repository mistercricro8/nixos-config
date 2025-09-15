# Hyprland dependencies and others used for its configuration
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    hyprpolkitagent
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    hyprcursor
    swaynotificationcenter
    waybar
    rofi-wayland
    wl-clipboard
    cliphist
    catppuccin-cursors.mochaYellow
  ];
}