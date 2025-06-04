{ pkgs, config, ... }:

let
  storeDir = "${config.home.homeDirectory}/store";
  dotfiles = builtins.attrNames (builtins.readDir ./config);
  thisHomeDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-pc";
  mkDotfileEntry = name: {
    name = ".config/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/config/${name}";
    };
  };
  storeDirs = [
    "unsa"
    "repos"
    "tiny-projects"
    "projects"
    "important"
  ];
  mkStoreEntry = name: {
    name = "${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${storeDir}/${name}";
    };
  };

in
{
  imports = [
    ../common.nix
  ];

  home.packages = with pkgs; [
    libreoffice
    obs-studio
    playerctl
    pavucontrol
    audio-recorder
    davinci-resolve
    catppuccin-cursors.mochaYellow
  ];

  programs.mpv = {
    enable = true;
    package = pkgs.mpv-unwrapped.wrapper {
      mpv = pkgs.mpv-unwrapped;
      scripts = with pkgs.mpvScripts; [
        mpris
      ];
    };
  };

  home.file = (
    builtins.listToAttrs (map mkDotfileEntry dotfiles)
    // builtins.listToAttrs (map mkStoreEntry storeDirs)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".config/VSCodium/User/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/settings.json";
      ".config/VSCodium/User/keybindings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/keybindings.json";
    }
  );
}
