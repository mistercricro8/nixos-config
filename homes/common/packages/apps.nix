{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libreoffice-fresh
    discord
    obs-studio
    nemo
    nwg-look
    catppuccin-gtk
    (brave.override {
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--password-store=gnome"
      ];
    })
    micro
    lorien
    rnote
    nwg-displays
    devenv
    wineWowPackages.stable
    winetricks
    filezilla
    librewolf
  ];
}
