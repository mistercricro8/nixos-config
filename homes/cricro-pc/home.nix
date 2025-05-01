{ pkgs, config, ... }:

let
  storeDir = "${config.home.homeDirectory}/store";
in
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
    "unsa/" = {
      source = config.lib.file.mkOutOfStoreSymlink storeDir + "/unsa";
    };
    "repos/" = {
      source = config.lib.file.mkOutOfStoreSymlink storeDir + "/repos";
    };
    "projects/" = {
      source = config.lib.file.mkOutOfStoreSymlink storeDir + "/projects";
    };
    "tiny-projects/" = {
      source = config.lib.file.mkOutOfStoreSymlink storeDir + "/tiny-projects";
    };
    "important/" = {
      source = config.lib.file.mkOutOfStoreSymlink storeDir + "/important";
    };
  };
}
