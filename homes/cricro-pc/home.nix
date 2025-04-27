{ pkgs, ... }:

{
    imports = [ ../common.nix ];
    home.packages = with pkgs; [
        libreoffice
        discord
        obs-studio
        playerctl
        pavucontrol
        audio-recorder
    ];

    programs.mpv = {
      enable = true;
      package = pkgs.mpv-unwrapped.wrapper {
        mpv = pkgs.mpv-unwrapped;
        scripts = with pkgs.mpvScripts; [
          mpris
        ];
      };
    };

    home.file = {
    ".config/" = {
      source = ./config;
      recursive = true;
    };
  };
}
