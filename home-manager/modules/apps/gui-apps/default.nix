# General GUI apps used often

{
  rootCfgPath,
  pkgs,
  ...
}:
let
  catppuccin-consts = import (rootCfgPath + "/constants/catppuccin.nix") { };
in
{
  home.packages = with pkgs; [
    # stablished
    pavucontrol
    libreoffice-fresh
    discord
    obs-studio
    nemo
    nwg-look
    lorien
    rnote
    nwg-displays
    firefox
    audio-recorder

    # testing
    bottles
  ];

  catppuccin.obs = {
    enable = true;
    flavor = catppuccin-consts.flavor;
  };

  catppuccin.firefox = {
    enable = true;
    flavor = catppuccin-consts.flavor;
    accent = catppuccin-consts.accent;
  };
}
