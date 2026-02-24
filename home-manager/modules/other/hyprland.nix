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
    rofi
    wl-clipboard
    cliphist
    libnotify
    catppuccin-cursors.mochaYellow
  ];
}