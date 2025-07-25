{ pkgs, config, ... }:

let
  thisHomeDir = "${config.home.homeDirectory}/nixos-config/homes/cricro-laptop";
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
in
{
  imports = [ ../common.nix ];
  home.packages = with pkgs; [
    brightnessctl
  ];

  home.file = (
    builtins.listToAttrs (mkRecursiveEntries ./config "")
    // {
      ".icons".source = "${pkgs.catppuccin-cursors.mochaYellow}";
      ".jdks/current".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.jdk24}";
    }
  );
}
