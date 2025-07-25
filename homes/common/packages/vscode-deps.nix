{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ruff
    clang-tools
    nixfmt-rfc-style
    jdk24
    lazygit
    go
    nixd
  ];
}
