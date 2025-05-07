{ pkgs, ... }: {
  home.packages = with pkgs; [
    hyprpolkitagent
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    hyprcursor
  ];
}
