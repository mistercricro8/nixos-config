{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bottom
    fd
    nix-output-monitor
    bat
    eza
    du-dust
    jq
    grim
    slurp
    tldr
    hyperfine
    nh
  ];
}
