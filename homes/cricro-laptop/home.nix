{ pkgs, config, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-laptop/config";
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
  mkEntry = name: {
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

  home.file = builtins.listToAttrs (map mkEntry dotfiles);
}
