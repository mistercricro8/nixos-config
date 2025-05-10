{ pkgs, config, ... }:

let
  dotfiles = builtins.attrNames (builtins.readDir ./config);
  dotfilesDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-laptop/config";
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
    catppuccin-cursors.mochaYellow
    nwg-displays
  ];

  home.file = (
    builtins.listToAttrs (map mkDotfileEntry dotfiles)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
    }
  );
}
