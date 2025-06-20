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
    obs-studio
    mpv
    jflap
    postman
  ];

  home.file = (
    builtins.listToAttrs (map mkDotfileEntry dotfiles)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".config/VSCodium/User/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/settings.json";
      ".config/VSCodium/User/keybindings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/VSCodium/keybindings.json";
      ".config/Code/User/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/Code/settings.json";
      ".config/Code/User/keybindings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/other-links/Code/keybindings.json";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
    }
  );
}
