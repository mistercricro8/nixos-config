# General CLI apps used often

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
    htop
    tree
    micro
    yazi
    btop
    fd
    nix-output-monitor
    bat
    eza
    du-dust
    jq
    poppler
    ripgrep
    ripdrag
    fzf
    resvg
    p7zip
    sops
    rar
    ffmpeg
    tldr
    hyperfine
    nh
    playerctl

    # testing
    wineWowPackages.stable # TODO checking whether bottles depends on these
    winetricks
  ];

  catppuccin.micro = {
    enable = true;
    flavor = catppuccin-consts.flavor;
    transparent = true;
  };

  catppuccin.yazi = {
    enable = true;
    flavor = catppuccin-consts.flavor;
    accent = catppuccin-consts.accent;
  };

  catppuccin.btop = {
    enable = true;
    flavor = catppuccin-consts.flavor;
  };

  catppuccin.bat = {
    enable = true;
    flavor = catppuccin-consts.flavor;
  };

  catppuccin.fzf = {
    enable = true;
    flavor = catppuccin-consts.flavor;
  };

}
