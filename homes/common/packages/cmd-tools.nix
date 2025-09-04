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
    poppler
    ripgrep
    ripdrag
    fzf
    zoxide
    resvg
    p7zip
    sops
    rar
    ffmpeg
    grim
    slurp
    tldr
    hyperfine
    nh
  ];
}
