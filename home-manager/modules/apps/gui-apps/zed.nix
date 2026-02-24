{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;
  };

  home.packages = with pkgs; [
    ruff
    clang-tools
    jdk
    lazygit
    go
    shellcheck
    shfmt
    nixd
    typst
    nixfmt
  ];
}
