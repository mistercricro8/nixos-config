{ pkgs, config, ... }:

let
  dotfiles = builtins.attrNames (builtins.readDir ./config);
  thisHomeDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-laptop";
  mkDotfileEntry = name: {
    name = ".config/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/config/${name}";
    };
  };
in
{
  imports = [ ../common.nix ];
  home.packages = with pkgs; [
    libreoffice
    obs-studio
    droidcam
    cheese
    mpv
    jflap
    catppuccin-cursors.mochaYellow
    nwg-displays
  ];

  home.file = (
    builtins.listToAttrs (map mkDotfileEntry dotfiles)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".config/VSCodium/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/settings.json";
      ".config/VSCodium/User/keybindings.json".source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/keybindings.json";
    }
  );
}
