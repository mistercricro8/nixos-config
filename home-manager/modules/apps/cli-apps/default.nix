# General CLI apps used often

{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    htop
    tree
    btop
    fd
    nix-output-monitor
    eza
    du-dust
    jq
    poppler
    ripgrep
    ripdrag
    resvg
    p7zip
    sops
    ffmpeg
    tldr
    hyperfine
    nh
    playerctl
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
  catppuccin.mpv.enable = true;

  programs.git.delta.enable = true;
  catppuccin.delta.enable = true;

  programs.fuzzel.enable = true;
  catppuccin.fuzzel.enable = true;

  programs.btop.enable = true;
  catppuccin.btop.enable = true;

  programs.fzf.enable = true;
  catppuccin.fzf.enable = true;
}
