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
    # audio-recorder
    kitty
    brave
    bottles
    # too lazy to reorganize rn
    jetbrains.idea
    nodejs
    kdePackages.kdenlive
    gsettings-desktop-schemas
    gtk3
    droidcam
    filezilla
    sunshine
    moonlight-qt
    rustdesk-flutter
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
