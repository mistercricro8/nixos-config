# Unique packages for cricro-pc
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    blender
    opencode
    parsec-bin
    android-tools # tied to droidcam
  ];
}
