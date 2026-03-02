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
    kitty
    brave
    kdePackages.kdenlive
    gsettings-desktop-schemas
    gtk3
    droidcam
    filezilla
    sunshine
    moonlight-qt
    rustdesk-flutter
    heroic
  ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
  };
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
