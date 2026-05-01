# Desktop apps
{ inputs, ... }:
{
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
          pavucontrol
          libreoffice-fresh
          discord
          nautilus
          nwg-look
          lorien
          rnote
          nwg-displays
          kitty
          brave
          kdePackages.kdenlive
          gsettings-desktop-schemas
          gtk3
          filezilla
          sunshine
          moonlight-qt
          rustdesk-flutter
          heroic
        ]
      );

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
    };
}
