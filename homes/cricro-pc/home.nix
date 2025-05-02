{ pkgs, config, ... }:

let
  storeDir = "${config.home.homeDirectory}/store";
  dotfilesDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-laptop/config/";
  dotfiles = [
    "backgrounds"
    "gtk-3.0"
    "hypr"
    "rofi"
    "kitty"
    "starship.toml"
    "waybar"
    "xsettingsd"
  ];
  mkDotfileEntry = name: {
    name = ".config/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${name}";
    };
  };
  storeDirs = [
    "unsa"
    "repos"
    "tiny-projects"
    "projects"
    "important"
  ];
  mkStoreEntry = name: {
    name = "${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${storeDir}/${name}";
    };
  };
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

  home.file = (
    builtins.listToAttrs (map mkDotfileEntry dotfiles)
    // builtins.listToAttrs (map mkStoreEntry storeDirs)
  );
}
