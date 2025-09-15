{
  pkgs,
  config,
  rootCfgPath,
  rootCfgPathAbs,
  inputs,
  ...
}:
let
  split-monitor-workspaces-hypr =
    inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces;

  storeDir = config.home.homeDirectory + "/store";
  storeDirs = [
    "uni"
    "repos"
    "tiny-projects"
    "videos"
    "projects"
    "important"
  ];

  home-file-generators = import (rootCfgPath + "/lib/home-file-generators.nix") {
    inherit config;
  };
  mkRecursiveFiles = home-file-generators.mkRecursiveFiles;
  mkSelectedFiles = home-file-generators.mkSelectedFiles;

  home-manager-modules = rootCfgPath + "/home-manager/modules";
  config-origin = rootCfgPathAbs + "/home-manager/config-dirs/cricro-pc";
in
{
  imports = [
    ../default.nix
    (home-manager-modules + "/apps/gui-apps/default.nix")
    (home-manager-modules + "/apps/gui-apps/vscode.nix")
    (home-manager-modules + "/apps/gui-apps/winapps.nix")
    (home-manager-modules + "/apps/cli-apps/default.nix")
    (home-manager-modules + "/apps/semester.nix")
    (home-manager-modules + "/fonts/default.nix")
    (home-manager-modules + "/system/default.nix")
    (home-manager-modules + "/other/hyprland.nix") # TODO rename the 'other' module :sob:
    (home-manager-modules + "/per-home/cricro-pc.nix")
  ];

  home.file = (
    (mkRecursiveFiles ../config-dirs/cricro-pc config-origin "" ".config")
    // (mkSelectedFiles storeDir storeDirs ".")
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}"; # TODO test gtk.cursorTheme
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
      ".hypr/plugins/libsplit-monitor-workspaces.so".source =
        config.lib.file.mkOutOfStoreSymlink "${split-monitor-workspaces-hypr}/lib/libsplit-monitor-workspaces.so";
    }
  );
}
