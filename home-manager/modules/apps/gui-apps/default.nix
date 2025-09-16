# General GUI apps used often

{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # stablished
    pavucontrol
    libreoffice-fresh
    discord
    nemo
    nwg-look
    lorien
    rnote
    nwg-displays
    audio-recorder

    # testing
    bottles
  ];

  programs.obs-studio.enable = true;
  catppuccin.obs = {
    enable = true;
  };

  programs.firefox.enable = true;
  catppuccin.firefox = {
    enable = true;
  };
}
