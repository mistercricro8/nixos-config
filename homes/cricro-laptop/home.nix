{ pkgs, ... }:

{
    imports = [ ../common.nix ];
    home.packages = with pkgs; [
        libreoffice
        obs-studio
        droidcam
        cheese
        mpv
        godot_4
        jflap
    ];

    home.file = {
    ".config/" = {
      source = ./config;
      recursive = true;
    };
  };
}