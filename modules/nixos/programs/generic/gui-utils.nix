{ inputs, ... }:
{
  flake.factories.nixos."programs/generic/gui-utils" =
    {
      user ? "cricro",
    }:
    { pkgs, ... }:
    {
      users.users.${user}.packages = inputs.self.lib.util.filterInvalidPackages pkgs (
        with pkgs;
        [
          pavucontrol
          libreoffice-fresh
          discord
          kdePackages.dolphin
          nwg-look
          lorien
          krita
          rnote
          localsend
          nwg-displays
          gsettings-desktop-schemas
          gtk3
          filezilla
          rustdesk-flutter
          blender
          easyeffects
          scrcpy
          baobab
          kitty
          kdePackages.kdenlive
          heroic
          imv
        ]
      );

      dotfiles.profiles = [
        "kitty"
        "xsettingsd"
        "mimeapps"
        "mangohud"
        "sioyek"
        "imv"
      ];
    };
}
