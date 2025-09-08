{
  pkgs,
  config,
  rootCfgPath,
  ...
}:

let
  thisHomeDir = config.home.homeDirectory + "/nixos-config/homes/cricro-laptop";
  home-file-generators = import (rootCfgPath + "/lib/home-file-generators.nix") { inherit config; };
  mkRecursiveFiles = home-file-generators.mkRecursiveFiles;
in
{
  imports = [ ../common.nix ];
  home.packages = with pkgs; [
    brightnessctl
  ];

  home.file = (
    (mkRecursiveFiles ./config "" thisHomeDir ".config")
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
    }
  );
}
