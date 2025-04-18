{ pkgs, ... }:

{
    imports = [ ../common.nix ];
    home.packages = with pkgs; [
        libreoffice
        obs-studio
        droidcam
        cheese
        mpv
        jflap
    ];

    home.file = {
    ".config/" = {
      source = ./config;
      recursive = true;
    };
  };
}