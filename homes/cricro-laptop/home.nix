{ pkgs, config, ... }:

let
  dotfilesDir = ./config;
  dotfiles = builtins.attrNames (builtins.readDir dotfilesDir);
  mkDotfileEntry = name: {
    name = ".config/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${name}";
    };
  };
in
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

  home.file = builtins.listToAttrs (map mkDotfileEntry dotfiles);
}
