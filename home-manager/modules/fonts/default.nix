# Fonts?? cant make a lot more out of this one
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
  ];
}
