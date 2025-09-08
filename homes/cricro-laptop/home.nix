{
  pkgs,
  config,
  rootCfgPath,
  ...
}:

let
  thisHomeDir = config.home.homeDirectory + "/nixos-config/homes/cricro-laptop";
  pathIsDir = path: builtins.pathExists (toString path + "/.");
  mkRecursiveEntries =
    dir: prefix:
    let
      items = builtins.attrNames (builtins.readDir dir);
    in
    builtins.concatLists (
      map (
        name:
        let
          fullPath = "${dir}/${name}";
          relPath = if prefix == "" then name else "${prefix}/${name}";
        in
        if pathIsDir fullPath then
          mkRecursiveEntries fullPath relPath
        else
          [
            {
              name = ".config/${relPath}";
              value = {
                source = config.lib.file.mkOutOfStoreSymlink "${thisHomeDir}/config/${relPath}";
              };
            }
          ]
      ) items
    );

  home-file-generators = import (rootCfgPath + "/lib/home-file-generators.nix") { inherit config; };
  mkRecursiveEntries2 = home-file-generators.mkRecursiveEntries;
in
{
  imports = [ ../common.nix ];
  home.packages = with pkgs; [
    brightnessctl
  ];

  home.file = (
    builtins.listToAttrs (mkRecursiveEntries2 ./config "" thisHomeDir)
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
    }
  );
}
