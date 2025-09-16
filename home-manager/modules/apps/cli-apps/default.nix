# General CLI apps used often

{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # stablished
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

  programs.micro.enable = true;
  catppuccin.micro = {
    enable = true;
    transparent = true;
  };

  programs.yazi.enable = true;
  catppuccin.yazi = {
    enable = true;
  };

  programs.btop.enable = true;
  catppuccin.btop = {
    enable = true;
  };

  programs.bat.enable = true;
  catppuccin.bat = {
    enable = true;
  };

  programs.fzf.enable = true;
  catppuccin.fzf = {
    enable = true;
  };
}
