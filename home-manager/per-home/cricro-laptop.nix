{
  pkgs,
  config,
  rootCfgPath,
  rootCfgPathAbs,
  ...
}:

let
  home-file-generators = import (rootCfgPath + "/lib/home-file-generators.nix") { inherit config; };
  mkRecursiveFiles = home-file-generators.mkRecursiveFiles;

  home-manager-modules = rootCfgPath + "/home-manager/modules";
  config-origin = rootCfgPathAbs + "/home-manager/config-dirs/cricro-laptop";
in
{
  imports = [
    ../default.nix
    (home-manager-modules + "/apps/gui-apps/default.nix")
    (home-manager-modules + "/apps/gui-apps/vscode.nix")
    (home-manager-modules + "/apps/cli-apps/default.nix")
    (home-manager-modules + "/apps/cli-apps/x86_64-only.nix")
    (home-manager-modules + "/apps/semester.nix")
    (home-manager-modules + "/fonts/default.nix")
    (home-manager-modules + "/system/default.nix")
    (home-manager-modules + "/system/for-laptops.nix")
    (home-manager-modules + "/other/hyprland.nix") # TODO rename the 'other' module :sob:
    (home-manager-modules + "/per-home/cricro-laptop.nix")
  ];

  home.file = (
    (mkRecursiveFiles ../config-dirs/cricro-laptop config-origin "" ".config")
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
    }
  );
}
