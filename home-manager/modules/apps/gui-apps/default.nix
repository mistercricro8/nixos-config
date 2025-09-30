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
    kitty
    bottles
  ];

  programs.obs-studio.enable = true;
  catppuccin.obs.enable = true;

  programs.firefox.enable = true;
  catppuccin.firefox = {
    enable = true;
    force = true;
  };

  programs.sioyek.enable = true;
  catppuccin.sioyek.enable = true;

  programs.imv.enable = true;
  catppuccin.imv.enable = true;

}
